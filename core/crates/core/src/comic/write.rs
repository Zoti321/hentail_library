use std::path::Path;

use sea_orm::{ActiveModelTrait, ConnectionTrait, Set, Statement, TransactionTrait};

use crate::comic::dto::{now_ms, serialize_languages, ComicDto, PagedComicResultDto};
use crate::comic::repository::load_comics_ordered;
use crate::comic_id::normalize_path_for_key;
use crate::db::{connection, map_db_err};
use crate::entity::{comic_meta, comics};
use crate::error::HentaiError;
use crate::metadata_lock::ComicAutoLocks;
use crate::sync::series_rebuild::rebuild_series_from_comics;
use crate::sync::writer::delete_comics_side_effects;
use crate::sync::writer::{
    replace_comic_authors, replace_comic_characters, replace_comic_parodies, replace_comic_tags,
};
use crate::util::{compute_sort_key, decode_basic_html_entities};

#[derive(Debug, Clone, Default)]
pub struct UpdateComicUserMetaDto {
    pub title: Option<String>,
    pub content_rating: Option<String>,
    pub description: Option<String>,
    /// Milliseconds since epoch, or `-1` to clear stored value.
    pub published_at: Option<i64>,
    pub authors: Option<Vec<String>>,
    pub tags: Option<Vec<String>>,
    pub languages: Option<Vec<String>>,
    pub parodies: Option<Vec<String>>,
    pub characters: Option<Vec<String>>,
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
    pub languages: Option<bool>,
    pub parodies: Option<bool>,
    pub characters: Option<bool>,
}

struct ComicDeletionTarget {
    comic_id: String,
    path: String,
    resource_type: String,
    library_kind: String,
    library_root_path: String,
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
    let targets = load_deletion_targets(&db, &comic_ids).await?;
    for target in &targets {
        maybe_delete_local_resource(target)?;
    }
    let txn = db.begin().await.map_err(map_db_err)?;
    delete_comics_side_effects(&txn, &comic_ids).await?;
    rebuild_series_from_comics(&txn, None).await?;
    txn.commit().await.map_err(map_db_err)?;
    Ok(())
}

async fn load_deletion_targets<C: ConnectionTrait>(
    db: &C,
    comic_ids: &[String],
) -> Result<Vec<ComicDeletionTarget>, HentaiError> {
    if comic_ids.is_empty() {
        return Ok(Vec::new());
    }
    let placeholders = comic_ids.iter().map(|_| "?").collect::<Vec<_>>().join(",");
    let values: Vec<sea_orm::Value> = comic_ids
        .iter()
        .map(|id| sea_orm::Value::String(Some(Box::new(id.clone()))))
        .collect();
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "SELECT c.comic_id, c.path, c.resource_type, l.kind, l.root_path \
                 FROM comics c \
                 INNER JOIN libraries l ON l.library_id = c.library_id \
                 WHERE c.comic_id IN ({placeholders})"
            ),
            values,
        ))
        .await
        .map_err(map_db_err)?;
    rows.into_iter()
        .map(|row| {
            Ok(ComicDeletionTarget {
                comic_id: row
                    .try_get_by_index::<String>(0)
                    .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
                path: row
                    .try_get_by_index::<String>(1)
                    .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
                resource_type: row
                    .try_get_by_index::<String>(2)
                    .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
                library_kind: row
                    .try_get_by_index::<String>(3)
                    .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
                library_root_path: row
                    .try_get_by_index::<String>(4)
                    .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
            })
        })
        .collect()
}

fn maybe_delete_local_resource(target: &ComicDeletionTarget) -> Result<(), HentaiError> {
    if target.library_kind == "remote" {
        return Ok(());
    }
    ensure_local_resource_within_library_root(target)?;
    let path = Path::new(&target.path);
    if !path.exists() {
        return Ok(());
    }
    let delete_result = if target.resource_type == "dir" {
        std::fs::remove_dir_all(path)
    } else {
        std::fs::remove_file(path)
    };
    delete_result.map_err(|error| {
        HentaiError::validation(format!("无法删除磁盘资源，漫画仍保留在库中。{error}"))
    })?;
    Ok(())
}

