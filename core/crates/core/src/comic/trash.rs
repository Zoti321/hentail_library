//! Comic trash → Comic purge (ADR-0023; purge disk semantics from ADR-0012).

use std::collections::{HashMap, HashSet};
use std::path::Path;

use sea_orm::{ConnectionTrait, DatabaseConnection, Statement, TransactionTrait, Value};

use crate::comic::dto::{now_ms, ComicDto};
use crate::comic::repository::load_comics_ordered;
use crate::comic_id::normalize_path_for_key;
use crate::db::{connection, map_db_err};
use crate::error::HentaiError;
use crate::reader::close_reader;
use crate::sync::library_lock::try_acquire_library_write_lock;
use crate::sync::series_rebuild::rebuild_series_from_comics;
use crate::sync::writer::delete_comics_side_effects;

const MAX_ERROR_SAMPLES: usize = 5;
const ID_BATCH_SIZE: usize = 500;
const KIND_REMOTE: &str = "remote";

#[derive(Debug, Clone, Default)]
pub struct ComicPurgeResultDto {
    pub succeeded: i32,
    pub failed: i32,
    pub error_samples: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct TrashedComicDto {
    pub comic: ComicDto,
    pub deleted_at: i64,
    pub library_name: String,
    /// `local` / `remote`.
    pub library_kind: String,
}

#[derive(Debug, Clone)]
pub struct PagedTrashedComicResultDto {
    pub items: Vec<TrashedComicDto>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct TrashedComicCountsDto {
    pub total: i64,
    pub local: i64,
    pub remote: i64,
}

struct PurgeTarget {
    comic_id: String,
    path: String,
    resource_type: String,
    library_kind: String,
    library_root_path: String,
    deleted_at: Option<i64>,
}

/// Comic trash：标记删除时间；库记录、元数据、阅读历史与 Resource 原样保留。
pub async fn trash_comics(comic_ids: Vec<String>) -> Result<(), HentaiError> {
    let ids = dedupe_ids(comic_ids);
    if ids.is_empty() {
        return Ok(());
    }
    let _guard = try_acquire_library_write_lock()?;
    let db = connection()?;
    let deleted_at = now_ms();
    let txn = db.begin().await.map_err(map_db_err)?;
    for chunk in ids.chunks(ID_BATCH_SIZE) {
        let (placeholders, mut values) = id_placeholders(chunk);
        values.insert(0, Value::BigInt(Some(deleted_at)));
        txn.execute(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "UPDATE comics SET deleted_at = ? \
                 WHERE comic_id IN ({placeholders}) AND deleted_at IS NULL"
            ),
            values,
        ))
        .await
        .map_err(map_db_err)?;
    }
    txn.commit().await.map_err(map_db_err)?;
    for id in &ids {
        close_reader(id);
    }
    Ok(())
}

/// Comic restore：清除删除时间。
pub async fn restore_comics(comic_ids: Vec<String>) -> Result<(), HentaiError> {
    let ids = dedupe_ids(comic_ids);
    if ids.is_empty() {
        return Ok(());
    }
    let _guard = try_acquire_library_write_lock()?;
    let db = connection()?;
    let txn = db.begin().await.map_err(map_db_err)?;
    for chunk in ids.chunks(ID_BATCH_SIZE) {
        let (placeholders, values) = id_placeholders(chunk);
        txn.execute(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!("UPDATE comics SET deleted_at = NULL WHERE comic_id IN ({placeholders})"),
            values,
        ))
        .await
        .map_err(map_db_err)?;
    }
    txn.commit().await.map_err(map_db_err)?;
    Ok(())
}

/// Comic purge：逐本处理；Local 先删 Resource 再清库，删盘失败者留在 trash。
/// 未处于 trash 的 id 计入失败。
pub async fn purge_comics(comic_ids: Vec<String>) -> Result<ComicPurgeResultDto, HentaiError> {
    let ids = dedupe_ids(comic_ids);
    let mut result = ComicPurgeResultDto::default();
    if ids.is_empty() {
        return Ok(result);
    }
    let _guard = try_acquire_library_write_lock()?;
    let db = connection()?;
    let targets = load_purge_targets(&db, &ids).await?;
    for id in &ids {
        let outcome = match targets.get(id) {
            None => Err(HentaiError::validation(format!("漫画不存在：{id}"))),
            Some(target) if target.deleted_at.is_none() => Err(HentaiError::validation(format!(
                "漫画未处于「已删除」，已拒绝永久删除：{id}"
            ))),
            Some(target) => purge_one(&db, target).await,
        };
        match outcome {
            Ok(()) => result.succeeded += 1,
            Err(error) => {
                result.failed += 1;
                push_error_sample(&mut result, error.message);
            }
        }
    }
    if result.succeeded > 0 {
        // Purged rows and Resources are already gone; a rebuild failure must not
        // hide the per-comic summary. The next sync rebuilds Series again.
        if let Err(err) = rebuild_series_after_purge(&db).await {
            tracing::warn!(error = %err, "purge 后系列重建失败");
            push_error_sample(&mut result, format!("系列重建失败: {err}"));
        }
    }
    Ok(result)
}

