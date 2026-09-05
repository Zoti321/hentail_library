use std::collections::HashMap;
use std::path::PathBuf;

use rayon::prelude::*;

use crate::comic::ComicDto;
use crate::error::HentaiError;

use super::format_group::{resource_type_enabled, FormatGroup};
use super::handle::SyncHandle;
use crate::resource::{
    comic_id_for_path, local_access, parse_directory_with, parse_file_with, read_resource_size_with,
    read_source_stat_with, ResourceAccess, ResourceKind,
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
    force_full_parse: bool,
    enabled_groups: &[FormatGroup],
) -> Result<Vec<ScanItem>, HentaiError> {
    scan_roots_excluding(roots, &[], ctx, handle, force_full_parse, enabled_groups)
}

pub fn scan_roots_excluding(
    roots: &[PathBuf],
    exclude_roots: &[String],
    ctx: &ScanContext,
    handle: &SyncHandle,
    force_full_parse: bool,
    enabled_groups: &[FormatGroup],
) -> Result<Vec<ScanItem>, HentaiError> {
    let root_locs: Vec<String> = roots
        .iter()
        .map(|r| r.to_string_lossy().into_owned())
        .collect();
    scan_roots_with(
        local_access(),
        &root_locs,
        exclude_roots,
        ctx,
        handle,
        force_full_parse,
        enabled_groups,
    )
}

