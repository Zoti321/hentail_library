use std::collections::BTreeSet;

use sea_orm::{ConnectionTrait, DatabaseBackend, Statement, TransactionTrait};

use crate::comic::repository::find_visible_comic_by_id_in;
use crate::db::{connection, map_db_err};
use crate::error::HentaiError;
use crate::library_write::with_library_write;
use crate::metadata_lock::ComicMetaField;

use super::{MetadataSnapshot, MetadataWriteIntent};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WritebackStatus {
    pub comic_id: String,
    pub state: String,
    pub revision: i64,
    pub applied_revision: i64,
    pub last_success_at: Option<i64>,
    pub error: Option<String>,
}

pub async fn is_enabled(library_id: &str) -> Result<bool, HentaiError> {
    enabled_in(&connection()?, library_id).await
}

async fn enabled_in(db: &impl ConnectionTrait, library_id: &str) -> Result<bool, HentaiError> {
    let row = db.query_one(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "SELECT w.enabled FROM resource_metadata_libraries w JOIN libraries l USING(library_id) WHERE w.library_id = ? AND l.kind = 'local'",
        [library_id.into()],
    )).await.map_err(map_db_err)?;
    row.map(|row| row.try_get::<i64>("", "enabled").map(|value| value == 1))
        .transpose()
        .map(|value| value.unwrap_or(false))
        .map_err(map_db_err)
}

pub async fn set_enabled(library_id: &str, enabled: bool) -> Result<(), HentaiError> {
    with_library_write(|| async {
        let db = connection()?;
        let txn = db.begin().await.map_err(map_db_err)?;
        let row = txn.query_one(Statement::from_sql_and_values(
            DatabaseBackend::Sqlite, "SELECT kind FROM libraries WHERE library_id = ?", [library_id.into()],
        )).await.map_err(map_db_err)?.ok_or_else(|| HentaiError::validation("Library is unavailable"))?;
        if row.try_get::<String>("", "kind").map_err(map_db_err)? != "local" {
            return Err(HentaiError::validation("Resource metadata embedding is only available for Local libraries"));
        }
        let previous = enabled_in(&txn, library_id).await?;
        txn.execute(Statement::from_sql_and_values(DatabaseBackend::Sqlite,
            "INSERT INTO resource_metadata_libraries(library_id, enabled) VALUES (?, ?) ON CONFLICT(library_id) DO UPDATE SET enabled = excluded.enabled",
            [library_id.into(), i64::from(enabled).into()],
        )).await.map_err(map_db_err)?;
        if enabled && !previous {
            let comics = txn.query_all(Statement::from_sql_and_values(DatabaseBackend::Sqlite,
                "SELECT comic_id FROM comics WHERE library_id = ? AND deleted_at IS NULL", [library_id.into()],
            )).await.map_err(map_db_err)?;
            for row in comics {
                let id: String = row.try_get("", "comic_id").map_err(map_db_err)?;
                if let Some(comic) = find_visible_comic_by_id_in(&txn, &id).await? {
                    enqueue_in(&txn, &id, MetadataWriteIntent::full(MetadataSnapshot::from(&comic))).await?;
                }
            }
        }
        txn.commit().await.map_err(map_db_err)?;
        crate::revision::notify_committed();
        Ok(())
    }).await
}

pub(crate) async fn capture_before_in(
    db: &impl ConnectionTrait,
    comic_id: &str,
) -> Result<Option<MetadataSnapshot>, HentaiError> {
    let Some(comic) = find_visible_comic_by_id_in(db, comic_id).await? else {
        return Ok(None);
    };
    if !enabled_in(db, &comic.library_id).await? {
        return Ok(None);
    }
    Ok(Some(MetadataSnapshot::from(&comic)))
}

pub(crate) async fn record_change_in(
    db: &impl ConnectionTrait,
    comic_id: &str,
    previous: Option<MetadataSnapshot>,
) -> Result<(), HentaiError> {
    let Some(previous) = previous else {
        return Ok(());
    };
    let Some(comic) = find_visible_comic_by_id_in(db, comic_id).await? else {
        return Ok(());
    };
    if enabled_in(db, &comic.library_id).await? {
        enqueue_in(
            db,
            comic_id,
            MetadataWriteIntent::changed(&previous, MetadataSnapshot::from(&comic)),
        )
        .await?;
    }
    Ok(())
}

