use sea_orm::{
    ActiveModelTrait, ColumnTrait, ConnectionTrait, EntityTrait, QueryFilter, Set, Statement,
    TransactionTrait,
};

use crate::comic::dto::{now_ms, ComicDto};
use crate::comic::repository::load_comics_ordered;
use crate::db::{connection, map_db_err};
use crate::entity::{comic_authors, comic_meta, comic_tags, comics, prelude::*};
use crate::error::HentaiError;
use crate::sync::series_rebuild::rebuild_series_from_comics;
use crate::sync::writer::{replace_comic_authors, replace_comic_tags};

#[derive(Debug, Clone, Default)]
pub struct UpdateComicUserMetaDto {
    pub title: Option<String>,
    pub content_rating: Option<String>,
    pub description: Option<String>,
    pub published_at: Option<i64>,
    pub authors: Option<Vec<String>>,
    pub tags: Option<Vec<String>>,
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
    rebuild_series_from_comics(&db).await?;
    Ok(())
}

pub async fn update_comic_user_meta(
    comic_id: &str,
    meta: UpdateComicUserMetaDto,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let txn = db.begin().await.map_err(map_db_err)?;
    let mut meta_touched = false;
    if meta.title.is_some()
        || meta.content_rating.is_some()
        || meta.description.is_some()
        || meta.published_at.is_some()
    {
        let mut active = comic_meta::ActiveModel {
            comic_id: Set(comic_id.to_string()),
            ..Default::default()
        };
        if let Some(title) = meta.title {
            active.title = Set(title);
            meta_touched = true;
        }
        if let Some(content_rating) = meta.content_rating {
            active.content_rating = Set(content_rating);
            meta_touched = true;
        }
        if let Some(description) = meta.description {
            active.description = Set(Some(description));
            meta_touched = true;
        }
        if let Some(published_at) = meta.published_at {
            active.published_at = Set(Some(published_at));
            meta_touched = true;
        }
        active.update(&txn).await.map_err(map_db_err)?;
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
    let mut sql = String::from(
        "SELECT c.comic_id FROM comics c INNER JOIN comic_meta m ON m.comic_id = c.comic_id WHERE 1=1",
    );
    let mut values: Vec<sea_orm::Value> = Vec::new();
    for tag in &includes {
        sql.push_str(
            " AND EXISTS (SELECT 1 FROM comic_tags ct WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) = ?)",
        );
        values.push(sea_orm::Value::String(Some(Box::new(tag.clone()))));
    }
    if !optional.is_empty() {
        let placeholders = optional.iter().map(|_| "?").collect::<Vec<_>>().join(",");
        sql.push_str(&format!(
            " AND EXISTS (SELECT 1 FROM comic_tags ct WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) IN ({placeholders}))"
        ));
        for tag in &optional {
            values.push(sea_orm::Value::String(Some(Box::new(tag.clone()))));
        }
    }
    if !excludes.is_empty() {
        let placeholders = excludes.iter().map(|_| "?").collect::<Vec<_>>().join(",");
        sql.push_str(&format!(
            " AND NOT EXISTS (SELECT 1 FROM comic_tags ct WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) IN ({placeholders}))"
        ));
        for tag in &excludes {
            values.push(sea_orm::Value::String(Some(Box::new(tag.clone()))));
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
