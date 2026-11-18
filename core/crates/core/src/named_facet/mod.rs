//! Junction-backed named metadata dictionary facets (Tag / Parody / Character).
//!
//! Author is a stable-identity entity and lives in `crate::author`; Language is a
//! closed-set JSON column on `comic_meta`. Neither is handled here.

use sea_orm::{ConnectionTrait, Statement, TransactionTrait, Value};

use crate::comic::visibility::{visible_comic_id_sql, visible_comic_sql};
use crate::db::{connection, map_db_err};
use crate::error::HentaiError;
use crate::library_write::with_library_write;

/// Named metadata dictionary facet stored as a global dictionary table + comic junction.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum JunctionNamedFacet {
    Tag,
    Parody,
    Character,
}

/// Metadata management UI facet (authors + dictionary facets).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ManagementFacetKind {
    Author,
    Tag,
    Parody,
    Character,
}

impl ManagementFacetKind {
    pub fn junction(self) -> Option<JunctionNamedFacet> {
        match self {
            Self::Author => None,
            Self::Tag => Some(JunctionNamedFacet::Tag),
            Self::Parody => Some(JunctionNamedFacet::Parody),
            Self::Character => Some(JunctionNamedFacet::Character),
        }
    }
}

impl JunctionNamedFacet {
    pub fn dict_table(self) -> &'static str {
        match self {
            Self::Tag => "tags",
            Self::Parody => "parodies",
            Self::Character => "characters",
        }
    }

    pub fn junction_table(self) -> &'static str {
        match self {
            Self::Tag => "comic_tags",
            Self::Parody => "comic_parodies",
            Self::Character => "comic_characters",
        }
    }

    /// Image set bindings on the same dictionary (no Metadata field lock).
    pub fn image_set_junction_table(self) -> &'static str {
        match self {
            Self::Tag => "image_set_tags",
            Self::Parody => "image_set_parodies",
            Self::Character => "image_set_characters",
        }
    }

    /// `(junction, owner column)` for every owner bound to this dictionary; dictionary
    /// rename/merge must rewrite all of them before the old dictionary row cascades away.
    fn owner_junctions(self) -> [(&'static str, &'static str); 2] {
        [
            (self.junction_table(), "comic_id"),
            (self.image_set_junction_table(), "image_set_id"),
        ]
    }

    pub fn junction_name_column(self) -> &'static str {
        match self {
            Self::Tag => "tag_name",
            Self::Parody => "parody_name",
            Self::Character => "character_name",
        }
    }

    /// Library-scoped distinct attached names (ORDER BY name COLLATE NOCASE).
    pub fn distinct_attached_sql(self) -> String {
        let visible = visible_comic_sql("c");
        let junction = self.junction_table();
        let name_col = self.junction_name_column();
        format!(
            "SELECT DISTINCT j.{name_col} AS name \
             FROM {junction} j \
             INNER JOIN comics c ON c.comic_id = j.comic_id \
             WHERE c.library_id = ? AND {visible} \
             ORDER BY j.{name_col} COLLATE NOCASE"
        )
    }

    /// Form picker candidates: name + global attachment count.
    ///
    /// Order: `attachment_count` DESC, then `name` ASC. Unused dictionary rows are 0.
    pub fn form_listing_sql(self) -> String {
        let dict = self.dict_table();
        let junction = self.junction_table();
        let visible = visible_comic_id_sql("j.comic_id");
        let name_col = self.junction_name_column();
        format!(
            "SELECT d.name AS name, COUNT(j.{name_col}) AS attachment_count \
             FROM {dict} d \
             LEFT JOIN {junction} j ON j.{name_col} = d.name AND {visible} \
             GROUP BY d.name \
             ORDER BY attachment_count DESC, d.name ASC"
        )
    }

    /// Management page candidates: name + global attachment count.
    ///
    /// Order: `name` ASC (matches legacy management paging). Unused dictionary rows are 0.
    pub fn management_page_sql(self) -> String {
        let dict = self.dict_table();
        let junction = self.junction_table();
        let visible = visible_comic_id_sql("j.comic_id");
        let name_col = self.junction_name_column();
        format!(
            "SELECT d.name AS name, COUNT(j.{name_col}) AS attachment_count \
             FROM {dict} d \
             LEFT JOIN {junction} j ON j.{name_col} = d.name AND {visible} \
             GROUP BY d.name \
             ORDER BY d.name ASC \
             LIMIT ? OFFSET ?"
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
    replace_owner_named_facet(
        db,
        facet,
        facet.junction_table(),
        "comic_id",
        comic_id,
        names,
    )
    .await
}

/// Replace-all Image set bindings for one dictionary facet; same name rules as Comic.
pub async fn replace_image_set_named_facet<C: ConnectionTrait>(
    db: &C,
    facet: JunctionNamedFacet,
    image_set_id: &str,
    names: &[String],
) -> Result<(), HentaiError> {
    replace_owner_named_facet(
        db,
        facet,
        facet.image_set_junction_table(),
        "image_set_id",
        image_set_id,
        names,
    )
    .await
}

/// Names of one dictionary facet bound to one Image set (name ASC).
pub async fn load_image_set_named_facet<C: ConnectionTrait>(
    db: &C,
    facet: JunctionNamedFacet,
    image_set_id: &str,
) -> Result<Vec<String>, HentaiError> {
    let junction = facet.image_set_junction_table();
    let name_col = facet.junction_name_column();
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "SELECT {name_col} FROM {junction} WHERE image_set_id = ? ORDER BY {name_col} ASC"
            ),
            [Value::String(Some(Box::new(image_set_id.to_string())))],
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

async fn replace_owner_named_facet<C: ConnectionTrait>(
    db: &C,
    facet: JunctionNamedFacet,
    junction: &str,
    owner_col: &str,
    owner_id: &str,
    names: &[String],
) -> Result<(), HentaiError> {
    let name_col = facet.junction_name_column();
    let dict = facet.dict_table();

    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM {junction} WHERE {owner_col} = ?"),
        [Value::String(Some(Box::new(owner_id.to_string())))],
    ))
    .await
    .map_err(map_db_err)?;

    // Trimmed, empty-free, first-seen order — dictionary and junction rows agree.
    let names = crate::metadata_lock::normalize_names(names);
    for name in &names {
        db.execute(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!("INSERT OR IGNORE INTO {dict} (name) VALUES (?)"),
            [Value::String(Some(Box::new(name.clone())))],
        ))
        .await
        .map_err(map_db_err)?;

        db.execute(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!("INSERT INTO {junction} ({owner_col}, {name_col}) VALUES (?, ?)"),
            [
                Value::String(Some(Box::new(owner_id.to_string()))),
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
) -> Result<Vec<NamedFacetFormEntry>, HentaiError> {
    let db = connection()?;
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            facet.management_page_sql(),
            [Value::Int(Some(limit)), Value::Int(Some(offset))],
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

/// Paged management name list (dictionary facets include attachment counts;
/// Author rows use `attachment_count = 0`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PagedStringNamesDto {
    pub items: Vec<NamedFacetFormEntry>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

pub async fn fetch_named_facet_names_page(
    facet: JunctionNamedFacet,
    request: crate::comic::PageRequestDto,
) -> Result<PagedStringNamesDto, HentaiError> {
    use crate::comic::pagination::paginate;

    let total = count_all_named_facet_names(facet).await?;
    let window = paginate(request, total).clamped();
    if total <= 0 {
        return Ok(PagedStringNamesDto {
            items: vec![],
            total_count: 0,
            page: 1,
            page_size: window.page_size,
        });
    }
    let items = fetch_named_facet_page(facet, window.page_size, window.offset as i32).await?;
    Ok(PagedStringNamesDto {
        items,
        total_count: total,
        page: window.page,
        page_size: window.page_size,
    })
}

/// Paged management-tab names (Author display names or dictionary facet names).
pub async fn fetch_management_facet_names_page(
    facet: ManagementFacetKind,
    request: crate::comic::PageRequestDto,
) -> Result<PagedStringNamesDto, HentaiError> {
    match facet {
        ManagementFacetKind::Author => {
            let page = crate::author::fetch_author_names_page_result(request).await?;
            Ok(PagedStringNamesDto {
                items: page
                    .items
                    .into_iter()
                    .map(|name| NamedFacetFormEntry {
                        name,
                        attachment_count: 0,
                    })
                    .collect(),
                total_count: page.total_count,
                page: page.page,
                page_size: page.page_size,
            })
        }
        ManagementFacetKind::Tag | ManagementFacetKind::Parody | ManagementFacetKind::Character => {
            fetch_named_facet_names_page(facet.junction().expect("dictionary facet"), request).await
        }
    }
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
    crate::revision::notify_committed();
    Ok(())
}

pub async fn delete_named_facet_by_names(
    facet: JunctionNamedFacet,
    names: Vec<String>,
) -> Result<(), HentaiError> {
    if names.is_empty() {
        return Ok(());
    }
    with_library_write(|| delete_named_facet_by_names_locked(facet, names)).await
}

async fn delete_named_facet_by_names_locked(
    facet: JunctionNamedFacet,
    names: Vec<String>,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let txn = db.begin().await.map_err(map_db_err)?;
    let dict = facet.dict_table();
    let placeholders = std::iter::repeat_n("?", names.len())
        .collect::<Vec<_>>()
        .join(", ");
    let values = names
        .into_iter()
        .map(|name| Value::String(Some(Box::new(name))))
        .collect::<Vec<_>>();
    let captured = capture_facet_writeback(&txn, facet, &placeholders, values.clone()).await?;
    txn.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM {dict} WHERE name IN ({placeholders})"),
        values,
    ))
    .await
    .map_err(map_db_err)?;
    crate::resource_metadata::record_affected_in(&txn, captured).await?;
    txn.commit().await.map_err(map_db_err)?;
    crate::revision::notify_committed();
    Ok(())
}

