use std::path::PathBuf;

use sea_orm::{ActiveModelTrait, ColumnTrait, EntityTrait, QueryFilter, QueryOrder, Set};

use crate::comic::find_comic_by_id;
use crate::db::{connection, map_db_err};
use crate::entity::{prelude::*, series, series_items};
use crate::error::HentaiError;
use crate::series_id::series_name_from_folder_path;

use crate::metadata_lock::{
    merge_kept_scan_with_existing, merge_series_name, series_name_needs_write,
};
use crate::resource::{parse_file, parsed_to_comic};

use super::library_lock::try_acquire_library_write_lock;
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
}

/// 重解析单本 Comic 的 Resource 元数据，按字段锁 merge 后写回（不动缩略图）。
pub async fn refresh_comic_metadata(comic_id: &str) -> Result<(), HentaiError> {
    let _guard = try_acquire_library_write_lock()?;
    refresh_comic_metadata_locked(comic_id).await
}

pub(crate) async fn refresh_comic_metadata_locked(comic_id: &str) -> Result<(), HentaiError> {
    let db = connection()?;
    let existing = find_comic_by_id(comic_id)
        .await?
        .ok_or_else(|| HentaiError::validation(format!("漫画不存在: {comic_id}")))?;

    let path = PathBuf::from(&existing.path);
    if !path.exists() {
        return Err(HentaiError::reader_not_found(&existing.path));
    }

    let parsed = parse_file(&path)?.ok_or_else(|| {
        HentaiError::reader_invalid_content(format!("无法解析资源元数据: {}", existing.path))
    })?;
    let scanned = parsed_to_comic(&parsed);
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    upsert_comics(&db, &[merged]).await?;
    Ok(())
}

/// 刷新 Series：逐成员 Comic 元数据 refresh；未锁定 name 用文件夹名覆盖。
/// 不改 status/totalCount/成员排序/缩略图；部分失败继续并汇总。
pub async fn refresh_series_metadata(
    series_id: &str,
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

    for (index, comic_id) in comic_ids.iter().enumerate() {
        let ok = match refresh_comic_metadata_locked(comic_id).await {
            Ok(()) => {
                succeeded += 1;
                true
            }
            Err(err) => {
                tracing::warn!(
                    series_id,
                    comic_id,
                    error = %err,
                    "refresh series member failed"
                );
                failed += 1;
                false
            }
        };
        let _ = ok;
        emit(RefreshSeriesProgressDto {
            current: (index as i32) + 1,
            total,
            comic_id: Some(comic_id.clone()),
            succeeded,
            failed,
        });
    }

    let folder_name = series_name_from_folder_path(&series_row.folder_path);
    if series_name_needs_write(series_row.name_locked, &series_row.name, &folder_name) {
        let mut active: series::ActiveModel = series_row.clone().into();
        active.name = Set(merge_series_name(
            series_row.name_locked,
            &series_row.name,
            &folder_name,
        ));
        active.update(&db).await.map_err(map_db_err)?;
    }

    let result = RefreshSeriesResultDto { succeeded, failed };
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
