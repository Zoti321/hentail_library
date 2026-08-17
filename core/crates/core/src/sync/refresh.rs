use sea_orm::{ActiveModelTrait, ColumnTrait, EntityTrait, QueryFilter, QueryOrder, Set};

use crate::comic::find_comic_by_id;
use crate::db::{connection, map_db_err};
use crate::entity::{comics, prelude::*, series, series_items};
use crate::error::HentaiError;
use crate::library::{
    find_library_by_id, remote_password_for, resolve_access_for_comic, LibraryDto,
};
use crate::metadata_lock::{
    merge_refresh_scan_with_existing, merge_series_name, series_name_needs_write,
};
use crate::resource::{parse_file_with, parsed_to_comic, ResourceAccess, WebDavResourceAccess};
use crate::series_id::series_name_from_folder_path;
use crate::util::compute_sort_key;

use super::handle::SyncHandle;
use super::library_lock::try_acquire_library_write_lock;
use super::remote::normalize_remote_location_key;
use super::writer::upsert_comics;

#[derive(Debug, Clone)]
pub struct RefreshSeriesProgressDto {
    pub current: i32,
    pub total: i32,
    pub comic_id: Option<String>,
    pub succeeded: i32,
    pub failed: i32,
}

#[derive(Debug, Clone)]
pub struct RefreshSeriesResultDto {
    pub succeeded: i32,
    pub failed: i32,
    pub cancelled: bool,
}

#[derive(Debug, Clone)]
pub struct RefreshLibraryResultDto {
    pub succeeded: i32,
    pub failed: i32,
    pub cancelled: bool,
    pub skipped: bool,
    pub skip_message: Option<String>,
}

/// 重解析单本 Comic 的 Resource 元数据，按字段锁 merge 后写回（不动缩略图）。
pub async fn refresh_comic_metadata(comic_id: &str) -> Result<(), HentaiError> {
    let _guard = try_acquire_library_write_lock()?;
    refresh_comic_metadata_locked(comic_id).await
}

pub(crate) async fn refresh_comic_metadata_locked(comic_id: &str) -> Result<(), HentaiError> {
    let existing = find_comic_by_id(comic_id)
        .await?
        .ok_or_else(|| HentaiError::validation(format!("漫画不存在: {comic_id}")))?;

    let resolved = resolve_access_for_comic(&existing)?;
    refresh_comic_metadata_with(resolved.as_dyn(), &existing.comic_id).await
}

/// Injected-access refresh (FakeResourceAccess / tests).
pub async fn refresh_comic_metadata_with(
    access: &dyn ResourceAccess,
    comic_id: &str,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let existing = find_comic_by_id(comic_id)
        .await?
        .ok_or_else(|| HentaiError::validation(format!("漫画不存在: {comic_id}")))?;

    let Some(_) = access.stat(&existing.path)? else {
        return Err(HentaiError::reader_not_found(&existing.path));
    };

    let parsed = parse_file_with(access, &existing.path)?.ok_or_else(|| {
        HentaiError::reader_invalid_content(format!("无法解析资源元数据: {}", existing.path))
    })?;
    let scanned = parsed_to_comic(&parsed);
    let merged = merge_refresh_scan_with_existing(&scanned, &existing);
    upsert_comics(&db, &[merged]).await?;
    Ok(())
}

/// 刷新 Series：逐成员 Comic 元数据 refresh；未锁定 name 用文件夹名覆盖。
/// 不改 status/totalCount/成员排序/缩略图；部分失败继续并汇总；可取消。
pub async fn refresh_series_metadata(
    series_id: &str,
    handle: &SyncHandle,
    mut emit: impl FnMut(RefreshSeriesProgressDto),
) -> Result<RefreshSeriesResultDto, HentaiError> {
    let _guard = try_acquire_library_write_lock()?;
    let db = connection()?;

    let series_row = Series::find_by_id(series_id.to_string())
        .one(&db)
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::validation(format!("系列不存在: {series_id}")))?;

    let comic_ids: Vec<String> = SeriesItems::find()
        .filter(series_items::Column::SeriesId.eq(series_id))
        .order_by_asc(series_items::Column::SortOrder)
        .order_by_asc(series_items::Column::ComicId)
        .all(&db)
        .await
        .map_err(map_db_err)?
        .into_iter()
        .map(|row| row.comic_id)
        .collect();

    let total = comic_ids.len() as i32;
    let mut succeeded = 0i32;
    let mut failed = 0i32;
    let mut cancelled = false;

    for (index, comic_id) in comic_ids.iter().enumerate() {
        if handle.is_cancelled() {
            cancelled = true;
            break;
        }
        match refresh_comic_metadata_locked(comic_id).await {
            Ok(()) => succeeded += 1,
            Err(err) => {
                tracing::warn!(
                    series_id,
                    comic_id,
                    error = %err,
                    "refresh series member failed"
                );
                failed += 1;
            }
        }
        emit(RefreshSeriesProgressDto {
            current: (index as i32) + 1,
            total,
            comic_id: Some(comic_id.clone()),
            succeeded,
            failed,
        });
    }

    if !cancelled {
        maybe_refresh_series_name(&db, series_row).await?;
    }

    let result = RefreshSeriesResultDto {
        succeeded,
        failed,
        cancelled,
    };
    if total == 0 {
        emit(RefreshSeriesProgressDto {
            current: 0,
            total: 0,
            comic_id: None,
            succeeded: 0,
            failed: 0,
        });
    }
    Ok(result)
}