pub async fn rename_named_facet_name(
    facet: JunctionNamedFacet,
    old_name: &str,
    new_name: &str,
) -> Result<(), HentaiError> {
    with_library_write(|| rename_named_facet_name_locked(facet, old_name, new_name)).await
}

async fn rename_named_facet_name_locked(
    facet: JunctionNamedFacet,
    old_name: &str,
    new_name: &str,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let txn = db.begin().await.map_err(map_db_err)?;
    let dict = facet.dict_table();
    let name_col = facet.junction_name_column();
    let captured = capture_facet_writeback(&txn, facet, "?", vec![old_name.into()]).await?;

    txn.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("INSERT OR IGNORE INTO {dict} (name) VALUES (?)"),
        [Value::String(Some(Box::new(new_name.to_string())))],
    ))
    .await
    .map_err(map_db_err)?;

    for (junction, _) in facet.owner_junctions() {
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
    }

    txn.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM {dict} WHERE name = ?"),
        [Value::String(Some(Box::new(old_name.to_string())))],
    ))
    .await
    .map_err(map_db_err)?;

    crate::resource_metadata::record_affected_in(&txn, captured).await?;
    txn.commit().await.map_err(map_db_err)?;
    crate::revision::notify_committed();
    Ok(())
}

/// Merge one dictionary Named facet name into another in a single transaction.
pub async fn merge_named_facet_name(
    facet: JunctionNamedFacet,
    source_name: &str,
    target_name: &str,
) -> Result<(), HentaiError> {
    with_library_write(|| merge_named_facet_name_locked(facet, source_name, target_name)).await
}

