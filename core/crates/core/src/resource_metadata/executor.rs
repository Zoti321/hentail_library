use std::path::{Path, PathBuf};

use sea_orm::{ConnectionTrait, DatabaseBackend, QueryResult, Statement, TransactionTrait};
use serde::{Deserialize, Serialize};

use crate::comic::{find_comic_by_id, now_ms};
use crate::db::{connection, map_db_err};
use crate::error::HentaiError;
use crate::library::find_library_by_id;
use crate::library_write::with_library_write;
use crate::resource::{local_access, read_source_stat};

use super::local::{file_digest, io_error, prepare};
use super::store::decode_fields;
use super::{MetadataSnapshot, MetadataWriteIntent};

#[derive(Debug, Serialize, Deserialize)]
struct Recovery {
    revision: i64,
    target: PathBuf,
    temporary: PathBuf,
    before_digest: Option<String>,
    after_digest: String,
    source_stat: (i64, i64),
}

/// Automatic lifecycle tick, never a user-facing manual-write command.
/// At most one Resource is processed, with the same fail-fast lock as sync/refresh.
pub async fn process_next() -> Result<bool, HentaiError> {
    with_library_write(|| process_next_locked(now_ms())).await
}

async fn process_next_locked(now: i64) -> Result<bool, HentaiError> {
    let db = connection()?;
    let row = db
        .query_one(Statement::from_sql_and_values(
            DatabaseBackend::Sqlite,
            "SELECT j.*, c.path, c.resource_type, c.library_id FROM resource_metadata_jobs j
         JOIN comics c USING(comic_id) JOIN libraries l USING(library_id)
         JOIN resource_metadata_libraries w USING(library_id)
         WHERE w.enabled = 1 AND l.kind = 'local' AND c.deleted_at IS NULL
           AND j.due_at <= ? AND (j.recovery IS NOT NULL OR j.state IN ('pending', 'failed'))
         ORDER BY CASE WHEN j.recovery IS NOT NULL THEN 0 ELSE 1 END, j.due_at, j.comic_id LIMIT 1",
            [now.into()],
        ))
        .await
        .map_err(|e| map_db_err(&e))?;
    let Some(row) = row else {
        return Ok(false);
    };
    let id: String = row.try_get("", "comic_id").map_err(|e| map_db_err(&e))?;
    let revision: i64 = row.try_get("", "revision").map_err(|e| map_db_err(&e))?;
    let path: String = row.try_get("", "path").map_err(|e| map_db_err(&e))?;
    let resource_type: String = row.try_get("", "resource_type").map_err(|e| map_db_err(&e))?;
    if !matches!(
        resource_type.as_str(),
        "dir" | "zip" | "cbz" | "sevenz" | "cb7" | "epub" | "pdf"
    ) {
        db.execute(Statement::from_sql_and_values(DatabaseBackend::Sqlite,
            "UPDATE resource_metadata_jobs SET state = 'unsupported', error = ? WHERE comic_id = ? AND revision = ?",
            [format!("Writeback is not available for {resource_type} on this build").into(), id.into(), revision.into()],
        )).await.map_err(|e| map_db_err(&e))?;
        crate::revision::notify_committed();
        return Ok(true);
    }
    let result = execute(&row, &id, &path, &resource_type).await;
    if let Err(error) = result {
        let attempts: i64 = row.try_get("", "attempts").map_err(|e| map_db_err(&e))?;
        let delay = 5000_i64
            .saturating_mul(1_i64 << attempts.clamp(0, 10))
            .min(3_600_000);
        db.execute(Statement::from_sql_and_values(DatabaseBackend::Sqlite,
            "UPDATE resource_metadata_jobs SET state = 'failed', attempts = attempts + 1, due_at = ?, error = ? WHERE comic_id = ?",
            [(now + delay).into(), error.message.into(), id.into()],
        )).await.map_err(|e| map_db_err(&e))?;
    }
    crate::revision::notify_committed();
    Ok(true)
}

async fn execute(
    row: &QueryResult,
    id: &str,
    source: &str,
    resource_type: &str,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let library_id: String = row.try_get("", "library_id").map_err(|e| map_db_err(&e))?;
    let library = find_library_by_id(&library_id)
        .await?
        .ok_or_else(|| io_error("Library disappeared"))?;
    let root = std::fs::canonicalize(&library.root_path).map_err(io_error)?;
    let source_path = Path::new(source);
    let canonical = std::fs::canonicalize(source_path).map_err(io_error)?;
    if canonical == root
        || !canonical.starts_with(&root)
        || std::fs::symlink_metadata(source_path)
            .map_err(io_error)?
            .file_type()
            .is_symlink()
    {
        return Err(io_error("Source is not a safe Local Library resource"));
    }
    let Some(recovery) = load_or_stage_recovery(&db, row, id, source_path, resource_type).await?
    else {
        return Ok(());
    };
    if invalidate_stale_recovery_plan(&db, id, source_path, resource_type, &recovery).await? {
        return Ok(());
    }
    if std::fs::symlink_metadata(&recovery.target).is_ok_and(|meta| meta.file_type().is_symlink()) {
        return Err(io_error("Metadata target became a symlink"));
    }
    if let Some(early) = persist_staged_recovery(&db, id, &recovery).await? {
        return early;
    }
    finalize(id, source, resource_type, &library_id, &recovery).await
}

