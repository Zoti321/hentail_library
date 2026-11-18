use std::collections::HashMap;
use std::path::Path;

use crate::error::HentaiError;
use crate::resource::{
    extension_lower, is_comic_image_extension, local_access, ResourceAccess, ResourceEntry,
    ResourceKind,
};
use crate::sync::SyncHandle;

use super::archive_list::list_archive_image_members;
use super::dto::CarrierKind;

/// Prior `(size, modified_ms)` per archive carrier path; equal stat skips re-listing.
pub(crate) type PriorCarrierStats = HashMap<String, (i64, i64)>;

pub(crate) enum Listing {
    Listed {
        stat: (i64, i64),
        members: Vec<String>,
    },
    Unchanged,
    Unlistable,
}

pub(crate) struct CarrierObs {
    pub relative_path: String,
    pub kind: CarrierKind,
    pub listing: Listing,
}

/// One first-level Image set (directory or root-level archive). `complete` is false when any
/// directory under a folder set failed to list.
pub(crate) struct SetObs {
    pub relative_path: String,
    pub complete: bool,
    pub loose: Vec<String>,
    pub carriers: Vec<CarrierObs>,
}

impl SetObs {
    fn new(relative_path: &str) -> Self {
        Self {
            relative_path: relative_path.to_string(),
            complete: true,
            loose: Vec::new(),
            carriers: Vec::new(),
        }
    }
}

pub(crate) struct LibraryObs {
    pub sets: Vec<SetObs>,
    pub warnings: Vec<String>,
}

/// `None` when the sync was cancelled mid-walk; the caller must not write.
pub(crate) fn observe_library(
    root: &str,
    prior: &PriorCarrierStats,
    handle: &SyncHandle,
) -> Result<Option<LibraryObs>, HentaiError> {
    let entries = local_access().list(root)?;
    let mut obs = LibraryObs {
        sets: Vec::new(),
        warnings: Vec::new(),
    };
    for entry in &entries {
        if handle.is_cancelled() {
            return Ok(None);
        }
        match entry.kind {
            ResourceKind::Dir => {
                let mut set = SetObs::new(&entry.name);
                walk(
                    &entry.location,
                    &entry.name,
                    &mut set,
                    prior,
                    handle,
                    &mut obs.warnings,
                );
                obs.sets.push(set);
            }
            ResourceKind::File => {
                // Library-root loose images are out of catalog. First-level archives are Image sets.
                let path = Path::new(&entry.location);
                if is_comic_image_extension(&extension_lower(path)) {
                    continue;
                }
                let Some(kind) = CarrierKind::archive_for_path(path) else {
                    continue;
                };
                let mut set = SetObs::new(&entry.name);
                push_archive_carrier(entry, &entry.name, kind, &mut set, prior, &mut obs.warnings);
                obs.sets.push(set);
            }
        }
    }
    Ok((!handle.is_cancelled()).then_some(obs))
}

fn walk(
    location: &str,
    relative_path: &str,
    set: &mut SetObs,
    prior: &PriorCarrierStats,
    handle: &SyncHandle,
    warnings: &mut Vec<String>,
) {
    let entries = match local_access().list(location) {
        Ok(entries) => entries,
        Err(err) => {
            set.complete = false;
            warnings.push(format!(
                "图集目录无法完整枚举，保留已有图片: {relative_path}: {}",
                err.message
            ));
            return;
        }
    };
    for entry in &entries {
        if handle.is_cancelled() {
            return;
        }
        let child = format!("{relative_path}/{}", entry.name);
        match entry.kind {
            ResourceKind::Dir => walk(&entry.location, &child, set, prior, handle, warnings),
            ResourceKind::File => classify_file(entry, &child, set, prior, warnings),
        }
    }
}

fn classify_file(
    entry: &ResourceEntry,
    relative_path: &str,
    set: &mut SetObs,
    prior: &PriorCarrierStats,
    warnings: &mut Vec<String>,
) {
    let path = Path::new(&entry.location);
    if is_comic_image_extension(&extension_lower(path)) {
        set.loose.push(relative_path.to_string());
        return;
    }
    let Some(kind) = CarrierKind::archive_for_path(path) else {
        return;
    };
    push_archive_carrier(entry, relative_path, kind, set, prior, warnings);
}

fn push_archive_carrier(
    entry: &ResourceEntry,
    relative_path: &str,
    kind: CarrierKind,
    set: &mut SetObs,
    prior: &PriorCarrierStats,
    warnings: &mut Vec<String>,
) {
    let listing = match observe_listing(&entry.location, relative_path, kind, prior) {
        Ok(listing) => listing,
        Err(err) => {
            warnings.push(format!(
                "图集压缩包无法列出，保留已有图片: {relative_path}: {}",
                err.message
            ));
            Listing::Unlistable
        }
    };
    set.carriers.push(CarrierObs {
        relative_path: relative_path.to_string(),
        kind,
        listing,
    });
}

fn observe_listing(
    location: &str,
    relative_path: &str,
    kind: CarrierKind,
    prior: &PriorCarrierStats,
) -> Result<Listing, HentaiError> {
    let stat = local_access()
        .stat(location)?
        .filter(|stat| stat.kind == ResourceKind::File)
        .ok_or_else(|| HentaiError::validation("压缩包不存在或不是文件"))?;
    let key = (stat.size as i64, stat.modified_ms);
    if prior.get(relative_path) == Some(&key) {
        return Ok(Listing::Unchanged);
    }
    let members = list_archive_image_members(Path::new(location), kind)?;
    Ok(Listing::Listed { stat: key, members })
}
