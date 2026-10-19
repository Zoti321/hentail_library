//! Library CRUD, sidebar layout, and current-library preferences.

use std::collections::HashSet;

use sea_orm::{
    ActiveModelTrait, ColumnTrait, ConnectionTrait, EntityTrait, QueryFilter, QueryOrder, Set,
    Statement, TransactionTrait,
};

use crate::comic::now_ms;
use crate::db::{connection, map_db_err};
use crate::entity::{app_prefs, libraries, prelude::*};
use crate::error::HentaiError;
use crate::sync::format_group::FormatGroup;
use crate::sync::writer::delete_comics_side_effects;

use super::dto::{
    library_id_from_root, library_name_from_root, library_name_from_webdav_root, model_to_dto,
    serialize_format_groups, LibraryDto, LibrarySidebarPlacement, ScanInterval,
    DEFAULT_FORMAT_GROUPS, KIND_LOCAL, KIND_REMOTE, PREF_CURRENT_LIBRARY_ID,
    REMOTE_DEFAULT_FORMAT_GROUPS,
};
use super::local_root_update::ensure_local_root_not_nested;
use super::webdav_root::{library_id_from_webdav_root, normalize_webdav_root};

pub(crate) fn resolve_library_name(explicit: Option<&str>, derived: String) -> String {
    explicit
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(str::to_string)
        .unwrap_or(derived)
}

pub async fn list_libraries() -> Result<Vec<LibraryDto>, HentaiError> {
    let db = connection()?;
    let rows = Libraries::find()
        .order_by_desc(libraries::Column::Pinned)
        .order_by_asc(libraries::Column::SidebarOrder)
        .order_by_asc(libraries::Column::RootPath)
        .all(&db)
        .await
        .map_err(map_db_err)?;
    Ok(rows.into_iter().map(model_to_dto).collect())
}

pub(crate) fn next_pinned_sidebar_order(libs: &[LibraryDto]) -> i32 {
    libs.iter()
        .filter(|lib| lib.pinned)
        .map(|lib| lib.sidebar_order)
        .max()
        .map(|max| max + 1)
        .unwrap_or(0)
}

/// Replace every Library's pin group and Library sidebar order.
///
/// [placements] must contain each existing Library exactly once.
pub async fn update_library_sidebar_layout(
    placements: Vec<LibrarySidebarPlacement>,
) -> Result<Vec<LibraryDto>, HentaiError> {
    let existing = list_libraries().await?;
    let existing_ids: HashSet<&str> = existing.iter().map(|l| l.library_id.as_str()).collect();
    let mut seen = HashSet::<String>::new();
    for placement in &placements {
        let id = placement.library_id.trim();
        if id.is_empty() {
            return Err(HentaiError::validation("library_id 不能为空"));
        }
        if !existing_ids.contains(id) {
            return Err(HentaiError::validation(format!("Library 不存在: {id}")));
        }
        if !seen.insert(id.to_string()) {
            return Err(HentaiError::validation("Library sidebar 布局含重复库"));
        }
    }
    if seen.len() != existing.len() {
        return Err(HentaiError::validation(
            "Library sidebar 布局必须包含全部 Library",
        ));
    }

    let db = connection()?;
    let txn = db.begin().await.map_err(map_db_err)?;
    for placement in &placements {
        txn.execute(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "UPDATE libraries SET pinned = ?, sidebar_order = ? WHERE library_id = ?",
            [
                sea_orm::Value::Int(Some(if placement.pinned { 1 } else { 0 })),
                sea_orm::Value::Int(Some(placement.sidebar_order)),
                sea_orm::Value::String(Some(Box::new(placement.library_id.trim().to_string()))),
            ],
        ))
        .await
        .map_err(map_db_err)?;
    }
    txn.commit().await.map_err(map_db_err)?;
    list_libraries().await
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
    ensure_local_root_not_nested(root, None, &existing_libs)?;

    let count = existing_libs.len();
    let sidebar_order = next_pinned_sidebar_order(&existing_libs);
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
        pinned: true,
        sidebar_order,
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
        pinned: Set(1),
        sidebar_order: Set(sidebar_order),
        last_successful_sync_at: Set(None),
        last_sync_error: Set(None),
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

    let existing_libs = list_libraries().await?;
    let count = existing_libs.len();
    let sidebar_order = next_pinned_sidebar_order(&existing_libs);
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
        pinned: true,
        sidebar_order,
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
        pinned: Set(1),
        sidebar_order: Set(sidebar_order),
        last_successful_sync_at: Set(None),
        last_sync_error: Set(None),
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
        return Err(HentaiError::validation(
            "仅 Remote library 可更新 WebDAV 根",
        ));
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

pub(crate) async fn update_existing_remote(
    model: libraries::Model,
    root: &str,
    username: &str,
    allow_http: bool,
) -> Result<LibraryDto, HentaiError> {
    if model.kind != KIND_REMOTE {
        return Err(HentaiError::validation(
            "仅 Remote library 可更新 WebDAV 根",
        ));
    }
    let db = connection()?;
    let mut active: libraries::ActiveModel = model.into();
    active.root_path = Set(root.to_string());
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
    crate::probe::delete_snapshots_for_library(&txn, id).await?;
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
            return Err(HentaiError::validation(format!("Library 不存在: {id}")));
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

pub(crate) async fn get_pref(
    db: &sea_orm::DatabaseConnection,
    key: &str,
) -> Result<Option<String>, HentaiError> {
    let row = AppPrefs::find_by_id(key.to_string())
        .one(db)
        .await
        .map_err(map_db_err)?;
    Ok(row.map(|r| r.value).filter(|v| !v.is_empty()))
}

pub(crate) async fn set_current_library_id_inner(
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

pub(crate) async fn load_comic_ids_for_library<C: ConnectionTrait>(
    db: &C,
    library_id: &str,
) -> Result<Vec<String>, HentaiError> {
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT comic_id FROM comics WHERE library_id = ?",
            [sea_orm::Value::String(Some(Box::new(
                library_id.to_string(),
            )))],
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