async fn load_or_stage_recovery(
    db: &sea_orm::DatabaseConnection,
    row: &QueryResult,
    id: &str,
    source_path: &Path,
    resource_type: &str,
) -> Result<Option<Recovery>, HentaiError> {
    let existing: Option<String> = row.try_get("", "recovery").map_err(|e| map_db_err(&e))?;
    if let Some(raw) = existing {
        return serde_json::from_str::<Recovery>(&raw)
            .map_err(io_error)
            .map(Some);
    }
    let revision: i64 = row.try_get("", "revision").map_err(|e| map_db_err(&e))?;
    let fields: String = row.try_get("", "fields").map_err(|e| map_db_err(&e))?;
    let snapshot: String = row.try_get("", "snapshot").map_err(|e| map_db_err(&e))?;
    let intent = MetadataWriteIntent {
        snapshot: serde_json::from_str::<MetadataSnapshot>(&snapshot).map_err(io_error)?,
        fields: decode_fields(&fields)?,
    };
    let source_stat = read_source_stat(source_path, resource_type)?
        .ok_or_else(|| io_error("Source disappeared"))?;
    let prepared = prepare(source_path, resource_type, &intent)?;
    let recovery = Recovery {
        revision,
        target: prepared.target,
        temporary: prepared.temporary.path().to_owned(),
        before_digest: prepared.before_digest,
        after_digest: prepared.after_digest,
        source_stat,
    };
    let raw = serde_json::to_string(&recovery).map_err(io_error)?;
    let result = db
        .execute(Statement::from_sql_and_values(
            DatabaseBackend::Sqlite,
            "UPDATE resource_metadata_jobs SET state = 'processing', recovery = ? WHERE comic_id = ? AND revision = ?",
            [raw.into(), id.into(), revision.into()],
        ))
        .await
        .map_err(|e| map_db_err(&e))?;
    if result.rows_affected() == 0 {
        return Ok(None);
    }
    crate::revision::notify_committed();
    // Keep exactly this temporary file for restart recovery after its path is durable.
    let (file, _) = prepared.temporary.keep().map_err(io_error)?;
    drop(file);
    Ok(Some(recovery))
}

async fn invalidate_stale_recovery_plan(
    db: &sea_orm::DatabaseConnection,
    id: &str,
    source_path: &Path,
    resource_type: &str,
    recovery: &Recovery,
) -> Result<bool, HentaiError> {
    let parent = source_path
        .parent()
        .ok_or_else(|| io_error("Missing source parent"))?;
    if recovery.temporary.parent() == Some(parent)
        && recovery
            .temporary
            .file_name()
            .is_some_and(|name| name.to_string_lossy().starts_with(".hlwriteback-"))
        && (resource_type == "dir" || recovery.target == source_path)
        && (resource_type != "dir"
            || (recovery.target.parent() == Some(source_path)
                && recovery.target.file_name().is_some_and(|name| {
                    name.to_string_lossy()
                        .eq_ignore_ascii_case("ComicInfo.xml")
                })))
    {
        return Ok(false);
    }
    db.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "UPDATE resource_metadata_jobs SET state = 'pending', recovery = NULL, due_at = 0 WHERE comic_id = ?",
        [id.into()],
    ))
    .await
    .map_err(|e| map_db_err(&e))?;
    Ok(true)
}

