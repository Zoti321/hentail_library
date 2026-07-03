use std::collections::HashMap;
use std::path::{Path, PathBuf};

use rayon::prelude::*;

use crate::comic::ComicDto;
use crate::error::HentaiError;

use super::handle::SyncHandle;
use super::parser::{
    comic_id_for_path, parse_directory, parse_file, parsed_to_comic,
    read_source_stat,
};

pub struct ScanContext {
    pub existing_by_id: HashMap<String, ComicDto>,
    pub thumbnail_stats: HashMap<String, (i64, i64)>,
}

pub struct ScanItem {
    pub path: String,
    pub resource_type: String,
    pub comic: ComicDto,
}

pub fn scan_roots(
    roots: &[PathBuf],
    ctx: &ScanContext,
    handle: &SyncHandle,
) -> Result<Vec<ScanItem>, HentaiError> {
    let mut candidates: Vec<PathBuf> = Vec::new();
    for root in roots {
        if handle.is_cancelled() {
            return Ok(vec![]);
        }
        if !root.exists() {
            continue;
        }
        if root.is_dir() {
            collect_from_directory(root, &mut candidates, handle)?;
        } else if root.is_file() {
            candidates.push(root.clone());
        }
    }
    if handle.is_cancelled() {
        return Ok(vec![]);
    }
    let parsed: Vec<Result<Option<ScanItem>, HentaiError>> = candidates
        .par_iter()
        .map(|path| {
            if handle.is_cancelled() {
                Ok(None)
            } else {
                resolve_scan_item(path, ctx)
            }
        })
        .collect();
    let mut items = Vec::new();
    for result in parsed {
        if let Some(item) = result? {
            items.push(item);
        }
    }
    Ok(items)
}

fn collect_from_directory(
    dir: &Path,
    out: &mut Vec<PathBuf>,
    handle: &SyncHandle,
) -> Result<(), HentaiError> {
    if handle.is_cancelled() {
        return Ok(());
    }
    if let Some(parsed) = parse_directory(dir)? {
        out.push(PathBuf::from(parsed.path));
        return Ok(());
    }
    let entries = std::fs::read_dir(dir).map_err(|e| {
        HentaiError::validation(format!("目录扫描失败: {} ({})", dir.display(), e))
    })?;
    for entry in entries {
        if handle.is_cancelled() {
            return Ok(());
        }
        let entry = entry.map_err(|e| HentaiError::validation(e.to_string()))?;
        let path = entry.path();
        if path.is_dir() {
            collect_from_directory(&path, out, handle)?;
        } else if path.is_file() {
            out.push(path);
        }
    }
    Ok(())
}

fn resolve_scan_item(path: &Path, ctx: &ScanContext) -> Result<Option<ScanItem>, HentaiError> {
    let comic_id = comic_id_for_path(&path.to_string_lossy());
    if let Some(existing) = ctx.existing_by_id.get(&comic_id) {
        if try_reuse_existing(path, existing, ctx) {
            return Ok(Some(ScanItem {
                path: existing.path.clone(),
                resource_type: existing.resource_type.clone(),
                comic: existing.clone(),
            }));
        }
    }
    let parsed = if path.is_dir() {
        parse_directory(path)?
    } else {
        parse_file(path)?
    };
    let Some(parsed) = parsed else {
        return Ok(None);
    };
    let comic = parsed_to_comic(&parsed);
    Ok(Some(ScanItem {
        path: parsed.path,
        resource_type: parsed.resource_type,
        comic,
    }))
}

fn try_reuse_existing(path: &Path, existing: &ComicDto, ctx: &ScanContext) -> bool {
    if existing.path != path.to_string_lossy() {
        return false;
    }
    let Ok(Some((modified_ms, size))) = read_source_stat(path, &existing.resource_type) else {
        return false;
    };
    if let Some((cached_ms, cached_size)) = ctx.thumbnail_stats.get(&existing.comic_id) {
        return *cached_ms == modified_ms && *cached_size == size;
    }
    false
}
