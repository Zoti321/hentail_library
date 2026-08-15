mod remote_access;
mod webdav_root;

pub use remote_access::{
    clear_remote_library_credentials, remote_password_for, resolve_access_for_comic,
    set_remote_library_credentials, RemoteLibraryCredential, ResolvedAccess,
};
pub use webdav_root::{library_id_from_webdav_root, normalize_webdav_root};

use std::path::Path;

use sea_orm::{
    ActiveModelTrait, ColumnTrait, ConnectionTrait, EntityTrait, QueryFilter, QueryOrder, Set,
    Statement, TransactionTrait,
};
use sha1::{Digest, Sha1};

use crate::comic::now_ms;
use crate::comic_id::normalize_path_for_key;
use crate::db::{connection, map_db_err};
use crate::entity::{app_prefs, libraries, prelude::*};
use crate::error::HentaiError;
use crate::sync::format_group::FormatGroup;
use crate::sync::writer::delete_comics_side_effects;

const PREF_CURRENT_LIBRARY_ID: &str = "current_library_id";
const KIND_LOCAL: &str = "local";
const KIND_REMOTE: &str = "remote";
const DEFAULT_FORMAT_GROUPS: [FormatGroup; 4] = FormatGroup::ALL;
const REMOTE_DEFAULT_FORMAT_GROUPS: [FormatGroup; 3] = [
    FormatGroup::Pdf,
    FormatGroup::Epub,
    FormatGroup::Archive,
];

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

fn scan_interval_from_stored(raw: &str) -> ScanInterval {
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

fn format_group_name(group: &FormatGroup) -> &'static str {
    match group {
        FormatGroup::Folder => "folder",
        FormatGroup::Pdf => "pdf",
        FormatGroup::Epub => "epub",
        FormatGroup::Archive => "archive",
    }
}

fn format_group_from_name(name: &str) -> Option<FormatGroup> {
    match name.trim().to_ascii_lowercase().as_str() {
        "folder" => Some(FormatGroup::Folder),
        "pdf" => Some(FormatGroup::Pdf),
        "epub" => Some(FormatGroup::Epub),
        "archive" => Some(FormatGroup::Archive),
        _ => None,
    }
}

fn library_name_from_root(root: &str) -> String {
    let trimmed = root.trim().trim_end_matches(['/', '\\']);
    Path::new(trimmed)
        .file_name()
        .and_then(|n| n.to_str())
        .filter(|s| !s.is_empty())
        .unwrap_or(trimmed)
        .to_string()
}

fn library_name_from_webdav_root(root: &str) -> String {
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

fn model_to_dto(model: libraries::Model) -> LibraryDto {
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
    }
}

fn resolve_library_name(explicit: Option<&str>, derived: String) -> String {
    explicit
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(str::to_string)
        .unwrap_or(derived)
}

pub async fn list_libraries() -> Result<Vec<LibraryDto>, HentaiError> {
    let db = connection()?;
    let rows = Libraries::find()
        .order_by_asc(libraries::Column::RootPath)
        .all(&db)
        .await
        .map_err(map_db_err)?;
    Ok(rows.into_iter().map(model_to_dto).collect())
}

