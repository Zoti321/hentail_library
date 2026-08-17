use sea_orm::{ActiveModelTrait, ConnectionTrait, Set, Statement, TransactionTrait};

use crate::comic::dto::{now_ms, ComicDto};
use crate::comic::repository::load_comics_ordered;
use crate::db::{connection, map_db_err};
use crate::entity::{comic_meta, comics};
use crate::error::HentaiError;
use crate::metadata_lock::comic_auto_locks;
use crate::sync::series_rebuild::rebuild_series_from_comics;
use crate::sync::writer::{replace_comic_authors, replace_comic_tags};
use crate::util::{decode_basic_html_entities, compute_sort_key};

#[derive(Debug, Clone, Default)]
pub struct UpdateComicUserMetaDto {
    pub title: Option<String>,
    pub content_rating: Option<String>,
    pub description: Option<String>,
    /// Milliseconds since epoch, or `-1` to clear stored value.
    pub published_at: Option<i64>,
    pub authors: Option<Vec<String>>,
    pub tags: Option<Vec<String>>,
}

/// Partial patch for Comic metadata field locks (`None` = leave unchanged).
#[derive(Debug, Clone, Default)]
pub struct SetComicMetaLocksDto {
    pub title: Option<bool>,
    pub description: Option<bool>,
    pub published_at: Option<bool>,
    pub content_rating: Option<bool>,
    pub authors: Option<bool>,
    pub tags: Option<bool>,
}

pub async fn touch_comic<C: ConnectionTrait>(db: &C, comic_id: &str) -> Result<(), HentaiError> {
    let active = comics::ActiveModel {
        comic_id: Set(comic_id.to_string()),
        last_updated_at: Set(now_ms()),
        ..Default::default()
    };
    active.update(db).await.map_err(map_db_err)?;
    Ok(())
}

pub async fn delete_comics_by_ids(comic_ids: Vec<String>) -> Result<(), HentaiError> {
    if comic_ids.is_empty() {
        return Ok(());
    }
    let db = connection()?;
    let placeholders = comic_ids
        .iter()
        .map(|_| "?")
        .collect::<Vec<_>>()
        .join(",");
    let values: Vec<sea_orm::Value> = comic_ids
        .iter()
        .map(|id| sea_orm::Value::String(Some(Box::new(id.clone()))))
        .collect();
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM comics WHERE comic_id IN ({placeholders})"),
        values,
    ))
    .await
    .map_err(map_db_err)?;
    rebuild_series_from_comics(&db, None).await?;
    Ok(())
}

pub async fn update_comic_user_meta(
    comic_id: &str,
    meta: UpdateComicUserMetaDto,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let txn = db.begin().await.map_err(map_db_err)?;
    let mut meta_touched = false;
    let touch_meta_row = meta.title.is_some()
        || meta.content_rating.is_some()
        || meta.description.is_some()
        || meta.published_at.is_some()
        || meta.authors.is_some()
        || meta.tags.is_some();
    let auto_locks = comic_auto_locks(
        meta.title.is_some(),
        meta.description.is_some(),
        meta.published_at.is_some(),
        meta.content_rating.is_some(),
        meta.authors.is_some(),
        meta.tags.is_some(),
    );
    if touch_meta_row {
        let mut active = comic_meta::ActiveModel {
            comic_id: Set(comic_id.to_string()),
            ..Default::default()
        };
        if let Some(title) = meta.title {
            let decoded = decode_basic_html_entities(&title);
            active.title_sort_key = Set(compute_sort_key(&decoded));
            active.title = Set(decoded);
            meta_touched = true;
        }
        if let Some(content_rating) = meta.content_rating {
            active.content_rating = Set(content_rating);
            meta_touched = true;
        }
        if let Some(description) = meta.description {
            active.description = Set(if description.is_empty() {
                None
            } else {
                Some(description)
            });
            meta_touched = true;
        }
        if let Some(published_at) = meta.published_at {
            active.published_at = Set(if published_at < 0 {
                None
            } else {
                Some(published_at)
            });
            meta_touched = true;
        }
        if auto_locks.title {
            active.title_locked = Set(true);
        }
        if auto_locks.description {
            active.description_locked = Set(true);
        }
        if auto_locks.published_at {
            active.published_at_locked = Set(true);
        }
        if auto_locks.content_rating {
            active.content_rating_locked = Set(true);
        }
        if auto_locks.authors {
            active.authors_locked = Set(true);
            meta_touched = true;
        }
        if auto_locks.tags {
            active.tags_locked = Set(true);
            meta_touched = true;
        }
        if meta_touched || auto_locks.any() {
            active.update(&txn).await.map_err(map_db_err)?;
            meta_touched = true;
        }
    }
    if let Some(authors) = meta.authors {
        replace_comic_authors(&txn, comic_id, &authors).await?;
        meta_touched = true;
    }
    if let Some(tags) = meta.tags {
        replace_comic_tags(&txn, comic_id, &tags).await?;
        meta_touched = true;
    }
    if meta_touched {
        touch_comic(&txn, comic_id).await?;
    }
    txn.commit().await.map_err(map_db_err)?;
    Ok(())
}

