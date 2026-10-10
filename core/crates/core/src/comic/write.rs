use sea_orm::{ActiveModelTrait, ConnectionTrait, Set, Statement, TransactionTrait};

use crate::comic::dto::{now_ms, serialize_languages, ComicDto, PagedComicResultDto};
use crate::comic::repository::load_comics_ordered;
use crate::db::{connection, map_db_err};
use crate::entity::{comic_meta, comics};
use crate::error::HentaiError;
use crate::metadata_lock::{
    normalize_names, normalize_tag_expression_tokens, ComicAutoLocks, ComicMetaField,
};
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

impl UpdateComicUserMetaDto {
    /// Whether this write sets `field`; a written field is auto-locked (ADR-0007).
    pub fn is_written(&self, field: ComicMetaField) -> bool {
        match field {
            ComicMetaField::Title => self.title.is_some(),
            ComicMetaField::Description => self.description.is_some(),
            ComicMetaField::PublishedAt => self.published_at.is_some(),
            ComicMetaField::ContentRating => self.content_rating.is_some(),
            ComicMetaField::Authors => self.authors.is_some(),
            ComicMetaField::Tags => self.tags.is_some(),
            ComicMetaField::Languages => self.languages.is_some(),
            ComicMetaField::Parodies => self.parodies.is_some(),
            ComicMetaField::Characters => self.characters.is_some(),
        }
    }
}

impl SetComicMetaLocksDto {
    pub fn any(&self) -> bool {
        ComicMetaField::ALL
            .iter()
            .any(|field| self.patch(*field).is_some())
    }

    /// `Some(locked)` when this patch sets `field`'s lock, `None` when it leaves it unchanged.
    pub fn patch(&self, field: ComicMetaField) -> Option<bool> {
        match field {
            ComicMetaField::Title => self.title,
            ComicMetaField::Description => self.description,
            ComicMetaField::PublishedAt => self.published_at,
            ComicMetaField::ContentRating => self.content_rating,
            ComicMetaField::Authors => self.authors,
            ComicMetaField::Tags => self.tags,
            ComicMetaField::Languages => self.languages,
            ComicMetaField::Parodies => self.parodies,
            ComicMetaField::Characters => self.characters,
        }
    }
}

