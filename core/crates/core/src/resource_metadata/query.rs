use sea_orm::{ConnectionTrait, DatabaseBackend, Statement, Value};

use crate::comic::{repository::load_comics_ordered, ComicDto};
use crate::db::{connection, map_db_err};
use crate::error::HentaiError;

#[derive(Debug, Clone)]
pub struct MediaResource {
    pub comic: ComicDto,
    pub library_name: String,
    pub state: String,
    pub error: Option<String>,
    pub last_success_at: Option<i64>,
}

#[derive(Debug, Clone)]
pub struct MediaPage {
    pub items: Vec<MediaResource>,
    pub total: i64,
}

pub async fn query_media(
    library_id: Option<String>,
    state: Option<String>,
    show_r18: bool,
    offset: i64,
    limit: i64,
) -> Result<MediaPage, HentaiError> {
    let db = connection()?;
    let mut predicates = vec!["l.kind = 'local'", "c.deleted_at IS NULL"];
    let mut values: Vec<Value> = Vec::new();
    if let Some(library) = library_id.filter(|id| !id.is_empty()) {
        predicates.push("c.library_id = ?");
        values.push(library.into());
    }
    if !show_r18 {
        predicates.push("m.content_rating != 'r18'");
    }
    let state_sql = "CASE WHEN COALESCE(w.enabled, 0) = 0 THEN 'disabled' ELSE COALESCE(j.state, 'pending') END";
    let state_predicate;
    if let Some(state) = state.filter(|state| !state.is_empty()) {
        if ![
            "disabled",
            "pending",
            "processing",
            "completed",
            "failed",
            "unsupported",
        ]
        .contains(&state.as_str())
        {
            return Err(HentaiError::validation(
                "Unknown Resource metadata embedding state",
            ));
        }
        state_predicate = format!("{state_sql} = ?");
        predicates.push(&state_predicate);
        values.push(state.into());
    }
    let from = format!("FROM comics c JOIN libraries l USING(library_id) JOIN comic_meta m USING(comic_id)
        LEFT JOIN resource_metadata_libraries w USING(library_id) LEFT JOIN resource_metadata_jobs j USING(comic_id)
        WHERE {}", predicates.join(" AND "));
    let total = db
        .query_one(Statement::from_sql_and_values(
            DatabaseBackend::Sqlite,
            format!("SELECT COUNT(*) AS count {from}"),
            values.clone(),
        ))
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::validation("Media count missing"))?
        .try_get::<i64>("", "count")
        .map_err(map_db_err)?;
    values.push(limit.clamp(1, 100).into());
    values.push(offset.max(0).into());
    let rows = db.query_all(Statement::from_sql_and_values(DatabaseBackend::Sqlite,
        format!("SELECT c.comic_id, l.name AS library_name, {state_sql} AS state, j.error, j.last_success_at {from} ORDER BY l.name, m.title_sort_key, c.comic_id LIMIT ? OFFSET ?"), values,
    )).await.map_err(map_db_err)?;
    let ids = rows
        .iter()
        .map(|row| row.try_get::<String>("", "comic_id").map_err(map_db_err))
        .collect::<Result<Vec<_>, _>>()?;
    let mut comics = load_comics_ordered(&db, ids).await?.into_iter();
    let mut items = Vec::new();
    for row in rows {
        if let Some(comic) = comics.next() {
            items.push(MediaResource {
                comic,
                library_name: row.try_get("", "library_name").map_err(map_db_err)?,
                state: row.try_get("", "state").map_err(map_db_err)?,
                error: row.try_get("", "error").map_err(map_db_err)?,
                last_success_at: row.try_get("", "last_success_at").map_err(map_db_err)?,
            });
        }
    }
    Ok(MediaPage { items, total })
}
