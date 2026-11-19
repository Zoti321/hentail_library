use std::collections::HashSet;

use crate::comic::repository::{find_comics_by_ids, find_visible_comic_by_id_in};
use crate::comic::write::{update_comic_user_meta_in, UpdateComicUserMetaDto};
use crate::db::{connection, map_db_err};
use crate::error::HentaiError;
use crate::library_write::with_library_write;
use crate::metadata_lock::merge_multi_value;
use crate::sync::handle::SyncHandle;
use sea_orm::TransactionTrait;

pub const BULK_PATCH_MAX_IDS: usize = 2000;
const MAX_ERROR_SAMPLES: usize = 5;

// Re-exported so `crate::comic::bulk_patch::*` and the FRB export surface keep these paths;
// the implementation lives in `metadata_lock::multi_value` (ADR-0007).
pub use crate::metadata_lock::{MultiValueOp, MultiValuePatch};

#[derive(Debug, Clone)]
pub enum ScalarPatch {
    Replace(String),
    Clear,
}

#[derive(Debug, Clone)]
pub enum PublishedAtPatch {
    Replace(i64),
    Clear,
}

#[derive(Debug, Clone, Default)]
pub struct ComicMetadataBulkPatch {
    pub tags: Option<MultiValuePatch>,
    pub authors: Option<MultiValuePatch>,
    pub languages: Option<MultiValuePatch>,
    pub parodies: Option<MultiValuePatch>,
    pub characters: Option<MultiValuePatch>,
    pub content_rating: Option<String>,
    pub description: Option<ScalarPatch>,
    pub published_at: Option<PublishedAtPatch>,
}

#[derive(Debug, Clone, Default)]
pub struct BulkPatchResultDto {
    pub succeeded: i32,
    pub failed: i32,
    pub unchanged: i32,
    pub cancelled: bool,
    pub error_samples: Vec<String>,
}

enum PatchOutcome {
    Succeeded,
    Unchanged,
}

impl ComicMetadataBulkPatch {
    fn has_fields(&self) -> bool {
        self.tags.is_some()
            || self.authors.is_some()
            || self.languages.is_some()
            || self.parodies.is_some()
            || self.characters.is_some()
            || self.content_rating.is_some()
            || self.description.is_some()
            || self.published_at.is_some()
    }
}

fn push_error_sample(result: &mut BulkPatchResultDto, message: String) {
    if result.error_samples.len() < MAX_ERROR_SAMPLES {
        result.error_samples.push(message);
    }
}

async fn apply_patch_to_one(
    comic_id: &str,
    library_id: &str,
    patch: &ComicMetadataBulkPatch,
) -> Result<PatchOutcome, HentaiError> {
    let db = connection()?;
    let txn = db.begin().await.map_err(|e| map_db_err(&e))?;
    let comic = find_visible_comic_by_id_in(&txn, comic_id)
        .await?
        .filter(|comic| comic.library_id == library_id)
        .ok_or_else(|| HentaiError::validation(format!("Comic unavailable: {comic_id}")))?;
    let mut meta = UpdateComicUserMetaDto::default();
    let mut changed = false;

    if let Some(tags_patch) = &patch.tags {
        let merged = merge_multi_value(&comic.tags, tags_patch);
        if merged != comic.tags {
            meta.tags = Some(merged);
            changed = true;
        }
    }
    if let Some(authors_patch) = &patch.authors {
        let author_names = comic.author_names();
        let merged = merge_multi_value(&author_names, authors_patch);
        if merged != author_names {
            meta.authors = Some(merged);
            changed = true;
        }
    }
    if let Some(languages_patch) = &patch.languages {
        let merged = crate::comic::dto::single_language(&languages_patch.values);
        if merged != comic.languages {
            meta.languages = Some(merged);
            changed = true;
        }
    }
    if let Some(parodies_patch) = &patch.parodies {
        let merged = merge_multi_value(&comic.parodies, parodies_patch);
        if merged != comic.parodies {
            meta.parodies = Some(merged);
            changed = true;
        }
    }
    if let Some(characters_patch) = &patch.characters {
        let merged = merge_multi_value(&comic.characters, characters_patch);
        if merged != comic.characters {
            meta.characters = Some(merged);
            changed = true;
        }
    }
    if let Some(rating) = &patch.content_rating {
        if rating != &comic.content_rating {
            meta.content_rating = Some(rating.clone());
            changed = true;
        }
    }
    if let Some(desc_patch) = &patch.description {
        let target = match desc_patch {
            ScalarPatch::Replace(value) => value.clone(),
            ScalarPatch::Clear => String::new(),
        };
        let current = comic.description.clone().unwrap_or_default();
        if current != target {
            meta.description = Some(target);
            changed = true;
        }
    }
    if let Some(pub_patch) = &patch.published_at {
        let target = match pub_patch {
            PublishedAtPatch::Replace(value) => Some(*value),
            PublishedAtPatch::Clear => None,
        };
        if comic.published_at != target {
            meta.published_at = Some(match pub_patch {
                PublishedAtPatch::Replace(value) => *value,
                PublishedAtPatch::Clear => -1,
            });
            changed = true;
        }
    }

    if !changed {
        txn.commit().await.map_err(|e| map_db_err(&e))?;
        return Ok(PatchOutcome::Unchanged);
    }
    update_comic_user_meta_in(&txn, &comic.comic_id, meta).await?;
    txn.commit().await.map_err(|e| map_db_err(&e))?;
    crate::revision::notify_committed();
    Ok(PatchOutcome::Succeeded)
}

