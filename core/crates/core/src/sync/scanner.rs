use std::collections::HashMap;
use std::path::{Path, PathBuf};

use rayon::prelude::*;

use crate::comic::ComicDto;
use crate::error::HentaiError;

use super::handle::SyncHandle;
use super::parser::{
    comic_id_for_path, parse_directory, parse_file, parsed_to_comic, read_resource_size,
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
            let mut comic = existing.clone();
            refresh_resource_size(path, &mut comic)?;
            return Ok(Some(ScanItem {
                path: existing.path.clone(),
                resource_type: existing.resource_type.clone(),
                comic,
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

fn refresh_resource_size(path: &Path, comic: &mut ComicDto) -> Result<(), HentaiError> {
    if let Some(size) = read_resource_size(path, &comic.resource_type)? {
        comic.resource_size = size;
    }
    Ok(())
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::comic::ComicDto;
    use crate::sync::handle::create_sync_handle;
    use std::collections::HashMap;
    use std::fs::File;
    use std::io::Write;
    use tempfile::TempDir;
    use zip::write::SimpleFileOptions;
    use zip::ZipWriter;

    #[test]
    fn reuse_existing_refreshes_stale_resource_size() {
        let temp = TempDir::new().expect("tempdir");
        let path = temp.path().join("comic.cbz");
        let file = File::create(&path).expect("create");
        let mut zip = ZipWriter::new(file);
        zip.start_file("01.jpg", SimpleFileOptions::default())
            .expect("start");
        zip.write_all(b"fake-jpeg").expect("write");
        zip.finish().expect("finish");

        let path_str = path.to_string_lossy().to_string();
        let comic_id = comic_id_for_path(&path_str);
        let (modified_ms, size) = read_source_stat(&path, "cbz")
            .expect("stat")
            .expect("source stat");
        assert!(size > 0);

        let existing = ComicDto {
            comic_id: comic_id.clone(),
            path: path_str,
            resource_type: "cbz".to_string(),
            resource_size: 0,
            created_at: 1,
            last_updated_at: 1,
            title: "旧标题".to_string(),
            content_rating: "unknown".to_string(),
            page_count: 1,
            description: None,
            published_at: None,
            authors: vec![],
            tags: vec![],
        };
        let ctx = ScanContext {
            existing_by_id: HashMap::from([(comic_id.clone(), existing)]),
            thumbnail_stats: HashMap::from([(comic_id, (modified_ms, size))]),
        };

        let handle = create_sync_handle();
        let items = scan_roots(&[path], &ctx, &handle).expect("scan");
        assert_eq!(items.len(), 1);
        assert!(
            items[0].comic.resource_size > 0,
            "expected refreshed resource_size, got {}",
            items[0].comic.resource_size
        );
    }
}
