use std::collections::{HashMap, HashSet};

use crate::comic::dto::ComicDto;
use crate::comic::repository::find_comics_by_ids;
use crate::comic::write::{update_comic_user_meta, UpdateComicUserMetaDto};
use crate::error::HentaiError;
use crate::library_write::with_library_write;
use crate::metadata_lock::merge_multi_value;
use crate::sync::handle::SyncHandle;

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
    comic: &ComicDto,
    patch: &ComicMetadataBulkPatch,
) -> Result<PatchOutcome, HentaiError> {
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
        let merged = merge_multi_value(&comic.authors, authors_patch);
        if merged != comic.authors {
            meta.authors = Some(merged);
            changed = true;
        }
    }
    if let Some(languages_patch) = &patch.languages {
        let merged = merge_multi_value(&comic.languages, languages_patch);
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
        return Ok(PatchOutcome::Unchanged);
    }
    update_comic_user_meta(&comic.comic_id, meta).await?;
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

    let comic_map: HashMap<String, ComicDto> = comics
        .into_iter()
        .map(|comic| (comic.comic_id.clone(), comic))
        .collect();
    let found_ids: HashSet<String> = comic_map.keys().cloned().collect();

    let mut result = BulkPatchResultDto::default();
    for comic_id in comic_ids {
        if handle.is_cancelled() {
            result.cancelled = true;
            break;
        }
        if !found_ids.contains(&comic_id) {
            result.failed += 1;
            push_error_sample(&mut result, format!("漫画不存在: {comic_id}"));
            continue;
        }
        let comic = comic_map.get(&comic_id).expect("validated above");
        match apply_patch_to_one(comic, &patch).await {
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