fn ensure_local_resource_within_library_root(
    target: &ComicDeletionTarget,
) -> Result<(), HentaiError> {
    let normalized_root = normalize_path_for_key(&target.library_root_path);
    let normalized_path = normalize_path_for_key(&target.path);
    if normalized_root.is_empty() || normalized_path.is_empty() {
        return Err(HentaiError::validation(format!(
            "漫画资源路径异常，已取消删除：{}",
            target.comic_id
        )));
    }
    if normalized_path == normalized_root
        || !normalized_path.starts_with(&format!("{normalized_root}/"))
    {
        return Err(HentaiError::validation(
            "漫画资源不在所属 Library root 下，已取消删除。",
        ));
    }
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
        || meta.tags.is_some()
        || meta.languages.is_some()
        || meta.parodies.is_some()
        || meta.characters.is_some();
    let auto_locks = ComicAutoLocks {
        title: meta.title.is_some(),
        description: meta.description.is_some(),
        published_at: meta.published_at.is_some(),
        content_rating: meta.content_rating.is_some(),
        authors: meta.authors.is_some(),
        tags: meta.tags.is_some(),
        languages: meta.languages.is_some(),
        parodies: meta.parodies.is_some(),
        characters: meta.characters.is_some(),
    };
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
        if let Some(languages) = meta.languages {
            active.languages = Set(serialize_languages(&normalize_languages(languages)));
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
        if auto_locks.languages {
            active.languages_locked = Set(true);
        }
        if auto_locks.parodies {
            active.parodies_locked = Set(true);
            meta_touched = true;
        }
        if auto_locks.characters {
            active.characters_locked = Set(true);
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
    if let Some(parodies) = meta.parodies {
        replace_comic_parodies(&txn, comic_id, &parodies).await?;
        meta_touched = true;
    }
    if let Some(characters) = meta.characters {
        replace_comic_characters(&txn, comic_id, &characters).await?;
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
        && locks.languages.is_none()
        && locks.parodies.is_none()
        && locks.characters.is_none()
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
    if let Some(v) = locks.languages {
        active.languages_locked = Set(v);
    }
    if let Some(v) = locks.parodies {
        active.parodies_locked = Set(v);
    }
    if let Some(v) = locks.characters {
        active.characters_locked = Set(v);
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
    let mut values: Vec<sea_orm::Value> = vec![sea_orm::Value::String(Some(Box::new(library_id)))];
    super::filter_predicate::append_metadata_expression_predicates(
        &mut sql,
        &mut values,
        &includes,
        &optional,
        &excludes,
    );
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
    let page =
        search_by_tag_expression_page(must_include, optional_or, must_exclude, 1, i32::MAX).await?;
    Ok(page.items)
}

pub async fn search_by_tag_expression_page(
    must_include: Vec<String>,
    optional_or: Vec<String>,
    must_exclude: Vec<String>,
    page: i32,
    page_size: i32,
) -> Result<PagedComicResultDto, HentaiError> {
    let page = page.max(1);
    let page_size = page_size.max(1);
    let ids = search_comic_ids_by_tag_expression(must_include, optional_or, must_exclude).await?;
    let total_count = ids.len() as i64;
    if total_count == 0 {
        return Ok(PagedComicResultDto {
            items: vec![],
            total_count: 0,
            page,
            page_size,
        });
    }
    let start = ((page - 1) as i64 * page_size as i64).min(total_count) as usize;
    let end = (start as i64 + page_size as i64).min(total_count) as usize;
    let page_ids = ids[start..end].to_vec();
    let db = connection()?;
    let items = load_comics_ordered(&db, page_ids).await?;
    Ok(PagedComicResultDto {
        items,
        total_count,
        page,
        page_size,
    })
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

/// Trim empties; preserve order and first-seen duplicates removed.
fn normalize_languages(source: Vec<String>) -> Vec<String> {
    let mut out = Vec::new();
    for value in source {
        let trimmed = value.trim().to_string();
        if trimmed.is_empty() {
            continue;
        }
        if !out.iter().any(|existing: &String| existing == &trimmed) {
            out.push(trimmed);
        }
    }
    out
}
