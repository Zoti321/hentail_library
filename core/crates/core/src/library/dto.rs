//! Library DTOs, scan interval, and format-group helpers.

use std::path::Path;

use sha1::{Digest, Sha1};

use crate::comic_id::normalize_path_for_key;
use crate::db::{connection, map_db_err};
use crate::entity::libraries;
use crate::error::HentaiError;
use crate::sync::format_group::FormatGroup;

pub(crate) const PREF_CURRENT_LIBRARY_ID: &str = "current_library_id";
pub(crate) const KIND_LOCAL: &str = "local";
pub(crate) const KIND_REMOTE: &str = "remote";
pub(crate) const DEFAULT_FORMAT_GROUPS: [FormatGroup; 4] = FormatGroup::ALL;
pub(crate) const REMOTE_DEFAULT_FORMAT_GROUPS: [FormatGroup; 3] =
    [FormatGroup::Pdf, FormatGroup::Epub, FormatGroup::Archive];

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ScanInterval {
    Disabled,
    Hourly,
    Every6Hours,
    Every12Hours,
    Daily,
    Weekly,
}

impl ScanInterval {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Disabled => "disabled",
            Self::Hourly => "hourly",
            Self::Every6Hours => "every_6_hours",
            Self::Every12Hours => "every_12_hours",
            Self::Daily => "daily",
            Self::Weekly => "weekly",
        }
    }

    /// Staleness window for Home library alert; `None` when interval is disabled.
    pub fn staleness_threshold_ms(self) -> Option<i64> {
        match self {
            Self::Disabled => None,
            Self::Hourly => Some(60 * 60 * 1000),
            Self::Every6Hours => Some(6 * 60 * 60 * 1000),
            Self::Every12Hours => Some(12 * 60 * 60 * 1000),
            Self::Daily => Some(24 * 60 * 60 * 1000),
            Self::Weekly => Some(7 * 24 * 60 * 60 * 1000),
        }
    }
}

pub fn parse_scan_interval(raw: &str) -> Result<ScanInterval, HentaiError> {
    match raw.trim().to_ascii_lowercase().as_str() {
        "disabled" => Ok(ScanInterval::Disabled),
        "hourly" => Ok(ScanInterval::Hourly),
        "every_6_hours" => Ok(ScanInterval::Every6Hours),
        "every_12_hours" => Ok(ScanInterval::Every12Hours),
        "daily" => Ok(ScanInterval::Daily),
        "weekly" => Ok(ScanInterval::Weekly),
        other => Err(HentaiError::validation(format!(
            "无效的 Scan interval: {other}"
        ))),
    }
}

pub(crate) fn scan_interval_from_stored(raw: &str) -> ScanInterval {
    parse_scan_interval(raw).unwrap_or(ScanInterval::Disabled)
}

#[derive(Debug, Clone)]
pub struct LibraryDto {
    pub library_id: String,
    pub kind: String,
    pub root_path: String,
    pub name: String,
    pub enabled_format_groups: Vec<FormatGroup>,
    pub created_at: i64,
    pub username: String,
    pub allow_http: bool,
    pub scan_on_startup: bool,
    pub scan_interval: ScanInterval,
    pub pinned: bool,
    pub sidebar_order: i32,
}

/// One Library's pin group and Library sidebar order.
#[derive(Debug, Clone)]
pub struct LibrarySidebarPlacement {
    pub library_id: String,
    pub pinned: bool,
    pub sidebar_order: i32,
}

/// SHA1 of `library:` + normalize_path_for_key(root) — distinct from comic_id.
pub fn library_id_from_root(root: &str) -> String {
    let normalized = normalize_path_for_key(root);
    let mut hasher = Sha1::new();
    hasher.update(b"library:");
    hasher.update(normalized.as_bytes());
    format!("{:x}", hasher.finalize())
}

pub fn serialize_format_groups(groups: &[FormatGroup]) -> String {
    let names: Vec<&str> = groups.iter().map(format_group_name).collect();
    serde_json::to_string(&names).unwrap_or_else(|_| "[]".to_string())
}

pub fn parse_format_groups_json(raw: &str) -> Vec<FormatGroup> {
    let Ok(names) = serde_json::from_str::<Vec<String>>(raw) else {
        return DEFAULT_FORMAT_GROUPS.to_vec();
    };
    // Explicit empty JSON array means all groups disabled.
    if names.is_empty() {
        return Vec::new();
    }
    let mut groups = Vec::new();
    for name in names {
        if let Some(group) = format_group_from_name(&name) {
            if !groups.contains(&group) {
                groups.push(group);
            }
        }
    }
    if groups.is_empty() {
        // Non-empty but all unrecognized → fall back to defaults.
        DEFAULT_FORMAT_GROUPS.to_vec()
    } else {
        groups
    }
}

pub(crate) fn format_group_name(group: &FormatGroup) -> &'static str {
    match group {
        FormatGroup::Folder => "folder",
        FormatGroup::Pdf => "pdf",
        FormatGroup::Epub => "epub",
        FormatGroup::Archive => "archive",
    }
}

pub(crate) fn format_group_from_name(name: &str) -> Option<FormatGroup> {
    match name.trim().to_ascii_lowercase().as_str() {
        "folder" => Some(FormatGroup::Folder),
        "pdf" => Some(FormatGroup::Pdf),
        "epub" => Some(FormatGroup::Epub),
        "archive" => Some(FormatGroup::Archive),
        _ => None,
    }
}

pub(crate) fn library_name_from_root(root: &str) -> String {
    let trimmed = root.trim().trim_end_matches(['/', '\\']);
    Path::new(trimmed)
        .file_name()
        .and_then(|n| n.to_str())
        .filter(|s| !s.is_empty())
        .unwrap_or(trimmed)
        .to_string()
}

pub(crate) fn library_name_from_webdav_root(root: &str) -> String {
    let trimmed = root.trim().trim_end_matches('/');
    if let Ok(url) = url::Url::parse(trimmed) {
        let path = url.path().trim_matches('/');
        if !path.is_empty() {
            if let Some(last) = path.rsplit('/').next() {
                if !last.is_empty() {
                    return last.to_string();
                }
            }
        }
        if let Some(host) = url.host_str() {
            return host.to_string();
        }
    }
    library_name_from_root(trimmed)
}

pub(crate) fn model_to_dto(model: libraries::Model) -> LibraryDto {
    LibraryDto {
        library_id: model.library_id,
        kind: model.kind,
        root_path: model.root_path,
        name: model.name,
        enabled_format_groups: parse_format_groups_json(&model.enabled_format_groups),
        created_at: model.created_at,
        username: model.username,
        allow_http: model.allow_http != 0,
        scan_on_startup: model.scan_on_startup != 0,
        scan_interval: scan_interval_from_stored(&model.scan_interval),
        pinned: model.pinned != 0,
        sidebar_order: model.sidebar_order,
    }
}