fn push_error_sample(result: &mut ComicPurgeResultDto, message: String) {
    if result.error_samples.len() < MAX_ERROR_SAMPLES {
        result.error_samples.push(message);
    }
}

async fn rebuild_series_after_purge(db: &DatabaseConnection) -> Result<(), HentaiError> {
    let txn = db.begin().await.map_err(map_db_err)?;
    rebuild_series_from_comics(&txn, None).await?;
    txn.commit().await.map_err(map_db_err)?;
    Ok(())
}

async fn purge_one(db: &DatabaseConnection, target: &PurgeTarget) -> Result<(), HentaiError> {
    close_reader(&target.comic_id);
    maybe_delete_local_resource(target)?;
    let txn = db.begin().await.map_err(map_db_err)?;
    delete_comics_side_effects(&txn, std::slice::from_ref(&target.comic_id)).await?;
    txn.commit().await.map_err(map_db_err)?;
    Ok(())
}

/// 「已删除」列表：跨全部 Library，按删除时间倒序。
pub async fn fetch_trashed_comics_page(
    page: i32,
    page_size: i32,
) -> Result<PagedTrashedComicResultDto, HentaiError> {
    let page = page.max(1);
    let page_size = page_size.max(1);
    let db = connection()?;
    let total_count = count_trashed_comics().await?.total;
    let offset = (page as i64 - 1) * page_size as i64;
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT c.comic_id, c.deleted_at, l.name, l.kind \
             FROM comics c \
             INNER JOIN libraries l ON l.library_id = c.library_id \
             WHERE c.deleted_at IS NOT NULL \
             ORDER BY c.deleted_at DESC, c.comic_id ASC \
             LIMIT ? OFFSET ?",
            [
                Value::BigInt(Some(page_size as i64)),
                Value::BigInt(Some(offset)),
            ],
        ))
        .await
        .map_err(map_db_err)?;
    let mut rows_meta = Vec::with_capacity(rows.len());
    for row in rows {
        rows_meta.push((
            row_string(&row, 0)?,
            row.try_get_by_index::<i64>(1)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
            row_string(&row, 2)?,
            row_string(&row, 3)?,
        ));
    }
    let comic_ids = rows_meta.iter().map(|(id, ..)| id.clone()).collect();
    let mut comics: HashMap<String, ComicDto> = load_comics_ordered(&db, comic_ids)
        .await?
        .into_iter()
        .map(|comic| (comic.comic_id.clone(), comic))
        .collect();
    let mut items = Vec::with_capacity(rows_meta.len());
    for (comic_id, deleted_at, library_name, library_kind) in rows_meta {
        let Some(comic) = comics.remove(&comic_id) else {
            continue;
        };
        items.push(TrashedComicDto {
            comic,
            deleted_at,
            library_name,
            library_kind,
        });
    }
    Ok(PagedTrashedComicResultDto {
        items,
        total_count,
        page,
        page_size,
    })
}

pub async fn count_trashed_comics() -> Result<TrashedComicCountsDto, HentaiError> {
    let db = connection()?;
    let row = db
        .query_one(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT COUNT(*), COALESCE(SUM(CASE WHEN l.kind = ? THEN 1 ELSE 0 END), 0) \
             FROM comics c \
             INNER JOIN libraries l ON l.library_id = c.library_id \
             WHERE c.deleted_at IS NOT NULL",
            [Value::String(Some(Box::new(KIND_REMOTE.to_string())))],
        ))
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::db_query_failed("trash count 无结果", None))?;
    let total = row
        .try_get_by_index::<i64>(0)
        .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
    let remote = row
        .try_get_by_index::<i64>(1)
        .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
    Ok(TrashedComicCountsDto {
        total,
        local: total - remote,
        remote,
    })
}