pub async fn create_local_library(
    root_path: &str,
    name: Option<&str>,
) -> Result<LibraryDto, HentaiError> {
    let root = root_path.trim();
    if root.is_empty() {
        return Err(HentaiError::validation("Library root 不能为空"));
    }
    let db = connection()?;
    let library_id = library_id_from_root(root);
    if let Some(existing) = Libraries::find_by_id(library_id.clone())
        .one(&db)
        .await
        .map_err(map_db_err)?
    {
        return Ok(model_to_dto(existing));
    }
    // Also treat same root_path as idempotent (different normalization edge cases).
    if let Some(existing) = Libraries::find()
        .filter(libraries::Column::RootPath.eq(root))
        .one(&db)
        .await
        .map_err(map_db_err)?
    {
        return Ok(model_to_dto(existing));
    }

    let existing_libs = list_libraries().await?;
    let new_key = normalize_path_for_key(root);
    for lib in &existing_libs {
        if lib.kind != KIND_LOCAL {
            continue;
        }
        let other = normalize_path_for_key(&lib.root_path);
        if other.is_empty() || new_key.is_empty() {
            continue;
        }
        if new_key == other
            || new_key.starts_with(&format!("{other}/"))
            || other.starts_with(&format!("{new_key}/"))
        {
            return Err(HentaiError::validation(
                "Local library 的 Library root 不能互相嵌套",
            ));
        }
    }

    let count = existing_libs.len();
    let dto = LibraryDto {
        library_id: library_id.clone(),
        kind: KIND_LOCAL.to_string(),
        root_path: root.to_string(),
        name: resolve_library_name(name, library_name_from_root(root)),
        enabled_format_groups: DEFAULT_FORMAT_GROUPS.to_vec(),
        created_at: now_ms(),
        username: String::new(),
        allow_http: false,
        scan_on_startup: false,
        scan_interval: ScanInterval::Disabled,
    };
    let active = libraries::ActiveModel {
        library_id: Set(dto.library_id.clone()),
        kind: Set(dto.kind.clone()),
        root_path: Set(dto.root_path.clone()),
        name: Set(dto.name.clone()),
        enabled_format_groups: Set(serialize_format_groups(&dto.enabled_format_groups)),
        created_at: Set(dto.created_at),
        username: Set(String::new()),
        allow_http: Set(0),
        scan_on_startup: Set(0),
        scan_interval: Set(ScanInterval::Disabled.as_str().to_string()),
    };
    Libraries::insert(active)
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    if count == 0 {
        set_current_library_id_inner(&db, Some(&dto.library_id)).await?;
    }
    Ok(dto)
}

pub async fn create_remote_library(
    root_url: &str,
    username: &str,
    allow_http: bool,
    name: Option<&str>,
) -> Result<LibraryDto, HentaiError> {
    let root = normalize_webdav_root(root_url, allow_http)?;
    let user = username.trim().to_string();
    let db = connection()?;
    let library_id = library_id_from_webdav_root(&root);

    if let Some(existing) = Libraries::find_by_id(library_id.clone())
        .one(&db)
        .await
        .map_err(map_db_err)?
    {
        return update_existing_remote(existing, &root, &user, allow_http).await;
    }
    if let Some(existing) = Libraries::find()
        .filter(libraries::Column::RootPath.eq(root.clone()))
        .one(&db)
        .await
        .map_err(map_db_err)?
    {
        return update_existing_remote(existing, &root, &user, allow_http).await;
    }

    let count = list_libraries().await?.len();
    let dto = LibraryDto {
        library_id: library_id.clone(),
        kind: KIND_REMOTE.to_string(),
        root_path: root.clone(),
        name: resolve_library_name(name, library_name_from_webdav_root(&root)),
        enabled_format_groups: REMOTE_DEFAULT_FORMAT_GROUPS.to_vec(),
        created_at: now_ms(),
        username: user.clone(),
        allow_http,
        scan_on_startup: false,
        scan_interval: ScanInterval::Disabled,
    };
    let active = libraries::ActiveModel {
        library_id: Set(dto.library_id.clone()),
        kind: Set(dto.kind.clone()),
        root_path: Set(dto.root_path.clone()),
        name: Set(dto.name.clone()),
        enabled_format_groups: Set(serialize_format_groups(&dto.enabled_format_groups)),
        created_at: Set(dto.created_at),
        username: Set(user),
        allow_http: Set(if allow_http { 1 } else { 0 }),
        scan_on_startup: Set(0),
        scan_interval: Set(ScanInterval::Disabled.as_str().to_string()),
    };
    Libraries::insert(active)
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    if count == 0 {
        set_current_library_id_inner(&db, Some(&dto.library_id)).await?;
    }
    Ok(dto)
}