/// Apply sparse metadata patch to many Comics in one Library.
///
/// Acquires library write lock for the whole batch; each Comic uses its own transaction.
pub async fn apply_comic_metadata_bulk_patch(
    comic_ids: Vec<String>,
    patch: ComicMetadataBulkPatch,
    handle: &SyncHandle,
) -> Result<BulkPatchResultDto, HentaiError> {
    if comic_ids.is_empty() {
        return Ok(BulkPatchResultDto::default());
    }
    if comic_ids.len() > BULK_PATCH_MAX_IDS {
        return Err(HentaiError::validation(format!(
            "批量编辑超出上限 {BULK_PATCH_MAX_IDS}"
        )));
    }
    if !patch.has_fields() {
        return Err(HentaiError::validation("批量 patch 未包含任何字段"));
    }
    if let Some(language) = &patch.languages {
        if !matches!(language.op, MultiValueOp::Replace) || language.values.len() > 1 {
            return Err(HentaiError::validation(
                "Language bulk editing only supports replacing one value or clearing it",
            ));
        }
    }
    if let Some(rating) = &patch.content_rating {
        if rating != "safe" && rating != "r18" {
            return Err(HentaiError::validation(
                "content_rating 批量编辑仅支持 safe / r18",
            ));
        }
    }

    with_library_write(|| apply_comic_metadata_bulk_patch_locked(comic_ids, patch, handle)).await
}

async fn apply_comic_metadata_bulk_patch_locked(
    comic_ids: Vec<String>,
    patch: ComicMetadataBulkPatch,
    handle: &SyncHandle,
) -> Result<BulkPatchResultDto, HentaiError> {
    let comics = find_comics_by_ids(comic_ids.clone()).await?;
    let library_ids: HashSet<String> = comics.iter().map(|c| c.library_id.clone()).collect();
    if library_ids.len() > 1 {
        return Err(HentaiError::validation("批量编辑不可跨 Library"));
    }

    let library_id = library_ids.into_iter().next().unwrap_or_default();
    let mut seen = HashSet::new();

    let mut result = BulkPatchResultDto::default();
    for comic_id in comic_ids {
        if handle.is_cancelled() {
            result.cancelled = true;
            break;
        }
        if !seen.insert(comic_id.clone()) {
            continue;
        }
        match apply_patch_to_one(&comic_id, &library_id, &patch).await {
            Ok(PatchOutcome::Succeeded) => result.succeeded += 1,
            Ok(PatchOutcome::Unchanged) => result.unchanged += 1,
            Err(err) => {
                result.failed += 1;
                push_error_sample(&mut result, format!("{comic_id}: {err}"));
            }
        }
    }

    Ok(result)
}