pub(super) async fn enqueue_in(
    db: &impl ConnectionTrait,
    comic_id: &str,
    mut intent: MetadataWriteIntent,
) -> Result<(), HentaiError> {
    if intent.fields.is_empty() {
        return Ok(());
    }
    if let Some(row) = db
        .query_one(Statement::from_sql_and_values(
            DatabaseBackend::Sqlite,
            "SELECT fields FROM resource_metadata_jobs WHERE comic_id = ?",
            [comic_id.into()],
        ))
        .await
        .map_err(map_db_err)?
    {
        let raw: String = row.try_get("", "fields").map_err(map_db_err)?;
        intent.fields.extend(decode_fields(&raw)?);
    }
    let fields = encode_fields(&intent.fields)?;
    let snapshot = serde_json::to_string(&intent.snapshot)
        .map_err(|err| HentaiError::validation(err.to_string()))?;
    db.execute(Statement::from_sql_and_values(DatabaseBackend::Sqlite,
        "INSERT INTO resource_metadata_jobs(comic_id, revision, fields, snapshot) VALUES (?, 1, ?, ?)
         ON CONFLICT(comic_id) DO UPDATE SET revision = revision + 1, fields = excluded.fields, snapshot = excluded.snapshot,
            state = CASE WHEN recovery IS NULL THEN 'pending' ELSE state END, attempts = 0, due_at = 0, error = NULL",
        [comic_id.into(), fields.into(), snapshot.into()],
    )).await.map_err(map_db_err)?;
    Ok(())
}

pub(super) fn encode_fields(fields: &BTreeSet<ComicMetaField>) -> Result<String, HentaiError> {
    serde_json::to_string(
        &fields
            .iter()
            .map(|field| field.as_str())
            .collect::<Vec<_>>(),
    )
    .map_err(|err| HentaiError::validation(err.to_string()))
}

pub(crate) async fn capture_affected_in(
    db: &impl ConnectionTrait,
    ids: Vec<String>,
) -> Result<Vec<(String, MetadataSnapshot)>, HentaiError> {
    let mut captured = Vec::new();
    for id in ids {
        if let Some(snapshot) = capture_before_in(db, &id).await? {
            captured.push((id, snapshot));
        }
    }
    Ok(captured)
}

pub(crate) async fn reschedule_in(db: &impl ConnectionTrait, id: &str) -> Result<(), HentaiError> {
    if let Some(comic) = find_visible_comic_by_id_in(db, id).await? {
        if enabled_in(db, &comic.library_id).await? {
            enqueue_in(
                db,
                id,
                MetadataWriteIntent::full(MetadataSnapshot::from(&comic)),
            )
            .await?;
        }
    }
    Ok(())
}

pub(crate) async fn record_affected_in(
    db: &impl ConnectionTrait,
    captured: Vec<(String, MetadataSnapshot)>,
) -> Result<(), HentaiError> {
    for (id, snapshot) in captured {
        record_change_in(db, &id, Some(snapshot)).await?;
    }
    Ok(())
}

pub(super) fn decode_fields(raw: &str) -> Result<BTreeSet<ComicMetaField>, HentaiError> {
    let keys: Vec<String> =
        serde_json::from_str(raw).map_err(|err| HentaiError::validation(err.to_string()))?;
    keys.iter()
        .map(|key| {
            ComicMetaField::ALL
                .into_iter()
                .find(|field| field.as_str() == key)
                .ok_or_else(|| HentaiError::validation(format!("Unknown writeback field: {key}")))
        })
        .collect()
}

pub async fn status_for_comic(comic_id: &str) -> Result<Option<WritebackStatus>, HentaiError> {
    let db = connection()?;
    let row = db.query_one(Statement::from_sql_and_values(DatabaseBackend::Sqlite,
        "SELECT c.comic_id,
            CASE WHEN COALESCE(w.enabled, 0) = 0 THEN 'disabled' ELSE COALESCE(j.state, 'pending') END AS state,
            COALESCE(j.revision, 0) AS revision, COALESCE(j.applied_revision, 0) AS applied_revision,
            j.last_success_at, j.error
         FROM comics c JOIN libraries l USING(library_id)
         LEFT JOIN resource_metadata_libraries w USING(library_id)
         LEFT JOIN resource_metadata_jobs j USING(comic_id)
         WHERE c.comic_id = ? AND c.deleted_at IS NULL AND l.kind = 'local'", [comic_id.into()],
    )).await.map_err(map_db_err)?;
    row.map(|row| {
        Ok(WritebackStatus {
            comic_id: row.try_get("", "comic_id").map_err(map_db_err)?,
            state: row.try_get("", "state").map_err(map_db_err)?,
            revision: row.try_get("", "revision").map_err(map_db_err)?,
            applied_revision: row.try_get("", "applied_revision").map_err(map_db_err)?,
            last_success_at: row.try_get("", "last_success_at").map_err(map_db_err)?,
            error: row.try_get("", "error").map_err(map_db_err)?,
        })
    })
    .transpose()
}
