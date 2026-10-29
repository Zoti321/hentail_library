mod crud;
mod dto;
mod local_root_update;
mod remote_access;
mod webdav_root;

pub use crud::{
    create_local_library, create_remote_library, delete_library, find_library_by_id,
    get_current_library_id, list_libraries, resolve_browse_library_id,
    set_all_libraries_scan_on_startup, set_current_library_id, update_library_resource_format_categories,
    update_library_settings, update_library_sidebar_layout, update_remote_library,
};
pub use dto::{
    library_id_from_root, parse_resource_format_categories_json, parse_scan_interval, serialize_resource_format_categories,
    LibraryDto, LibrarySidebarPlacement, ScanInterval,
};
pub use local_root_update::update_local_library_root;
pub use remote_access::{
    clear_remote_library_credentials, remote_password_for, resolve_access_for_comic,
    set_remote_library_credentials, RemoteLibraryCredential, ResolvedAccess,
};
pub use webdav_root::{library_id_from_webdav_root, normalize_webdav_root};

use sea_orm::{ActiveModelTrait, EntityTrait, Set};

use crate::comic::now_ms;
use crate::db::{connection, map_db_err};
use crate::entity::{libraries, prelude::*};
use crate::error::HentaiError;

pub async fn record_library_sync_success(library_id: &str) -> Result<(), HentaiError> {
    let db = connection()?;
    let now = now_ms();
    let mut active: libraries::ActiveModel = Libraries::find_by_id(library_id.to_string())
        .one(&db)
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::validation(format!("Library 不存在: {library_id}")))?
        .into();
    active.last_successful_sync_at = Set(Some(now));
    active.last_sync_error = Set(None);
    active.update(&db).await.map_err(map_db_err)?;
    Ok(())
}

pub async fn record_library_sync_failure(
    library_id: &str,
    error_message: &str,
) -> Result<(), HentaiError> {
    let trimmed = error_message.trim();
    if trimmed.is_empty() {
        return Ok(());
    }
    let db = connection()?;
    let mut active: libraries::ActiveModel = Libraries::find_by_id(library_id.to_string())
        .one(&db)
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::validation(format!("Library 不存在: {library_id}")))?
        .into();
    active.last_sync_error = Set(Some(trimmed.to_string()));
    active.update(&db).await.map_err(map_db_err)?;
    Ok(())
}