pub fn scan_roots_with(
    access: &dyn ResourceAccess,
    roots: &[String],
    exclude_roots: &[String],
    ctx: &ScanContext,
    handle: &SyncHandle,
    force_full_parse: bool,
    enabled_groups: &[FormatGroup],
) -> Result<Vec<ScanItem>, HentaiError> {
    let exclude_keys: Vec<String> = exclude_roots
        .iter()
        .map(|r| crate::comic_id::normalize_path_for_key(r))
        .filter(|k| !k.is_empty())
        .collect();
    let mut candidates: Vec<String> = Vec::new();
    for root in roots {
        if handle.is_cancelled() {
            return Ok(vec![]);
        }
        let Some(stat) = access.stat(root)? else {
            continue;
        };
        match stat.kind {
            ResourceKind::Dir => {
                collect_from_directory(
                    access,
                    root,
                    &exclude_keys,
                    &mut candidates,
                    handle,
                    enabled_groups,
                )?;
            }
            ResourceKind::File => candidates.push(root.clone()),
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
                resolve_scan_item(access, path, ctx, force_full_parse, enabled_groups)
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

fn is_excluded_root(location: &str, exclude_keys: &[String]) -> bool {
    let key = crate::comic_id::normalize_path_for_key(location);
    if key.is_empty() {
        return false;
    }
    exclude_keys.contains(&key)
}

fn collect_from_directory(
    access: &dyn ResourceAccess,
    dir: &str,
    exclude_keys: &[String],
    out: &mut Vec<String>,
    handle: &SyncHandle,
    enabled_groups: &[FormatGroup],
) -> Result<(), HentaiError> {
    if handle.is_cancelled() {
        return Ok(());
    }
    if let Some(parsed) = parse_directory_with(access, dir)? {
        if resource_type_enabled(&parsed.resource_type, enabled_groups) {
            out.push(parsed.path);
        }
        return Ok(());
    }
    for entry in access.list(dir)? {
        if handle.is_cancelled() {
            return Ok(());
        }
        match entry.kind {
            ResourceKind::Dir => {
                if is_excluded_root(&entry.location, exclude_keys) {
                    continue;
                }
                collect_from_directory(
                    access,
                    &entry.location,
                    exclude_keys,
                    out,
                    handle,
                    enabled_groups,
                )?;
            }
            ResourceKind::File => out.push(entry.location),
        }
    }
    Ok(())
}

fn resolve_scan_item(
    access: &dyn ResourceAccess,
    path: &str,
    ctx: &ScanContext,
    force_full_parse: bool,
    enabled_groups: &[FormatGroup],
) -> Result<Option<ScanItem>, HentaiError> {
    let comic_id = comic_id_for_path(path);
    if !force_full_parse {
        if let Some(existing) = ctx.existing_by_id.get(&comic_id) {
            if try_reuse_existing(access, path, existing, ctx) {
                if !resource_type_enabled(&existing.resource_type, enabled_groups) {
                    return Ok(None);
                }
                let mut comic = existing.clone();
                refresh_resource_size(access, path, &mut comic)?;
                return Ok(Some(ScanItem {
                    path: existing.path.clone(),
                    resource_type: existing.resource_type.clone(),
                    comic,
                }));
            }
        }
    }
    let kind = match access.stat(path)? {
        Some(stat) => stat.kind,
        None => return Ok(None),
    };
    let parsed = match kind {
        ResourceKind::Dir => parse_directory_with(access, path)?,
        ResourceKind::File => parse_file_with(access, path)?,
    };
    let Some(parsed) = parsed else {
        return Ok(None);
    };
    if !resource_type_enabled(&parsed.resource_type, enabled_groups) {
        return Ok(None);
    }
    let comic = crate::resource::parsed_to_comic(&parsed);
    Ok(Some(ScanItem {
        path: parsed.path,
        resource_type: parsed.resource_type,
        comic,
    }))
}

fn refresh_resource_size(
    access: &dyn ResourceAccess,
    path: &str,
    comic: &mut ComicDto,
) -> Result<(), HentaiError> {
    if let Some(size) = read_resource_size_with(access, path, &comic.resource_type)? {
        comic.resource_size = size;
    }
    Ok(())
}

fn try_reuse_existing(
    access: &dyn ResourceAccess,
    path: &str,
    existing: &ComicDto,
    ctx: &ScanContext,
) -> bool {
    if existing.path != path {
        return false;
    }
    let Ok(Some((modified_ms, size))) = read_source_stat_with(access, path, &existing.resource_type)
    else {
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
    use crate::resource::FakeResourceAccess;
    use crate::sync::handle::create_sync_handle;
    use std::collections::HashMap;
    use std::fs::File;
    use std::io::{Cursor, Write};
    use tempfile::TempDir;
    use zip::write::SimpleFileOptions;
    use zip::ZipWriter;

    fn write_minimal_cbz(bytes: &mut Vec<u8>) {
        let mut zip = ZipWriter::new(Cursor::new(bytes));
        zip.start_file("01.jpg", SimpleFileOptions::default())
            .expect("start");
        zip.write_all(b"fake-jpeg").expect("write");
        zip.finish().expect("finish");
    }

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
        let (modified_ms, size) = read_source_stat_with(local_access(), &path_str, "cbz")
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
            last_read_time_ms: None,
            authors: vec![],
            tags: vec![],
            languages: vec![],
            parodies: vec![],
            characters: vec![],
            locks: crate::comic::ComicMetaLocks::default(),
            library_id: String::new(),
        };
        let ctx = ScanContext {
            existing_by_id: HashMap::from([(comic_id.clone(), existing)]),
            thumbnail_stats: HashMap::from([(comic_id, (modified_ms, size))]),
        };

        let handle = create_sync_handle();
        let items = scan_roots(&[path], &ctx, &handle, false, &FormatGroup::ALL).expect("scan");
        assert_eq!(items.len(), 1);
        assert!(
            items[0].comic.resource_size > 0,
            "expected refreshed resource_size, got {}",
            items[0].comic.resource_size
        );
    }

    #[test]
    fn scan_roots_skips_resource_types_outside_enabled_format_groups() {
        let temp = TempDir::new().expect("tempdir");
        let root = temp.path();

        let folder = root.join("image_comic");
        std::fs::create_dir(&folder).expect("mkdir");
        std::fs::write(folder.join("01.jpg"), b"fake-jpeg").expect("write jpg");

        let cbz_path = root.join("archive.cbz");
        let file = File::create(&cbz_path).expect("create");
        let mut zip = ZipWriter::new(file);
        zip.start_file("01.jpg", SimpleFileOptions::default())
            .expect("start");
        zip.write_all(b"fake-jpeg").expect("write");
        zip.finish().expect("finish");

        let ctx = ScanContext {
            existing_by_id: HashMap::new(),
            thumbnail_stats: HashMap::new(),
        };
        let handle = create_sync_handle();
        let items = scan_roots(
            &[root.to_path_buf()],
            &ctx,
            &handle,
            false,
            &[FormatGroup::Folder],
        )
        .expect("scan");

        assert_eq!(items.len(), 1);
        assert_eq!(items[0].resource_type, "dir");
    }

    #[test]
    fn fake_access_discovers_dir_and_cbz_without_disk_walk() {
        let mut cbz = Vec::new();
        write_minimal_cbz(&mut cbz);

        let mut fake = FakeResourceAccess::new();
        fake.insert_dir("/lib");
        fake.insert_dir("/lib/folder");
        fake.insert_file("/lib/folder/01.jpg", b"fake-jpeg");
        fake.insert_file("/lib/comic.cbz", cbz);

        let handle = create_sync_handle();
        let ctx = ScanContext {
            existing_by_id: HashMap::new(),
            thumbnail_stats: HashMap::new(),
        };
        let items = scan_roots_with(
            &fake,
            &["/lib".to_string()],
            &[],
            &ctx,
            &handle,
            true,
            &[FormatGroup::Folder, FormatGroup::Archive],
        )
        .expect("scan");
        let mut paths: Vec<_> = items.iter().map(|i| i.path.as_str()).collect();
        paths.sort();
        assert_eq!(paths, vec!["/lib/comic.cbz", "/lib/folder"]);
        assert!(items.iter().any(|i| i.resource_type == "dir"));
        assert!(items.iter().any(|i| i.resource_type == "cbz"));
    }
}

