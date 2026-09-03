use sea_orm::{ConnectionTrait, EntityTrait, QueryOrder, Statement, Value};

use crate::db::{connection, map_db_err};
use crate::entity::{characters, prelude::*};
use crate::error::HentaiError;

pub fn distinct_characters_sql() -> &'static str {
    "SELECT DISTINCT cc.character_name AS name \
     FROM comic_characters cc \
     INNER JOIN comics c ON c.comic_id = cc.comic_id \
     WHERE c.library_id = ? \
     ORDER BY cc.character_name COLLATE NOCASE"
}

pub async fn list_all_characters() -> Result<Vec<String>, HentaiError> {
    let db = connection()?;
    let rows = Characters::find()
        .order_by_asc(characters::Column::Name)
        .all(&db)
        .await
        .map_err(map_db_err)?;
    Ok(rows.into_iter().map(|r| r.name).collect())
}

pub async fn list_distinct_characters(
    library_id: Option<String>,
) -> Result<Vec<String>, HentaiError> {
    let Some(library_id) = crate::library::resolve_browse_library_id(library_id).await? else {
        return Ok(Vec::new());
    };
    let db = connection()?;
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            distinct_characters_sql(),
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
    fn distinct_characters_sql_scopes_current_library() {
        let sql = distinct_characters_sql();
        assert!(sql.contains("comic_characters cc"));
        assert!(sql.contains("c.library_id = ?"));
    }
}