/// 「全部永久删除」用：全部处于 trash 的 comic_id。
pub async fn list_trashed_comic_ids() -> Result<Vec<String>, HentaiError> {
    let db = connection()?;
    let rows = db
        .query_all(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT comic_id FROM comics WHERE deleted_at IS NOT NULL \
             ORDER BY deleted_at DESC, comic_id ASC"
                .to_string(),
        ))
        .await
        .map_err(map_db_err)?;
    rows.iter().map(|row| row_string(row, 0)).collect()
}

/// Read session 打开前的 trash 校验；库不可用时不拦截（由打开路径自行报错）。
pub async fn is_comic_trashed(comic_id: &str) -> Result<bool, HentaiError> {
    let db = connection()?;
    let row = db
        .query_one(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT 1 FROM comics WHERE comic_id = ? AND deleted_at IS NOT NULL",
            [Value::String(Some(Box::new(comic_id.to_string())))],
        ))
        .await
        .map_err(map_db_err)?;
    Ok(row.is_some())
}

async fn load_purge_targets<C: ConnectionTrait>(
    db: &C,
    comic_ids: &[String],
) -> Result<HashMap<String, PurgeTarget>, HentaiError> {
    let mut targets = HashMap::with_capacity(comic_ids.len());
    for chunk in comic_ids.chunks(ID_BATCH_SIZE) {
        let (placeholders, values) = id_placeholders(chunk);
        let rows = db
            .query_all(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "SELECT c.comic_id, c.path, c.resource_type, l.kind, l.root_path, c.deleted_at \
                     FROM comics c \
                     INNER JOIN libraries l ON l.library_id = c.library_id \
                     WHERE c.comic_id IN ({placeholders})"
                ),
                values,
            ))
            .await
            .map_err(map_db_err)?;
        for row in &rows {
            let target = PurgeTarget {
                comic_id: row_string(row, 0)?,
                path: row_string(row, 1)?,
                resource_type: row_string(row, 2)?,
                library_kind: row_string(row, 3)?,
                library_root_path: row_string(row, 4)?,
                deleted_at: row
                    .try_get_by_index::<Option<i64>>(5)
                    .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
            };
            targets.insert(target.comic_id.clone(), target);
        }
    }
    Ok(targets)
}

fn maybe_delete_local_resource(target: &PurgeTarget) -> Result<(), HentaiError> {
    if target.library_kind == KIND_REMOTE {
        return Ok(());
    }
    ensure_local_resource_within_library_root(target)?;
    let path = Path::new(&target.path);
    if !path.exists() {
        return Ok(());
    }
    let delete_result = if target.resource_type == "dir" {
        std::fs::remove_dir_all(path)
    } else {
        std::fs::remove_file(path)
    };
    delete_result.map_err(|error| {
        HentaiError::validation(format!(
            "无法删除磁盘资源，漫画仍保留在「已删除」中：{}（{error}）",
            target.path
        ))
    })
}

fn ensure_local_resource_within_library_root(target: &PurgeTarget) -> Result<(), HentaiError> {
    let normalized_root = normalize_path_for_key(&target.library_root_path);
    let normalized_path = normalize_path_for_key(&target.path);
    if normalized_root.is_empty() || normalized_path.is_empty() {
        return Err(HentaiError::validation(format!(
            "漫画资源路径异常，已取消永久删除：{}",
            target.comic_id
        )));
    }
    if normalized_path == normalized_root
        || !normalized_path.starts_with(&format!("{normalized_root}/"))
    {
        return Err(HentaiError::validation(format!(
            "漫画资源不在所属 Library root 下，已取消永久删除：{}",
            target.path
        )));
    }
    Ok(())
}

fn dedupe_ids(comic_ids: Vec<String>) -> Vec<String> {
    let mut seen = HashSet::new();
    comic_ids
        .into_iter()
        .map(|id| id.trim().to_string())
        .filter(|id| !id.is_empty() && seen.insert(id.clone()))
        .collect()
}

fn id_placeholders(ids: &[String]) -> (String, Vec<Value>) {
    let placeholders = ids.iter().map(|_| "?").collect::<Vec<_>>().join(",");
    let values = ids
        .iter()
        .map(|id| Value::String(Some(Box::new(id.clone()))))
        .collect();
    (placeholders, values)
}

fn row_string(row: &sea_orm::QueryResult, index: usize) -> Result<String, HentaiError> {
    row.try_get_by_index::<String>(index)
        .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
}