pub async fn update_remote_library(
    library_id: &str,
    root_url: &str,
    username: &str,
    allow_http: bool,
) -> Result<LibraryDto, HentaiError> {
    let id = library_id.trim();
    if id.is_empty() {
        return Err(HentaiError::validation("library_id 不能为空"));
    }
    let root = normalize_webdav_root(root_url, allow_http)?;
    let user = username.trim().to_string();
    let db = connection()?;
    let Some(model) = Libraries::find_by_id(id.to_string())
        .one(&db)
        .await
        .map_err(map_db_err)?
    else {
        return Err(HentaiError::validation(format!("Library 不存在: {id}")));
    };
    if model.kind != KIND_REMOTE {
        return Err(HentaiError::validation("仅 Remote library 可更新 WebDAV 根"));
    }

    // Prevent colliding with another library's root_path.
    if let Some(other) = Libraries::find()
        .filter(libraries::Column::RootPath.eq(root.clone()))
        .one(&db)
        .await
        .map_err(map_db_err)?
    {
        if other.library_id != id {
            return Err(HentaiError::validation("WebDAV 根已被其他 Library 使用"));
        }
    }

    update_existing_remote(model, &root, &user, allow_http).await
}

async fn update_existing_remote(
    model: libraries::Model,
    root: &str,
    username: &str,
    allow_http: bool,
) -> Result<LibraryDto, HentaiError> {
    if model.kind != KIND_REMOTE {
        return Err(HentaiError::validation("仅 Remote library 可更新 WebDAV 根"));
    }
    let db = connection()?;
    let mut active: libraries::ActiveModel = model.into();
    active.root_path = Set(root.to_string());
    active.name = Set(library_name_from_webdav_root(root));
    active.username = Set(username.to_string());
    active.allow_http = Set(if allow_http { 1 } else { 0 });
    let updated = active.update(&db).await.map_err(map_db_err)?;
    Ok(model_to_dto(updated))
}

pub async fn delete_library(library_id: &str) -> Result<(), HentaiError> {
    let id = library_id.trim();
    if id.is_empty() {
        return Err(HentaiError::validation("library_id 不能为空"));
    }
    let db = connection()?;
    let existing = Libraries::find_by_id(id.to_string())
        .one(&db)
        .await
        .map_err(map_db_err)?;
    if existing.is_none() {
        return Ok(());
    }

    let txn = db.begin().await.map_err(map_db_err)?;
    let comic_ids = load_comic_ids_for_library(&txn, id).await?;
    delete_comics_side_effects(&txn, &comic_ids).await?;
    txn.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM series WHERE library_id = ?",
        [sea_orm::Value::String(Some(Box::new(id.to_string())))],
    ))
    .await
    .map_err(map_db_err)?;
    Libraries::delete_by_id(id.to_string())
        .exec(&txn)
        .await
        .map_err(map_db_err)?;
    txn.commit().await.map_err(map_db_err)?;

    let current = get_current_library_id().await?;
    if current.as_deref() == Some(id) {
        let remaining = list_libraries().await?;
        let next = remaining.first().map(|l| l.library_id.clone());
        set_current_library_id_inner(&db, next.as_deref()).await?;
    }
    Ok(())
}

pub async fn get_current_library_id() -> Result<Option<String>, HentaiError> {
    let db = connection()?;
    get_pref(&db, PREF_CURRENT_LIBRARY_ID).await
}

pub async fn set_current_library_id(library_id: Option<&str>) -> Result<(), HentaiError> {
    let db = connection()?;
    if let Some(id) = library_id {
        let id = id.trim();
        if id.is_empty() {
            set_current_library_id_inner(&db, None).await?;
            return Ok(());
        }
        let exists = Libraries::find_by_id(id.to_string())
            .one(&db)
            .await
            .map_err(map_db_err)?
            .is_some();
        if !exists {
            return Err(HentaiError::validation(format!(
                "Library 不存在: {id}"
            )));
        }
        set_current_library_id_inner(&db, Some(id)).await?;
    } else {
        set_current_library_id_inner(&db, None).await?;
    }
    Ok(())
}

pub async fn update_library_format_groups(
    library_id: &str,
    groups: Vec<FormatGroup>,
) -> Result<LibraryDto, HentaiError> {
    let id = library_id.trim();
    if id.is_empty() {
        return Err(HentaiError::validation("library_id 不能为空"));
    }
    let db = connection()?;
    let Some(model) = Libraries::find_by_id(id.to_string())
        .one(&db)
        .await
        .map_err(map_db_err)?
    else {
        return Err(HentaiError::validation(format!("Library 不存在: {id}")));
    };
    // Empty list is intentional (user may disable all groups until next sync).
    let mut active: libraries::ActiveModel = model.into();
    active.enabled_format_groups = Set(serialize_format_groups(&groups));
    let updated = active.update(&db).await.map_err(map_db_err)?;
    Ok(model_to_dto(updated))
}