async fn merge_named_facet_name_locked(
    facet: JunctionNamedFacet,
    source_name: &str,
    target_name: &str,
) -> Result<(), HentaiError> {
    let source = source_name.trim();
    let target = target_name.trim();
    if source.is_empty() || target.is_empty() {
        return Err(HentaiError::validation("合并名称不能为空"));
    }
    if source == target {
        return Err(HentaiError::validation("合并源与目标不能相同"));
    }

    let db = connection()?;
    let txn = db.begin().await.map_err(map_db_err)?;
    let dict = facet.dict_table();
    let name_col = facet.junction_name_column();
    let captured = capture_facet_writeback(&txn, facet, "?", vec![source.into()]).await?;

    for (name, label) in [(source, "源名称"), (target, "目标名称")] {
        let rows = txn
            .query_all(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                format!("SELECT 1 FROM {dict} WHERE name = ? LIMIT 1"),
                [Value::String(Some(Box::new(name.to_string())))],
            ))
            .await
            .map_err(map_db_err)?;
        if rows.is_empty() {
            return Err(HentaiError::validation(format!("{label}不存在: {name}")));
        }
    }

    for (junction, owner_col) in facet.owner_junctions() {
        txn.execute(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "INSERT OR IGNORE INTO {junction} ({owner_col}, {name_col}) \
                 SELECT {owner_col}, ? FROM {junction} WHERE {name_col} = ?"
            ),
            [
                Value::String(Some(Box::new(target.to_string()))),
                Value::String(Some(Box::new(source.to_string()))),
            ],
        ))
        .await
        .map_err(map_db_err)?;
        txn.execute(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!("DELETE FROM {junction} WHERE {name_col} = ?"),
            [Value::String(Some(Box::new(source.to_string())))],
        ))
        .await
        .map_err(map_db_err)?;
    }
    txn.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM {dict} WHERE name = ?"),
        [Value::String(Some(Box::new(source.to_string())))],
    ))
    .await
    .map_err(map_db_err)?;
    crate::resource_metadata::record_affected_in(&txn, captured).await?;
    txn.commit().await.map_err(map_db_err)?;
    crate::revision::notify_committed();
    Ok(())
}