/// 刷新指定 Library：全部 Comic + 未锁 Series name。
/// Remote 根不可达则跳过；可取消；部分失败继续并汇总。
pub async fn refresh_library_metadata(
    library_id: &str,
    handle: &SyncHandle,
    mut emit: impl FnMut(RefreshSeriesProgressDto),
) -> Result<RefreshLibraryResultDto, HentaiError> {
    let _guard = try_acquire_library_write_lock()?;
    let db = connection()?;

    let library = find_library_by_id(library_id)
        .await?
        .ok_or_else(|| HentaiError::validation(format!("库不存在: {library_id}")))?;

    if let Some(skip_message) = probe_remote_library_skip(&library)? {
        return Ok(RefreshLibraryResultDto {
            succeeded: 0,
            failed: 0,
            cancelled: false,
            skipped: true,
            skip_message: Some(skip_message),
        });
    }

    let comic_ids: Vec<String> = Comics::find()
        .filter(comics::Column::LibraryId.eq(library_id))
        .order_by_asc(comics::Column::ComicId)
        .all(&db)
        .await
        .map_err(map_db_err)?
        .into_iter()
        .map(|row| row.comic_id)
        .collect();

    let total = comic_ids.len() as i32;
    let mut succeeded = 0i32;
    let mut failed = 0i32;
    let mut cancelled = false;

    for (index, comic_id) in comic_ids.iter().enumerate() {
        if handle.is_cancelled() {
            cancelled = true;
            break;
        }
        match refresh_comic_metadata_locked(comic_id).await {
            Ok(()) => succeeded += 1,
            Err(err) => {
                tracing::warn!(
                    library_id,
                    comic_id,
                    error = %err,
                    "refresh library comic failed"
                );
                failed += 1;
            }
        }
        emit(RefreshSeriesProgressDto {
            current: (index as i32) + 1,
            total,
            comic_id: Some(comic_id.clone()),
            succeeded,
            failed,
        });
    }

    if !cancelled {
        let series_rows = Series::find()
            .filter(series::Column::LibraryId.eq(library_id))
            .all(&db)
            .await
            .map_err(map_db_err)?;
        for series_row in series_rows {
            maybe_refresh_series_name(&db, series_row).await?;
        }
    }

    if total == 0 {
        emit(RefreshSeriesProgressDto {
            current: 0,
            total: 0,
            comic_id: None,
            succeeded: 0,
            failed: 0,
        });
    }

    Ok(RefreshLibraryResultDto {
        succeeded,
        failed,
        cancelled,
        skipped: false,
        skip_message: None,
    })
}

fn probe_remote_library_skip(library: &LibraryDto) -> Result<Option<String>, HentaiError> {
    if library.kind != "remote" {
        return Ok(None);
    }
    let Some(password) = remote_password_for(&library.library_id).filter(|p| !p.is_empty()) else {
        let warning = format!("已跳过远程库（缺少凭证）: {}", library.root_path);
        tracing::warn!(library_id = %library.library_id, "{warning}");
        return Ok(Some(warning));
    };
    match WebDavResourceAccess::connect(&library.root_path, &library.username, &password) {
        Ok(access) => {
            match access.stat(&normalize_remote_location_key(&library.root_path)) {
                Err(err) if err.is_remote_access_failure() => {
                    let warning = format!(
                        "已跳过远程库（不可达）: {} — {}",
                        library.root_path, err.message
                    );
                    tracing::warn!(library_id = %library.library_id, "{warning}");
                    Ok(Some(warning))
                }
                Err(err) => Err(err),
                Ok(None) => {
                    let warning = format!("已跳过远程库（不可达）: {}", library.root_path);
                    tracing::warn!(library_id = %library.library_id, "{warning}");
                    Ok(Some(warning))
                }
                Ok(Some(_)) => Ok(None),
            }
        }
        Err(err) if err.is_remote_access_failure() => {
            let warning = format!("已跳过远程库（不可达）: {} — {}", library.root_path, err.message);
            tracing::warn!(library_id = %library.library_id, "{warning}");
            Ok(Some(warning))
        }
        Err(err) => Err(err),
    }
}

async fn maybe_refresh_series_name(
    db: &sea_orm::DatabaseConnection,
    series_row: series::Model,
) -> Result<(), HentaiError> {
    let folder_name = series_name_from_folder_path(&series_row.folder_path);
    if !series_name_needs_write(series_row.name_locked, &series_row.name, &folder_name) {
        return Ok(());
    }
    let mut active: series::ActiveModel = series_row.clone().into();
    let merged_name = merge_series_name(series_row.name_locked, &series_row.name, &folder_name);
    active.name_sort_key = Set(compute_sort_key(&merged_name));
    active.name = Set(merged_name);
    active.update(db).await.map_err(map_db_err)?;
    Ok(())
}