async fn persist_staged_recovery(
    db: &sea_orm::DatabaseConnection,
    id: &str,
    recovery: &Recovery,
) -> Result<Option<Result<(), HentaiError>>, HentaiError> {
    let actual = file_digest(&recovery.target)?;
    if actual.as_deref() == Some(&recovery.after_digest) {
        return Ok(None);
    }
    if actual != recovery.before_digest
        || file_digest(&recovery.temporary)?.as_deref() != Some(&recovery.after_digest)
    {
        db.execute(Statement::from_sql_and_values(
            DatabaseBackend::Sqlite,
            "UPDATE resource_metadata_jobs SET recovery = NULL WHERE comic_id = ?",
            [id.into()],
        ))
        .await
        .map_err(|e| map_db_err(&e))?;
        if recovery.temporary.is_file() {
            std::fs::remove_file(&recovery.temporary).map_err(io_error)?;
        }
        return Ok(Some(Err(io_error(
            "Source changed or staged output was lost; automatic retry will re-merge",
        ))));
    }
    let current = db
        .query_one(Statement::from_sql_and_values(
            DatabaseBackend::Sqlite,
            "SELECT revision FROM resource_metadata_jobs WHERE comic_id = ?",
            [id.into()],
        ))
        .await
        .map_err(|e| map_db_err(&e))?
        .ok_or_else(|| io_error("Writeback job disappeared"))?;
    if current.try_get::<i64>("", "revision").map_err(|e| map_db_err(&e))? != recovery.revision {
        db.execute(Statement::from_sql_and_values(
            DatabaseBackend::Sqlite,
            "UPDATE resource_metadata_jobs SET state = 'pending', recovery = NULL, due_at = 0 WHERE comic_id = ?",
            [id.into()],
        ))
        .await
        .map_err(|e| map_db_err(&e))?;
        if recovery.temporary.is_file() {
            std::fs::remove_file(&recovery.temporary).map_err(io_error)?;
        }
        return Ok(Some(Ok(())));
    }
    crate::reader::close_reader(id);
    let permissions = std::fs::metadata(&recovery.target).map(|meta| meta.permissions());
    if let Ok(permissions) = permissions {
        std::fs::set_permissions(&recovery.temporary, permissions).map_err(io_error)?;
    }
    tempfile::TempPath::try_from_path(&recovery.temporary)
        .map_err(io_error)?
        .persist(&recovery.target)
        .map_err(io_error)?;
    Ok(None)
}

async fn finalize(
    id: &str,
    source: &str,
    resource_type: &str,
    library_id: &str,
    recovery: &Recovery,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let stat = read_source_stat(Path::new(source), resource_type)?
        .ok_or_else(|| io_error("Written Resource disappeared"))?;
    let comic = find_comic_by_id(id)
        .await?
        .ok_or_else(|| io_error("Comic disappeared"))?;
    let item = crate::sync::scanner::ScanItem::from_resource(comic);
    let digest = crate::sync::fingerprint::content_digest(
        local_access(),
        &item,
        &crate::create_sync_handle(),
    )?;
    if read_source_stat(Path::new(source), resource_type)? != Some(stat)
        || file_digest(&recovery.target)?.as_deref() != Some(&recovery.after_digest)
    {
        return Err(io_error("Source changed during observation reconciliation"));
    }
    let txn = db.begin().await.map_err(|e| map_db_err(&e))?;
    txn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "UPDATE comics SET resource_size = ? WHERE comic_id = ?",
        [stat.1.into(), id.into()],
    ))
    .await
    .map_err(|e| map_db_err(&e))?;
    txn.execute(Statement::from_sql_and_values(DatabaseBackend::Sqlite,
        "UPDATE library_resource_snapshots SET modified_ms = ?, size = ? WHERE library_id = ? AND location_key = ? AND modified_ms = ? AND size = ?",
        [stat.0.into(), stat.1.into(), library_id.into(), crate::comic_id::normalize_path_for_key(source).into(), recovery.source_stat.0.into(), recovery.source_stat.1.into()],
    )).await.map_err(|e| map_db_err(&e))?;
    if let Some(digest) = digest {
        txn.execute(Statement::from_sql_and_values(DatabaseBackend::Sqlite,
            "INSERT INTO comic_content_fingerprints(comic_id, digest, resource_type, modified_ms, size) VALUES (?, ?, ?, ?, ?)
             ON CONFLICT(comic_id) DO UPDATE SET digest = excluded.digest, resource_type = excluded.resource_type, modified_ms = excluded.modified_ms, size = excluded.size",
            [id.into(), digest.into(), resource_type.into(), stat.0.into(), stat.1.into()],
        )).await.map_err(|e| map_db_err(&e))?;
    } else {
        txn.execute(Statement::from_sql_and_values(
            DatabaseBackend::Sqlite,
            "DELETE FROM comic_content_fingerprints WHERE comic_id = ?",
            [id.into()],
        ))
        .await
        .map_err(|e| map_db_err(&e))?;
    }
    txn.execute(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "UPDATE resource_metadata_jobs SET applied_revision = ?, last_success_at = ?,
            state = CASE WHEN revision = ? THEN 'completed' ELSE 'pending' END,
            fields = CASE WHEN revision = ? THEN '[]' ELSE fields END,
            error = NULL, attempts = 0, due_at = 0, recovery = NULL WHERE comic_id = ?",
        [
            recovery.revision.into(),
            now_ms().into(),
            recovery.revision.into(),
            recovery.revision.into(),
            id.into(),
        ],
    ))
    .await
    .map_err(|e| map_db_err(&e))?;
    txn.commit().await.map_err(|e| map_db_err(&e))?;
    if recovery.temporary.is_file() {
        std::fs::remove_file(&recovery.temporary).map_err(io_error)?;
    }
    Ok(())
}