/// Write one ADR-0007 lock column. Exhaustive over the field table: adding a field makes this
/// (and the DTO accessors above) fail to compile until the new lock column is wired.
fn apply_comic_lock(active: &mut comic_meta::ActiveModel, field: ComicMetaField, locked: bool) {
    match field {
        ComicMetaField::Title => active.title_locked = Set(locked),
        ComicMetaField::Description => active.description_locked = Set(locked),
        ComicMetaField::PublishedAt => active.published_at_locked = Set(locked),
        ComicMetaField::ContentRating => active.content_rating_locked = Set(locked),
        ComicMetaField::Authors => active.authors_locked = Set(locked),
        ComicMetaField::Tags => active.tags_locked = Set(locked),
        ComicMetaField::Languages => active.languages_locked = Set(locked),
        ComicMetaField::Parodies => active.parodies_locked = Set(locked),
        ComicMetaField::Characters => active.characters_locked = Set(locked),
    }
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

pub async fn update_comic_user_meta(
    comic_id: &str,
    meta: UpdateComicUserMetaDto,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let txn = db.begin().await.map_err(map_db_err)?;
    // A written field is auto-locked; the field table decides which fields and locks exist.
    let auto_locks = ComicAutoLocks::from_written(|field| meta.is_written(field));
    let mut meta_touched = false;
    if auto_locks.any() {
        let mut active = comic_meta::ActiveModel {
            comic_id: Set(comic_id.to_string()),
            ..Default::default()
        };
        if let Some(title) = meta.title {
            let decoded = decode_basic_html_entities(&title);
            active.title_sort_key = Set(compute_sort_key(&decoded));
            active.title = Set(decoded);
        }
        if let Some(content_rating) = meta.content_rating {
            active.content_rating = Set(content_rating);
        }
        if let Some(description) = meta.description {
            active.description = Set(if description.is_empty() {
                None
            } else {
                Some(description)
            });
        }
        if let Some(published_at) = meta.published_at {
            active.published_at = Set(if published_at < 0 {
                None
            } else {
                Some(published_at)
            });
        }
        if let Some(languages) = meta.languages {
            active.languages = Set(serialize_languages(&normalize_names(&languages)));
        }
        for field in auto_locks.written() {
            apply_comic_lock(&mut active, field, true);
        }
        active.update(&txn).await.map_err(map_db_err)?;
        meta_touched = true;
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
    if !locks.any() {
        return Ok(());
    }
    let db = connection()?;
    let txn = db.begin().await.map_err(map_db_err)?;
    let mut active = comic_meta::ActiveModel {
        comic_id: Set(comic_id.to_string()),
        ..Default::default()
    };
    for field in ComicMetaField::ALL {
        if let Some(locked) = locks.patch(field) {
            apply_comic_lock(&mut active, field, locked);
        }
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
    let includes = normalize_tag_expression_tokens(&must_include);
    let optional = normalize_tag_expression_tokens(&optional_or);
    let excludes = normalize_tag_expression_tokens(&must_exclude);
    if includes.is_empty() && optional.is_empty() && excludes.is_empty() {
        return Ok(vec![]);
    }
    let Some(library_id) = crate::library::resolve_browse_library_id(None).await? else {
        return Ok(vec![]);
    };
    let mut sql = format!(
        "SELECT c.comic_id FROM comics c INNER JOIN comic_meta m ON m.comic_id = c.comic_id \
         WHERE c.library_id = ? AND {}",
        super::visibility::visible_comic_sql("c")
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

#[cfg(test)]
mod tests {
    use super::*;

    /// A DTO that writes exactly `field`.
    fn dto_writing(field: ComicMetaField) -> UpdateComicUserMetaDto {
        let mut meta = UpdateComicUserMetaDto::default();
        match field {
            ComicMetaField::Title => meta.title = Some("title".to_string()),
            ComicMetaField::Description => meta.description = Some("description".to_string()),
            ComicMetaField::PublishedAt => meta.published_at = Some(0),
            ComicMetaField::ContentRating => meta.content_rating = Some("safe".to_string()),
            ComicMetaField::Authors => meta.authors = Some(vec!["author".to_string()]),
            ComicMetaField::Tags => meta.tags = Some(vec!["tag".to_string()]),
            ComicMetaField::Languages => meta.languages = Some(vec!["ja".to_string()]),
            ComicMetaField::Parodies => meta.parodies = Some(vec!["parody".to_string()]),
            ComicMetaField::Characters => meta.characters = Some(vec!["character".to_string()]),
        }
        meta
    }

    /// Every variant reports itself written; the field table (its `ALL` order and `from_written`
    /// round-trip) is covered by `metadata_lock::auto_lock`'s own tests.
    #[test]
    fn is_written_reports_exactly_the_written_field() {
        for field in ComicMetaField::ALL {
            let meta = dto_writing(field);
            assert!(meta.is_written(field), "{field:?} 应视为已写入");
        }
        let empty = UpdateComicUserMetaDto::default();
        assert!(!ComicMetaField::ALL
            .iter()
            .any(|field| empty.is_written(*field)));
    }

    #[test]
    fn lock_patch_reports_only_the_set_lock() {
        let empty = SetComicMetaLocksDto::default();
        assert!(!empty.any());
        assert!(ComicMetaField::ALL
            .iter()
            .all(|field| empty.patch(*field).is_none()));

        for field in ComicMetaField::ALL {
            let mut locks = SetComicMetaLocksDto::default();
            match field {
                ComicMetaField::Title => locks.title = Some(false),
                ComicMetaField::Description => locks.description = Some(false),
                ComicMetaField::PublishedAt => locks.published_at = Some(false),
                ComicMetaField::ContentRating => locks.content_rating = Some(false),
                ComicMetaField::Authors => locks.authors = Some(false),
                ComicMetaField::Tags => locks.tags = Some(false),
                ComicMetaField::Languages => locks.languages = Some(false),
                ComicMetaField::Parodies => locks.parodies = Some(false),
                ComicMetaField::Characters => locks.characters = Some(false),
            }
            assert!(locks.any());
            assert_eq!(locks.patch(field), Some(false));
            assert_eq!(
                ComicMetaField::ALL
                    .iter()
                    .filter(|candidate| locks.patch(**candidate).is_some())
                    .count(),
                1
            );
        }
    }
}
