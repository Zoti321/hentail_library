use std::collections::{HashMap, HashSet};

use crate::comic::dto::ComicDto;
use crate::comic::repository::find_comics_by_ids;
use crate::comic::write::{update_comic_user_meta, UpdateComicUserMetaDto};
use crate::error::HentaiError;
use crate::sync::handle::SyncHandle;
use crate::sync::library_lock::try_acquire_library_write_lock;

pub const BULK_PATCH_MAX_IDS: usize = 2000;
const MAX_ERROR_SAMPLES: usize = 5;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MultiValueOp {
    Add,
    Remove,
    Replace,
}

#[derive(Debug, Clone)]
pub struct MultiValuePatch {
    pub op: MultiValueOp,
    pub values: Vec<String>,
}

#[derive(Debug, Clone, Default)]
pub struct ComicMetadataBulkPatch {
    pub tags: Option<MultiValuePatch>,
    pub authors: Option<MultiValuePatch>,
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
        self.tags.is_some() || self.authors.is_some()
    }
}

fn merge_multi_value(current: &[String], patch: &MultiValuePatch) -> Vec<String> {
    match patch.op {
        MultiValueOp::Add => {
            let mut out = current.to_vec();
            for value in &patch.values {
                if !out.iter().any(|existing| existing == value) {
                    out.push(value.clone());
                }
            }
            out
        }
        MultiValueOp::Remove => current
            .iter()
            .filter(|value| !patch.values.iter().any(|remove| remove == *value))
            .cloned()
            .collect(),
        MultiValueOp::Replace => patch.values.clone(),
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

    let _guard = try_acquire_library_write_lock()?;

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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn merge_add_dedupes_preserving_order() {
        let current = vec!["a".to_string(), "b".to_string()];
        let patch = MultiValuePatch {
            op: MultiValueOp::Add,
            values: vec!["b".to_string(), "c".to_string()],
        };
        assert_eq!(
            merge_multi_value(&current, &patch),
            vec!["a", "b", "c"]
                .into_iter()
                .map(String::from)
                .collect::<Vec<_>>()
        );
    }

    #[test]
    fn merge_remove_is_noop_when_missing() {
        let current = vec!["a".to_string()];
        let patch = MultiValuePatch {
            op: MultiValueOp::Remove,
            values: vec!["z".to_string()],
        };
        assert_eq!(merge_multi_value(&current, &patch), current);
    }

    #[test]
    fn merge_replace_replaces_whole_list() {
        let current = vec!["a".to_string(), "b".to_string()];
        let patch = MultiValuePatch {
            op: MultiValueOp::Replace,
            values: vec!["x".to_string()],
        };
        assert_eq!(
            merge_multi_value(&current, &patch),
            vec!["x".to_string()]
        );
    }
}
