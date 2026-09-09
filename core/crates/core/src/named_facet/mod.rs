//! Junction-backed named metadata facets (Tag / Author / Parody / Character).
//!
//! Language is a closed-set JSON column on `comic_meta` and is not handled here.

use sea_orm::{ConnectionTrait, Statement, TransactionTrait, Value};

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

    /// Form picker candidates: name + global attachment count.
    ///
    /// Order: `attachment_count` DESC, then `name` ASC. Unused dictionary rows are 0.
    pub fn form_listing_sql(self) -> String {
        let dict = self.dict_table();
        let junction = self.junction_table();
        let name_col = self.junction_name_column();
        format!(
            "SELECT d.name AS name, COUNT(j.{name_col}) AS attachment_count \
             FROM {dict} d \
             LEFT JOIN {junction} j ON j.{name_col} = d.name \
             GROUP BY d.name \
             ORDER BY attachment_count DESC, d.name ASC"
        )
    }
}

/// Named metadata facet row for Comic metadata form MultiSelect candidates.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NamedFacetFormEntry {
    pub name: String,
    pub attachment_count: i64,
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

pub async fn count_all_named_facet_names(facet: JunctionNamedFacet) -> Result<i64, HentaiError> {
    let db = connection()?;
    let dict = facet.dict_table();
    let rows = db
        .query_all(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!("SELECT COUNT(*) FROM {dict}"),
        ))
        .await
        .map_err(map_db_err)?;
    rows.into_iter()
        .next()
        .ok_or_else(|| HentaiError::db_query_failed("count row missing".to_string(), None))
        .and_then(|row| {
            row.try_get_by_index::<i64>(0)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
        })
}

pub async fn fetch_named_facet_page(
    facet: JunctionNamedFacet,
    limit: i32,
    offset: i32,
) -> Result<Vec<String>, HentaiError> {
    let db = connection()?;
    let dict = facet.dict_table();
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!("SELECT name FROM {dict} ORDER BY name ASC LIMIT ? OFFSET ?"),
            [Value::Int(Some(limit)), Value::Int(Some(offset))],
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

pub async fn add_named_facet_name(
    facet: JunctionNamedFacet,
    name: &str,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let dict = facet.dict_table();
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("INSERT OR IGNORE INTO {dict} (name) VALUES (?)"),
        [Value::String(Some(Box::new(name.to_string())))],
    ))
    .await
    .map_err(map_db_err)?;
    Ok(())
}

pub async fn delete_named_facet_by_names(
    facet: JunctionNamedFacet,
    names: Vec<String>,
) -> Result<(), HentaiError> {
    if names.is_empty() {
        return Ok(());
    }
    let db = connection()?;
    let dict = facet.dict_table();
    let placeholders = std::iter::repeat("?")
        .take(names.len())
        .collect::<Vec<_>>()
        .join(", ");
    let values = names
        .into_iter()
        .map(|name| Value::String(Some(Box::new(name))))
        .collect::<Vec<_>>();
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM {dict} WHERE name IN ({placeholders})"),
        values,
    ))
    .await
    .map_err(map_db_err)?;
    Ok(())
}

pub async fn rename_named_facet_name(
    facet: JunctionNamedFacet,
    old_name: &str,
    new_name: &str,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let txn = db.begin().await.map_err(map_db_err)?;
    let dict = facet.dict_table();
    let junction = facet.junction_table();
    let name_col = facet.junction_name_column();

    txn.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("INSERT OR IGNORE INTO {dict} (name) VALUES (?)"),
        [Value::String(Some(Box::new(new_name.to_string())))],
    ))
    .await
    .map_err(map_db_err)?;

    txn.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("UPDATE {junction} SET {name_col} = ? WHERE {name_col} = ?"),
        [
            Value::String(Some(Box::new(new_name.to_string()))),
            Value::String(Some(Box::new(old_name.to_string()))),
        ],
    ))
    .await
    .map_err(map_db_err)?;

    txn.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM {dict} WHERE name = ?"),
        [Value::String(Some(Box::new(old_name.to_string())))],
    ))
    .await
    .map_err(map_db_err)?;

    txn.commit().await.map_err(map_db_err)?;
    Ok(())
}

/// Dictionary names with Named facet attachment count for Comic metadata form pickers.
///
/// Sorted by attachment count descending, then name ascending. Does not mutate
/// existing `list_all_named_facet_names` (name ASC) used by management UIs.
pub async fn list_named_facet_for_form(
    facet: JunctionNamedFacet,
) -> Result<Vec<NamedFacetFormEntry>, HentaiError> {
    let db = connection()?;
    let rows = db
        .query_all(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            facet.form_listing_sql(),
        ))
        .await
        .map_err(map_db_err)?;
    rows.into_iter()
        .map(|row| {
            let name = row
                .try_get_by_index::<String>(0)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
            let attachment_count = row
                .try_get_by_index::<i64>(1)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
            Ok(NamedFacetFormEntry {
                name,
                attachment_count,
            })
        })
        .collect()
}

pub async fn count_named_facet_attachments(
    facet: JunctionNamedFacet,
    name: &str,
) -> Result<i64, HentaiError> {
    let db = connection()?;
    let junction = facet.junction_table();
    let name_col = facet.junction_name_column();
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!("SELECT COUNT(*) FROM {junction} WHERE {name_col} = ?"),
            [Value::String(Some(Box::new(name.to_string())))],
        ))
        .await
        .map_err(map_db_err)?;
    rows.into_iter()
        .next()
        .ok_or_else(|| HentaiError::db_query_failed("count row missing".to_string(), None))
        .and_then(|row| {
            row.try_get_by_index::<i64>(0)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
        })
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

    #[test]
    fn form_listing_sql_counts_and_orders_for_each_facet() {
        for facet in [
            JunctionNamedFacet::Tag,
            JunctionNamedFacet::Author,
            JunctionNamedFacet::Parody,
            JunctionNamedFacet::Character,
        ] {
            let sql = facet.form_listing_sql();
            assert!(sql.contains(facet.dict_table()), "{facet:?}");
            assert!(sql.contains(facet.junction_table()), "{facet:?}");
            assert!(sql.contains("attachment_count DESC"), "{facet:?}");
            assert!(sql.contains("d.name ASC"), "{facet:?}");
        }
    }
}
