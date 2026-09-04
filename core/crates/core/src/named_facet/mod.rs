//! Junction-backed named metadata facets (Tag / Author / Parody / Character).
//!
//! Language is a closed-set JSON column on `comic_meta` and is not handled here.

use sea_orm::{ConnectionTrait, Statement, Value};

use crate::db::{connection, map_db_err};
use crate::error::HentaiError;

/// Named metadata facet stored as a global dictionary table + comic junction.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum JunctionNamedFacet {
    Tag,
    Author,
    Parody,
    Character,
}

impl JunctionNamedFacet {
    pub fn dict_table(self) -> &'static str {
        match self {
            Self::Tag => "tags",
            Self::Author => "authors",
            Self::Parody => "parodies",
            Self::Character => "characters",
        }
    }

    pub fn junction_table(self) -> &'static str {
        match self {
            Self::Tag => "comic_tags",
            Self::Author => "comic_authors",
            Self::Parody => "comic_parodies",
            Self::Character => "comic_characters",
        }
    }

    pub fn junction_name_column(self) -> &'static str {
        match self {
            Self::Tag => "tag_name",
            Self::Author => "author_name",
            Self::Parody => "parody_name",
            Self::Character => "character_name",
        }
    }

    /// Library-scoped distinct attached names (ORDER BY name COLLATE NOCASE).
    pub fn distinct_attached_sql(self) -> String {
        let junction = self.junction_table();
        let name_col = self.junction_name_column();
        format!(
            "SELECT DISTINCT j.{name_col} AS name \
             FROM {junction} j \
             INNER JOIN comics c ON c.comic_id = j.comic_id \
             WHERE c.library_id = ? \
             ORDER BY j.{name_col} COLLATE NOCASE"
        )
    }
}

/// Delete all junction rows for `comic_id`, upsert names into the dictionary, then re-attach.
pub async fn replace_comic_named_facet<C: ConnectionTrait>(
    db: &C,
    facet: JunctionNamedFacet,
    comic_id: &str,
    names: &[String],
) -> Result<(), HentaiError> {
    let junction = facet.junction_table();
    let name_col = facet.junction_name_column();
    let dict = facet.dict_table();

    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM {junction} WHERE comic_id = ?"),
        [Value::String(Some(Box::new(comic_id.to_string())))],
    ))
    .await
    .map_err(map_db_err)?;

    let unique: std::collections::HashSet<&String> = names.iter().collect();
    for name in unique {
        db.execute(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!("INSERT OR IGNORE INTO {dict} (name) VALUES (?)"),
            [Value::String(Some(Box::new(name.clone())))],
        ))
        .await
        .map_err(map_db_err)?;

        db.execute(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!("INSERT INTO {junction} (comic_id, {name_col}) VALUES (?, ?)"),
            [
                Value::String(Some(Box::new(comic_id.to_string()))),
                Value::String(Some(Box::new(name.clone()))),
            ],
        ))
        .await
        .map_err(map_db_err)?;
    }
    Ok(())
}

pub async fn list_all_named_facet_names(
    facet: JunctionNamedFacet,
) -> Result<Vec<String>, HentaiError> {
    let db = connection()?;
    let dict = facet.dict_table();
    let rows = db
        .query_all(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!("SELECT name FROM {dict} ORDER BY name ASC"),
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

pub async fn list_distinct_named_facet_names(
    facet: JunctionNamedFacet,
    library_id: Option<String>,
) -> Result<Vec<String>, HentaiError> {
    let Some(library_id) = crate::library::resolve_browse_library_id(library_id).await? else {
        return Ok(Vec::new());
    };
    let db = connection()?;
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            facet.distinct_attached_sql(),
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
    fn distinct_sql_scopes_library_for_each_facet() {
        for facet in [
            JunctionNamedFacet::Tag,
            JunctionNamedFacet::Author,
            JunctionNamedFacet::Parody,
            JunctionNamedFacet::Character,
        ] {
            let sql = facet.distinct_attached_sql();
            assert!(sql.contains(facet.junction_table()), "{facet:?}");
            assert!(sql.contains("c.library_id = ?"), "{facet:?}");
            assert!(sql.contains(facet.junction_name_column()), "{facet:?}");
        }
    }
}
