//! Lightweight Remote library discovery — extension-based registration, no full parse.

use std::path::Path;

use crate::comic::{now_ms, ComicDto};
use crate::comic_id::comic_id_from_normalized_path;
use crate::error::HentaiError;
use crate::library::normalize_webdav_root;
use crate::resource::{
    basename_without_extension, extension_lower, ResourceAccess, ResourceKind,
};

use super::format_group::{resource_type_enabled, FormatGroup};
use super::handle::SyncHandle;
use super::scanner::{ScanContext, ScanItem};

pub enum RemoteScanOutcome {
    Unreachable { message: String },
    /// Caller must not apply a replace plan (would orphan-delete).
    Cancelled,
    Scanned(Vec<ScanItem>),
}

/// SHA1 of a normalized WebDAV resource URL (ADR-0001 remote location key).
pub fn comic_id_for_remote_location(location: &str) -> String {
    let normalized = normalize_remote_location_key(location);
    if normalized.is_empty() {
        return String::new();
    }
    comic_id_from_normalized_path(&normalized)
}

pub fn normalize_remote_location_key(location: &str) -> String {
    // allow_http=true: identity key must not reject stored http roots.
    normalize_webdav_root(location, true).unwrap_or_else(|_| {
        let mut s = location.trim().replace('\\', "/");
        while s.ends_with('/') && s.len() > 1 {
            s.pop();
        }
        s
    })
}

/// Probe Remote root via [ResourceAccess]; on transport/auth failure skip without scanning.
pub fn scan_remote_lightweight(
    access: &dyn ResourceAccess,
    root: &str,
    _ctx: &ScanContext,
    handle: &SyncHandle,
    enabled_groups: &[FormatGroup],
) -> Result<RemoteScanOutcome, HentaiError> {
    let root_key = normalize_remote_location_key(root);
    if root_key.is_empty() {
        return Err(HentaiError::validation("WebDAV 根 URL 不能为空"));
    }

    match access.stat(&root_key) {
        Err(err) if err.is_remote_access_failure() => {
            return Ok(RemoteScanOutcome::Unreachable {
                message: err.message,
            });
        }
        Err(err) => return Err(err),
        Ok(None) => {
            return Ok(RemoteScanOutcome::Unreachable {
                message: format!("远程根不存在或不可达: {root_key}"),
            });
        }
        Ok(Some(stat)) if stat.kind != ResourceKind::Dir => {
            return Err(HentaiError::validation(format!(
                "远程 Library root 必须是目录: {root_key}"
            )));
        }
        Ok(Some(_)) => {}
    }

    let mut files = Vec::new();
    match collect_remote_files(access, &root_key, &mut files, handle) {
        Err(err) if err.is_remote_access_failure() => {
            return Ok(RemoteScanOutcome::Unreachable {
                message: err.message,
            });
        }
        Err(err) => return Err(err),
        Ok(()) => {}
    }
    if handle.is_cancelled() {
        return Ok(RemoteScanOutcome::Cancelled);
    }

    let mut items = Vec::new();
    for location in files {
        if handle.is_cancelled() {
            return Ok(RemoteScanOutcome::Cancelled);
        }
        if let Some(item) = register_remote_file(access, &location, enabled_groups)? {
            items.push(item);
        }
    }
    Ok(RemoteScanOutcome::Scanned(items))
}

fn collect_remote_files(
    access: &dyn ResourceAccess,
    dir: &str,
    out: &mut Vec<String>,
    handle: &SyncHandle,
) -> Result<(), HentaiError> {
    if handle.is_cancelled() {
        return Ok(());
    }
    for entry in access.list(dir)? {
        if handle.is_cancelled() {
            return Ok(());
        }
        match entry.kind {
            ResourceKind::Dir => {
                // Remote image-folder comics are out of scope — only walk for nested files.
                collect_remote_files(access, &entry.location, out, handle)?;
            }
            ResourceKind::File => out.push(entry.location),
        }
    }
    Ok(())
}

fn register_remote_file(
    access: &dyn ResourceAccess,
    location: &str,
    enabled_groups: &[FormatGroup],
) -> Result<Option<ScanItem>, HentaiError> {
    let Some(resource_type) = remote_resource_type_from_location(location) else {
        return Ok(None);
    };
    if !resource_type_enabled(resource_type, enabled_groups) {
        return Ok(None);
    }

    let Some(stat) = access.stat(location)? else {
        return Ok(None);
    };
    if stat.kind != ResourceKind::File {
        return Ok(None);
    }

    let path = normalize_remote_location_key(location);
    let title = basename_without_extension(Path::new(
        path.rsplit('/').next().unwrap_or(path.as_str()),
    ));
    let title = if title.is_empty() {
        path.clone()
    } else {
        title
    };
    let now = now_ms();
    let modified = if stat.modified_ms > 0 {
        stat.modified_ms
    } else {
        now
    };
    let comic = ComicDto {
        comic_id: comic_id_for_remote_location(&path),
        path: path.clone(),
        resource_type: resource_type.to_string(),
        resource_size: stat.size as i64,
        created_at: now,
        last_updated_at: modified,
        title,
        content_rating: "unknown".to_string(),
        // DB CHECK requires page_count > 0; real count is filled on first open (#59).
        page_count: 1,
        description: None,
        published_at: None,
        last_read_time_ms: None,
        authors: vec![],
        tags: vec![],
        languages: vec![],
        parodies: vec![],
        characters: vec![],
        locks: Default::default(),
        library_id: String::new(),
    };
    Ok(Some(ScanItem {
        path,
        resource_type: resource_type.to_string(),
        comic,
    }))
}

fn remote_resource_type_from_location(location: &str) -> Option<&'static str> {
    let name = location.rsplit('/').next().unwrap_or(location);
    let ext = extension_lower(Path::new(name));
    match ext.as_str() {
        ".pdf" => Some("pdf"),
        ".epub" => Some("epub"),
        ".zip" => Some("zip"),
        ".cbz" => Some("cbz"),
        ".cbr" => Some("cbr"),
        ".rar" => Some("rar"),
        ".cb7" => Some("cb7"),
        ".7z" => Some("sevenz"),
        _ => None,
    }
}