/// Dictionary names with Named facet attachment count for Comic metadata form pickers.
async fn capture_facet_writeback(
    db: &impl ConnectionTrait,
    facet: JunctionNamedFacet,
    placeholders: &str,
    values: Vec<Value>,
) -> Result<Vec<(String, crate::resource_metadata::MetadataSnapshot)>, HentaiError> {
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "SELECT DISTINCT comic_id FROM {} WHERE {} IN ({placeholders})",
                facet.junction_table(),
                facet.junction_name_column()
            ),
            values,
        ))
        .await
        .map_err(map_db_err)?;
    let ids = rows
        .into_iter()
        .map(|row| row.try_get("", "comic_id").map_err(map_db_err))
        .collect::<Result<Vec<String>, _>>()?;
    crate::resource_metadata::capture_affected_in(db, ids).await
}

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
            format!(
                "SELECT COUNT(*) FROM {junction} j WHERE j.{name_col} = ? AND {}",
                visible_comic_id_sql("j.comic_id")
            ),
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

/// Batch attachment counts for the given dictionary names (missing names → 0).
pub async fn count_named_facet_attachments_batch(
    facet: JunctionNamedFacet,
    names: &[String],
) -> Result<Vec<NamedFacetFormEntry>, HentaiError> {
    if names.is_empty() {
        return Ok(vec![]);
    }

    let db = connection()?;
    let junction = facet.junction_table();
    let name_col = facet.junction_name_column();
    let placeholders = std::iter::repeat_n("?", names.len())
        .collect::<Vec<_>>()
        .join(", ");
    let sql = format!(
        "SELECT j.{name_col} AS name, COUNT(*) AS attachment_count \
         FROM {junction} j \
         WHERE j.{name_col} IN ({placeholders}) AND {} \
         GROUP BY j.{name_col}",
        visible_comic_id_sql("j.comic_id")
    );
    let values: Vec<Value> = names
        .iter()
        .map(|name| Value::String(Some(Box::new(name.clone()))))
        .collect();
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            sql,
            values,
        ))
        .await
        .map_err(map_db_err)?;

    let mut counted = std::collections::HashMap::<String, i64>::with_capacity(rows.len());
    for row in rows {
        let name = row
            .try_get_by_index::<String>(0)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
        let attachment_count = row
            .try_get_by_index::<i64>(1)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
        counted.insert(name, attachment_count);
    }

    Ok(names
        .iter()
        .map(|name| NamedFacetFormEntry {
            name: name.clone(),
            attachment_count: counted.get(name).copied().unwrap_or(0),
        })
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn distinct_sql_scopes_library_for_each_facet() {
        for facet in [
            JunctionNamedFacet::Tag,
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

    #[test]
    fn management_page_sql_counts_and_orders_name_asc() {
        for facet in [
            JunctionNamedFacet::Tag,
            JunctionNamedFacet::Parody,
            JunctionNamedFacet::Character,
        ] {
            let sql = facet.management_page_sql();
            assert!(sql.contains(facet.dict_table()), "{facet:?}");
            assert!(sql.contains(facet.junction_table()), "{facet:?}");
            assert!(sql.contains("ORDER BY d.name ASC"), "{facet:?}");
            assert!(sql.contains("LIMIT ? OFFSET ?"), "{facet:?}");
            assert!(!sql.contains("attachment_count DESC"), "{facet:?}");
        }
    }
}
