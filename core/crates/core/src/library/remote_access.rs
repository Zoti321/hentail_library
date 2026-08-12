//! Resolve [ResourceAccess] for a Comic + in-memory Remote Basic credentials.

use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};

use crate::comic::ComicDto;
use crate::error::HentaiError;
use crate::resource::{local_access, LocalResourceAccess, ResourceAccess, WebDavResourceAccess};
use crate::runtime::block_on;

use super::find_library_by_id;

/// Basic password for one Remote library (never written to SQLite).
#[derive(Debug, Clone)]
pub struct RemoteLibraryCredential {
    pub library_id: String,
    pub password: String,
}

fn remote_passwords() -> &'static Mutex<HashMap<String, String>> {
    static REMOTE_PASSWORDS: OnceLock<Mutex<HashMap<String, String>>> = OnceLock::new();
    REMOTE_PASSWORDS.get_or_init(|| Mutex::new(HashMap::new()))
}

/// Replace/merge process-wide Remote Basic passwords (never persisted).
pub fn set_remote_library_credentials(credentials: Vec<RemoteLibraryCredential>) {
    let Ok(mut map) = remote_passwords().lock() else {
        return;
    };
    for cred in credentials {
        if cred.password.is_empty() {
            map.remove(&cred.library_id);
        } else {
            map.insert(cred.library_id, cred.password);
        }
    }
}

pub fn clear_remote_library_credentials() {
    if let Ok(mut map) = remote_passwords().lock() {
        map.clear();
    }
}

pub fn remote_password_for(library_id: &str) -> Option<String> {
    remote_passwords()
        .lock()
        .ok()
        .and_then(|map| map.get(library_id).cloned())
}

/// Owned access handle — Local borrows the process singleton; Remote owns the client.
pub enum ResolvedAccess {
    Local(&'static LocalResourceAccess),
    Remote(WebDavResourceAccess),
}

impl ResolvedAccess {
    pub fn as_dyn(&self) -> &dyn ResourceAccess {
        match self {
            Self::Local(access) => *access,
            Self::Remote(access) => access,
        }
    }
}

/// Look up Library for [comic] and build Local or WebDAV access.
pub fn resolve_access_for_comic(comic: &ComicDto) -> Result<ResolvedAccess, HentaiError> {
    if comic.library_id.trim().is_empty() {
        return Ok(ResolvedAccess::Local(local_access()));
    }
    let library = block_on(find_library_by_id(&comic.library_id))?.ok_or_else(|| {
        HentaiError::validation(format!("漫画所属库不存在: {}", comic.library_id))
    })?;
    if library.kind != "remote" {
        return Ok(ResolvedAccess::Local(local_access()));
    }
    let Some(password) = remote_password_for(&library.library_id).filter(|p| !p.is_empty()) else {
        return Err(HentaiError::remote_auth_failed(format!(
            "缺少远程库凭证: {}",
            library.root_path
        )));
    };
    let access =
        WebDavResourceAccess::connect(&library.root_path, &library.username, &password)?;
    Ok(ResolvedAccess::Remote(access))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn credentials_roundtrip_and_clear() {
        clear_remote_library_credentials();
        set_remote_library_credentials(vec![RemoteLibraryCredential {
            library_id: "lib-a".into(),
            password: "secret".into(),
        }]);
        assert_eq!(remote_password_for("lib-a").as_deref(), Some("secret"));
        clear_remote_library_credentials();
        assert!(remote_password_for("lib-a").is_none());
    }
}
