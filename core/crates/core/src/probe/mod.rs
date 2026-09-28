mod snapshot;

use std::collections::HashMap;

use crate::comic::now_ms;
use crate::db::connection;
use crate::error::HentaiError;
use crate::library::{find_library_by_id, list_libraries, remote_password_for, LibraryDto};
use crate::resource::{
    local_access, normalize_roots, read_source_stat_with, ResourceAccess, ResourceKind,
    WebDavResourceAccess,
};
use crate::sync::format_group::resource_type_enabled;
use crate::sync::handle::create_sync_handle;
use crate::sync::remote::{
    collect_remote_files, normalize_remote_location_key, remote_resource_type_from_location,
};
use crate::sync::scanner::{enumerate_local_resources, EnumeratedResource, ScanItem};

pub use snapshot::{
    delete_snapshots_for_library, load_snapshot_map, rebuild_snapshot_from_scan_items,
    snapshot_row_count,
};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LibraryProbeResultDto {
    pub library_id: String,
    pub added_count: i32,
    pub changed_count: i32,
    pub removed_count: i32,
    pub unreachable: bool,
    pub error_message: Option<String>,
    pub probed_at_ms: i64,
    pub baseline_missing: bool,
}

pub async fn probe_library(
    library_id: &str,
    password: Option<&str>,
) -> Result<LibraryProbeResultDto, HentaiError> {
    let library = find_library_by_id(library_id)
        .await?
        .ok_or_else(|| HentaiError::validation(format!("Library 不存在: {library_id}")))?;
    let db = connection()?;
    let snapshot = snapshot::load_snapshot_map(&db, library_id).await?;
    let baseline_missing = snapshot.is_empty();
    let handle = create_sync_handle();
    let exclude_roots: Vec<String> = list_libraries()
        .await?
        .into_iter()
        .filter(|lib| lib.library_id != library.library_id)
        .map(|lib| lib.root_path)
        .collect();
    let enumerated = match probe_enumerate(&library, password, &exclude_roots, &handle)? {
        ProbeEnumerateOutcome::Ok(items) => items,
        ProbeEnumerateOutcome::Unreachable(message) => {
            return Ok(LibraryProbeResultDto {
                library_id: library_id.to_string(),
                added_count: 0,
                changed_count: 0,
                removed_count: 0,
                unreachable: true,
                error_message: Some(message),
                probed_at_ms: now_ms(),
                baseline_missing,
            });
        }
    };
    let diff = diff_enumerated(&snapshot, &enumerated);
    Ok(LibraryProbeResultDto {
        library_id: library_id.to_string(),
        added_count: diff.added,
        changed_count: diff.changed,
        removed_count: diff.removed,
        unreachable: false,
        error_message: None,
        probed_at_ms: now_ms(),
        baseline_missing,
    })
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ProbeDiff {
    pub added: i32,
    pub changed: i32,
    pub removed: i32,
}

/// Diff snapshot vs freshly enumerated resources (exported for integration tests).
pub fn diff_enumerated(
    snapshot: &HashMap<String, (i64, i64, String)>,
    enumerated: &[EnumeratedResource],
) -> ProbeDiff {
    let mut added = 0i32;
    let mut changed = 0i32;
    let mut seen = HashMap::new();
    for item in enumerated {
        seen.insert(item.location_key.clone(), (item.modified_ms, item.size));
        match snapshot.get(&item.location_key) {
            None => added += 1,
            Some((modified_ms, size, _))
                if *modified_ms != item.modified_ms || *size != item.size =>
            {
                changed += 1
            }
            Some(_) => {}
        }
    }
    let mut removed = 0i32;
    for key in snapshot.keys() {
        if !seen.contains_key(key) {
            removed += 1;
        }
    }
    ProbeDiff {
        added,
        changed,
        removed,
    }
}

enum ProbeEnumerateOutcome {
    Ok(Vec<EnumeratedResource>),
    Unreachable(String),
}

fn probe_enumerate(
    library: &LibraryDto,
    password: Option<&str>,
    exclude_roots: &[String],
    handle: &crate::sync::handle::SyncHandle,
) -> Result<ProbeEnumerateOutcome, HentaiError> {
    if library.kind == "remote" {
        return probe_enumerate_remote(library, password, handle);
    }
    probe_enumerate_local(library, exclude_roots, handle)
}

fn probe_enumerate_local(
    library: &LibraryDto,
    exclude_roots: &[String],
    handle: &crate::sync::handle::SyncHandle,
) -> Result<ProbeEnumerateOutcome, HentaiError> {
    let roots = normalize_roots(std::slice::from_ref(&library.root_path));
    if roots.is_empty() {
        return Ok(ProbeEnumerateOutcome::Ok(vec![]));
    }
    if let Err(err) = local_access().probe_root(&library.root_path) {
        return Ok(ProbeEnumerateOutcome::Unreachable(err.message));
    }
    let items = enumerate_local_resources(
        &roots,
        exclude_roots,
        handle,
        &library.enabled_format_groups,
    )?;
    Ok(ProbeEnumerateOutcome::Ok(items))
}

fn probe_enumerate_remote(
    library: &LibraryDto,
    password: Option<&str>,
    handle: &crate::sync::handle::SyncHandle,
) -> Result<ProbeEnumerateOutcome, HentaiError> {
    let password = password
        .map(str::to_string)
        .or_else(|| remote_password_for(&library.library_id))
        .filter(|p| !p.is_empty());
    let Some(password) = password else {
        return Ok(ProbeEnumerateOutcome::Unreachable(
            "缺少远程库凭证".to_string(),
        ));
    };
    let access =
        match WebDavResourceAccess::connect(&library.root_path, &library.username, &password) {
            Ok(access) => access,
            Err(err) if err.is_remote_access_failure() => {
                return Ok(ProbeEnumerateOutcome::Unreachable(err.message));
            }
            Err(err) => return Err(err),
        };
    match enumerate_remote_resources(
        &access,
        &library.root_path,
        handle,
        &library.enabled_format_groups,
    ) {
        Ok(items) => Ok(ProbeEnumerateOutcome::Ok(items)),
        Err(err) if err.is_remote_access_failure() => {
            Ok(ProbeEnumerateOutcome::Unreachable(err.message))
        }
        Err(err) => Err(err),
    }
}

fn enumerate_remote_resources(
    access: &dyn ResourceAccess,
    root: &str,
    handle: &crate::sync::handle::SyncHandle,
    enabled_groups: &[crate::sync::format_group::FormatGroup],
) -> Result<Vec<EnumeratedResource>, HentaiError> {
    let root_key = normalize_remote_location_key(root);
    if root_key.is_empty() {
        return Err(HentaiError::validation("WebDAV 根 URL 不能为空"));
    }
    match access.stat(&root_key) {
        Err(err) if err.is_remote_access_failure() => return Err(err),
        Err(err) => return Err(err),
        Ok(None) => {
            return Err(HentaiError::remote_unreachable(format!(
                "远程根不存在或不可达: {root_key}"
            )));
        }
        Ok(Some(stat)) if stat.kind != ResourceKind::Dir => {
            return Err(HentaiError::validation(format!(
                "远程 Library root 必须是目录: {root_key}"
            )));
        }
        Ok(Some(_)) => {}
    }
    let mut files = Vec::new();
    collect_remote_files(access, &root_key, &mut files, handle)?;
    if handle.is_cancelled() {
        return Ok(vec![]);
    }
    let mut out = Vec::new();
    for location in files {
        if handle.is_cancelled() {
            break;
        }
        let Some(resource_type) = remote_resource_type_from_location(&location) else {
            continue;
        };
        if !resource_type_enabled(resource_type, enabled_groups) {
            continue;
        }
        let path = normalize_remote_location_key(&location);
        let Some((modified_ms, size)) = read_source_stat_with(access, &path, resource_type)? else {
            continue;
        };
        out.push(EnumeratedResource {
            location_key: path,
            resource_type: resource_type.to_string(),
            modified_ms,
            size,
        });
    }
    Ok(out)
}

pub(crate) fn scan_item_location_key(library: &LibraryDto, item: &ScanItem) -> String {
    if library.kind == "remote" {
        normalize_remote_location_key(&item.path)
    } else {
        crate::comic_id::normalize_path_for_key(&item.path)
    }
}
