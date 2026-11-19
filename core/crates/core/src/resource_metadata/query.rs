use sea_orm::{ConnectionTrait, DatabaseBackend, Statement};

use crate::db::{connection, map_db_err};
use crate::error::HentaiError;

#[derive(Debug, Clone)]
pub struct MediaOverview {
    pub total: i64,
    pub disabled: i64,
    pub pending: i64,
    pub processing: i64,
    pub completed: i64,
    pub failed: i64,
    pub unsupported: i64,
    pub local_libraries: i64,
    pub enabled_libraries: i64,
}

/// Aggregate visible Local Resources without loading Comic metadata or job payloads.
pub async fn query_media_overview(show_r18: bool) -> Result<MediaOverview, HentaiError> {
    let db = connection()?;
    let row = db
        .query_one(Statement::from_sql_and_values(
            DatabaseBackend::Sqlite,
            "WITH visible AS (
            SELECT CASE WHEN COALESCE(w.enabled, 0) = 0 THEN 'disabled'
                        ELSE COALESCE(j.state, 'pending') END AS state
            FROM comics c JOIN libraries l USING(library_id) JOIN comic_meta m USING(comic_id)
            LEFT JOIN resource_metadata_libraries w USING(library_id)
            LEFT JOIN resource_metadata_jobs j USING(comic_id)
            WHERE l.kind = 'local' AND c.deleted_at IS NULL AND (? OR m.content_rating != 'r18')
        )
        SELECT COUNT(*) AS total,
            COALESCE(SUM(state = 'disabled'), 0) AS disabled,
            COALESCE(SUM(state = 'pending'), 0) AS pending,
            COALESCE(SUM(state = 'processing'), 0) AS processing,
            COALESCE(SUM(state = 'completed'), 0) AS completed,
            COALESCE(SUM(state = 'failed'), 0) AS failed,
            COALESCE(SUM(state = 'unsupported'), 0) AS unsupported,
            (SELECT COUNT(*) FROM libraries WHERE kind = 'local') AS local_libraries,
            (SELECT COUNT(*) FROM libraries l JOIN resource_metadata_libraries w USING(library_id)
                WHERE l.kind = 'local' AND w.enabled = 1) AS enabled_libraries
        FROM visible",
            [show_r18.into()],
        ))
        .await
        .map_err(|e| map_db_err(&e))?
        .ok_or_else(|| HentaiError::validation("Media overview missing"))?;
    Ok(MediaOverview {
        total: row.try_get("", "total").map_err(|e| map_db_err(&e))?,
        disabled: row.try_get("", "disabled").map_err(|e| map_db_err(&e))?,
        pending: row.try_get("", "pending").map_err(|e| map_db_err(&e))?,
        processing: row.try_get("", "processing").map_err(|e| map_db_err(&e))?,
        completed: row.try_get("", "completed").map_err(|e| map_db_err(&e))?,
        failed: row.try_get("", "failed").map_err(|e| map_db_err(&e))?,
        unsupported: row.try_get("", "unsupported").map_err(|e| map_db_err(&e))?,
        local_libraries: row.try_get("", "local_libraries").map_err(|e| map_db_err(&e))?,
        enabled_libraries: row.try_get("", "enabled_libraries").map_err(|e| map_db_err(&e))?,
    })
}
