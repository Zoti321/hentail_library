use sea_orm::{ConnectionTrait, EntityTrait, QueryOrder, Statement, Value};

use crate::db::{connection, map_db_err};
use crate::entity::{parodies, prelude::*};
use crate::error::HentaiError;

pub fn distinct_parodies_sql() -> &'static str {
    "SELECT DISTINCT cp.parody_name AS name \
     FROM comic_parodies cp \
     INNER JOIN comics c ON c.comic_id = cp.comic_id \
     WHERE c.library_id = ? \
     ORDER BY cp.parody_name COLLATE NOCASE"
}

pub async fn list_all_parodies() -> Result<Vec<String>, HentaiError> {
    let db = connection()?;
    let rows = Parodies::find()
        .order_by_asc(parodies::Column::Name)
        .all(&db)
        .await
        .map_err(map_db_err)?;
    Ok(rows.into_iter().map(|r| r.name).collect())
}

pub async fn list_distinct_parodies(
    library_id: Option<String>,
) -> Result<Vec<String>, HentaiError> {
    let Some(library_id) = crate::library::resolve_browse_library_id(library_id).await? else {
        return Ok(Vec::new());
    };
    let db = connection()?;
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            distinct_parodies_sql(),
            [Value::String(Some(Box::new(library_id)))],
        ))
        .await
        .map_err(map_db_err)?;
    rows.into_iter()
        .map(|row| {
            row.try_get_by_index::<String>(0)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn distinct_parodies_sql_scopes_current_library() {
        let sql = distinct_parodies_sql();
        assert!(sql.contains("comic_parodies cp"));
        assert!(sql.contains("c.library_id = ?"));
    }
}