pub async fn set_comic_meta_locks(
    comic_id: &str,
    locks: SetComicMetaLocksDto,
) -> Result<(), HentaiError> {
    if locks.title.is_none()
        && locks.description.is_none()
        && locks.published_at.is_none()
        && locks.content_rating.is_none()
        && locks.authors.is_none()
        && locks.tags.is_none()
    {
        return Ok(());
    }
    let db = connection()?;
    let txn = db.begin().await.map_err(map_db_err)?;
    let mut active = comic_meta::ActiveModel {
        comic_id: Set(comic_id.to_string()),
        ..Default::default()
    };
    if let Some(v) = locks.title {
        active.title_locked = Set(v);
    }
    if let Some(v) = locks.description {
        active.description_locked = Set(v);
    }
    if let Some(v) = locks.published_at {
        active.published_at_locked = Set(v);
    }
    if let Some(v) = locks.content_rating {
        active.content_rating_locked = Set(v);
    }
    if let Some(v) = locks.authors {
        active.authors_locked = Set(v);
    }
    if let Some(v) = locks.tags {
        active.tags_locked = Set(v);
    }
    active.update(&txn).await.map_err(map_db_err)?;
    touch_comic(&txn, comic_id).await?;
    txn.commit().await.map_err(map_db_err)?;
    Ok(())
}

pub async fn search_comic_ids_by_tag_expression(
    must_include: Vec<String>,
    optional_or: Vec<String>,
    must_exclude: Vec<String>,
) -> Result<Vec<String>, HentaiError> {
    let includes = normalize_tag_set(must_include);
    let optional = normalize_tag_set(optional_or);
    let excludes = normalize_tag_set(must_exclude);
    if includes.is_empty() && optional.is_empty() && excludes.is_empty() {
        return Ok(vec![]);
    }
    let Some(library_id) = crate::library::resolve_browse_library_id(None).await? else {
        return Ok(vec![]);
    };
    let mut sql = String::from(
        "SELECT c.comic_id FROM comics c INNER JOIN comic_meta m ON m.comic_id = c.comic_id \
         WHERE c.library_id = ?",
    );
    let mut values: Vec<sea_orm::Value> =
        vec![sea_orm::Value::String(Some(Box::new(library_id)))];
    for name in &includes {
        sql.push_str(
            " AND (\
               EXISTS (SELECT 1 FROM comic_tags ct WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) = ?) \
               OR EXISTS (SELECT 1 FROM comic_authors ca WHERE ca.comic_id = c.comic_id AND lower(ca.author_name) = ?)\
             )",
        );
        values.push(sea_orm::Value::String(Some(Box::new(name.clone()))));
        values.push(sea_orm::Value::String(Some(Box::new(name.clone()))));
    }
    if !optional.is_empty() {
        let placeholders = optional.iter().map(|_| "?").collect::<Vec<_>>().join(",");
        sql.push_str(&format!(
            " AND (\
               EXISTS (SELECT 1 FROM comic_tags ct WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) IN ({placeholders})) \
               OR EXISTS (SELECT 1 FROM comic_authors ca WHERE ca.comic_id = c.comic_id AND lower(ca.author_name) IN ({placeholders}))\
             )"
        ));
        for name in &optional {
            values.push(sea_orm::Value::String(Some(Box::new(name.clone()))));
        }
        for name in &optional {
            values.push(sea_orm::Value::String(Some(Box::new(name.clone()))));
        }
    }
    if !excludes.is_empty() {
        let placeholders = excludes.iter().map(|_| "?").collect::<Vec<_>>().join(",");
        sql.push_str(&format!(
            " AND NOT EXISTS (SELECT 1 FROM comic_tags ct WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) IN ({placeholders})) \
              AND NOT EXISTS (SELECT 1 FROM comic_authors ca WHERE ca.comic_id = c.comic_id AND lower(ca.author_name) IN ({placeholders}))"
        ));
        for name in &excludes {
            values.push(sea_orm::Value::String(Some(Box::new(name.clone()))));
        }
        for name in &excludes {
            values.push(sea_orm::Value::String(Some(Box::new(name.clone()))));
        }
    }
    let db = connection()?;
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            sql,
            values,
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

pub async fn search_by_tag_expression(
    must_include: Vec<String>,
    optional_or: Vec<String>,
    must_exclude: Vec<String>,
) -> Result<Vec<ComicDto>, HentaiError> {
    let ids = search_comic_ids_by_tag_expression(must_include, optional_or, must_exclude).await?;
    let db = connection()?;
    load_comics_ordered(&db, ids).await
}

fn normalize_tag_set(source: Vec<String>) -> Vec<String> {
    let mut set = std::collections::BTreeSet::new();
    for value in source {
        let trimmed = value.trim().to_lowercase();
        if !trimmed.is_empty() {
            set.insert(trimmed);
        }
    }
    set.into_iter().collect()
}