pub async fn update_library_settings(
    library_id: &str,
    name: &str,
    groups: Vec<FormatGroup>,
    scan_on_startup: bool,
    scan_interval: ScanInterval,
) -> Result<LibraryDto, HentaiError> {
    let id = library_id.trim();
    if id.is_empty() {
        return Err(HentaiError::validation("library_id 不能为空"));
    }
    let trimmed_name = name.trim();
    if trimmed_name.is_empty() {
        return Err(HentaiError::validation("Library name 不能为空"));
    }
    let db = connection()?;
    let Some(model) = Libraries::find_by_id(id.to_string())
        .one(&db)
        .await
        .map_err(map_db_err)?
    else {
        return Err(HentaiError::validation(format!("Library 不存在: {id}")));
    };
    let mut active: libraries::ActiveModel = model.into();
    active.name = Set(trimmed_name.to_string());
    active.enabled_format_groups = Set(serialize_format_groups(&groups));
    active.scan_on_startup = Set(if scan_on_startup { 1 } else { 0 });
    active.scan_interval = Set(scan_interval.as_str().to_string());
    let updated = active.update(&db).await.map_err(map_db_err)?;
    Ok(model_to_dto(updated))
}

/// Used when migrating legacy app-level `autoScan: true` onto every Library.
pub async fn set_all_libraries_scan_on_startup(enabled: bool) -> Result<(), HentaiError> {
    let db = connection()?;
    let flag = if enabled { 1 } else { 0 };
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "UPDATE libraries SET scan_on_startup = ?",
        [sea_orm::Value::Int(Some(flag))],
    ))
    .await
    .map_err(map_db_err)?;
    Ok(())
}

pub async fn find_library_by_id(library_id: &str) -> Result<Option<LibraryDto>, HentaiError> {
    let db = connection()?;
    let row = Libraries::find_by_id(library_id.to_string())
        .one(&db)
        .await
        .map_err(map_db_err)?;
    Ok(row.map(model_to_dto))
}

/// Resolve browse/search scope: explicit filter wins; otherwise Current library.
pub async fn resolve_browse_library_id(
    filter_library_id: Option<String>,
) -> Result<Option<String>, HentaiError> {
    if let Some(id) = filter_library_id {
        let trimmed = id.trim().to_string();
        if !trimmed.is_empty() {
            return Ok(Some(trimmed));
        }
    }
    get_current_library_id().await
}

async fn get_pref(
    db: &sea_orm::DatabaseConnection,
    key: &str,
) -> Result<Option<String>, HentaiError> {
    let row = AppPrefs::find_by_id(key.to_string())
        .one(db)
        .await
        .map_err(map_db_err)?;
    Ok(row.map(|r| r.value).filter(|v| !v.is_empty()))
}

async fn set_current_library_id_inner(
    db: &sea_orm::DatabaseConnection,
    library_id: Option<&str>,
) -> Result<(), HentaiError> {
    match library_id {
        Some(id) => {
            let active = app_prefs::ActiveModel {
                key: Set(PREF_CURRENT_LIBRARY_ID.to_string()),
                value: Set(id.to_string()),
            };
            AppPrefs::insert(active)
                .on_conflict(
                    sea_orm::sea_query::OnConflict::column(app_prefs::Column::Key)
                        .update_column(app_prefs::Column::Value)
                        .to_owned(),
                )
                .exec(db)
                .await
                .map_err(map_db_err)?;
        }
        None => {
            AppPrefs::delete_by_id(PREF_CURRENT_LIBRARY_ID.to_string())
                .exec(db)
                .await
                .map_err(map_db_err)?;
        }
    }
    Ok(())
}

async fn load_comic_ids_for_library<C: ConnectionTrait>(
    db: &C,
    library_id: &str,
) -> Result<Vec<String>, HentaiError> {
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT comic_id FROM comics WHERE library_id = ?",
            [sea_orm::Value::String(Some(Box::new(library_id.to_string())))],
        ))
        .await
        .map_err(map_db_err)?;
    rows.into_iter()
        .map(|row| {
            row.try_get_by_index::<String>(0)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
        })
        .collect()
}
