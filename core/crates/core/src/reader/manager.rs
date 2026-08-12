use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};

use crate::comic::find_comic_by_id;
use crate::error::HentaiError;
use crate::library::{resolve_access_for_comic, ResolvedAccess};
use crate::resource::{local_access, ResourceAccess};
use crate::runtime::block_on;

use super::backend::{open_backend_with, ReaderBackend};

struct CachedSession {
    normalized_path: String,
    backend: ReaderBackend,
    /// Active acquire count (Flutter open + ephemeral leases).
    ref_count: usize,
    /// Whether the first cache-hit reuse has already been logged for this session.
    reuse_logged: bool,
}

struct SessionStore {
    sessions: HashMap<String, CachedSession>,
    order: Vec<String>,
}

impl SessionStore {
    fn new() -> Self {
        Self {
            sessions: HashMap::new(),
            order: Vec::new(),
        }
    }

    fn touch(&mut self, comic_id: &str) {
        self.order.retain(|id| id != comic_id);
        self.order.push(comic_id.to_string());
    }

    fn remove_session(&mut self, comic_id: &str) -> bool {
        let removed = self.sessions.remove(comic_id).is_some();
        if removed {
            self.order.retain(|id| id != comic_id);
        }
        removed
    }

    /// Evict idle (`ref_count == 0`) sessions until at or under the soft cap.
    /// In-use sessions are never evicted; the store may temporarily exceed [MAX_SESSIONS].
    fn evict_if_needed(&mut self) {
        while self.order.len() > MAX_SESSIONS {
            let Some(oldest_idle) = self
                .order
                .iter()
                .find(|id| {
                    self.sessions
                        .get(id.as_str())
                        .is_some_and(|s| s.ref_count == 0)
                })
                .cloned()
            else {
                tracing::debug!(
                    session_count = self.order.len(),
                    "reader session eviction skipped; all in use"
                );
                break;
            };
            if self.remove_session(&oldest_idle) {
                tracing::debug!(comic_id = %oldest_idle, "reader session evicted");
            }
        }
    }
}

const MAX_SESSIONS: usize = 4;

fn store() -> &'static Mutex<SessionStore> {
    static STORE: OnceLock<Mutex<SessionStore>> = OnceLock::new();
    STORE.get_or_init(|| Mutex::new(SessionStore::new()))
}

/// Ensure a session exists and increment its ref count.
fn acquire_reader(comic_id: &str, path: &str, resource_type: &str) -> Result<(), HentaiError> {
    let access = resolve_access_for_open(comic_id)?;
    acquire_reader_with(access.as_dyn(), comic_id, path, resource_type)
}

fn resolve_access_for_open(comic_id: &str) -> Result<ResolvedAccess, HentaiError> {
    match block_on(find_comic_by_id(comic_id)) {
        Ok(Some(comic)) => resolve_access_for_comic(&comic),
        Ok(None) => Ok(ResolvedAccess::Local(local_access())),
        Err(err) if err.code == crate::error::HentaiErrorCode::DbInitFailed => {
            // Unit tests / early boot: no DB yet → Local FS.
            Ok(ResolvedAccess::Local(local_access()))
        }
        Err(err) => Err(err),
    }
}

fn acquire_reader_with(
    access: &dyn ResourceAccess,
    comic_id: &str,
    path: &str,
    resource_type: &str,
) -> Result<(), HentaiError> {
    let normalized_path = super::backend::normalize_reader_location_for_session(path);
    let mut store = store()
        .lock()
        .map_err(|e| HentaiError::validation(e.to_string()))?;

    if let Some(existing) = store.sessions.get(comic_id) {
        if existing.normalized_path == normalized_path {
            let existing = store.sessions.get_mut(comic_id).expect("session exists");
            existing.ref_count = existing.ref_count.saturating_add(1);
            if !existing.reuse_logged {
                existing.reuse_logged = true;
                tracing::debug!(comic_id, "reader session reused");
            }
            store.touch(comic_id);
            return Ok(());
        }
        if existing.ref_count > 0 {
            return Err(HentaiError::reader_kind_mismatch(format!(
                "阅读会话仍在使用中，无法切换路径: {comic_id}"
            )));
        }
        store.remove_session(comic_id);
    }

    // Release the store lock while opening the backend (can be slow / I/O).
    drop(store);
    let backend = open_backend_with(access, path, resource_type)?;
    let mut store = self::store()
        .lock()
        .map_err(|e| HentaiError::validation(e.to_string()))?;

    // Another acquire may have won the race; reuse if path matches.
    if let Some(existing) = store.sessions.get(comic_id) {
        if existing.normalized_path == normalized_path {
            let existing = store.sessions.get_mut(comic_id).expect("session exists");
            existing.ref_count = existing.ref_count.saturating_add(1);
            if !existing.reuse_logged {
                existing.reuse_logged = true;
                tracing::debug!(comic_id, "reader session reused");
            }
            store.touch(comic_id);
            return Ok(());
        }
        if existing.ref_count > 0 {
            return Err(HentaiError::reader_kind_mismatch(format!(
                "阅读会话仍在使用中，无法切换路径: {comic_id}"
            )));
        }
        store.remove_session(comic_id);
    }

    store.sessions.insert(
        comic_id.to_string(),
        CachedSession {
            normalized_path,
            backend,
            ref_count: 1,
            reuse_logged: false,
        },
    );
    store.touch(comic_id);
    store.evict_if_needed();
    tracing::info!(comic_id, resource_type, "reader opened");
    Ok(())
}

fn release_reader(comic_id: &str) {
    let Ok(mut store) = store().lock() else {
        return;
    };
    let Some(session) = store.sessions.get_mut(comic_id) else {
        return;
    };
    session.ref_count = session.ref_count.saturating_sub(1);
    if session.ref_count == 0 {
        store.remove_session(comic_id);
        tracing::debug!(comic_id, "reader session released");
    }
}

/// Flutter / explicit open: acquire a session (create or reuse).
#[tracing::instrument(err, fields(comic_id, resource_type, path))]
pub fn open_reader(comic_id: &str, path: &str, resource_type: &str) -> Result<(), HentaiError> {
    acquire_reader(comic_id, path, resource_type)
}

/// Test / injected-access open (FakeResourceAccess, etc.).
pub fn open_reader_with(
    access: &dyn ResourceAccess,
    comic_id: &str,
    path: &str,
    resource_type: &str,
) -> Result<(), HentaiError> {
    acquire_reader_with(access, comic_id, path, resource_type)
}

/// Cold-path helper: acquire → run → release (drops session when ref hits 0).
pub fn with_ephemeral_reader<T>(
    comic_id: &str,
    path: &str,
    resource_type: &str,
    f: impl FnOnce() -> Result<T, HentaiError>,
) -> Result<T, HentaiError> {
    acquire_reader(comic_id, path, resource_type)?;
    let result = f();
    release_reader(comic_id);
    result
}

pub fn with_session<T>(
    comic_id: &str,
    f: impl FnOnce(&ReaderBackend) -> Result<T, HentaiError>,
) -> Result<T, HentaiError> {
    let store = store()
        .lock()
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    let Some(session) = store.sessions.get(comic_id) else {
        return Err(HentaiError::reader_session_not_open(comic_id));
    };
    f(&session.backend)
}

/// Force-remove a session regardless of ref count (leave reader / cancel).
pub fn close_reader(comic_id: &str) {
    let Ok(mut store) = store().lock() else {
        return;
    };
    if store.remove_session(comic_id) {
        tracing::info!(comic_id, "reader closed");
    }
}

/// Force-clear all sessions (library sync / delete).
pub fn clear_reader_sessions() {
    let Ok(mut store) = store().lock() else {
        return;
    };
    let count = store.sessions.len();
    store.sessions.clear();
    store.order.clear();
    if count > 0 {
        tracing::info!(count, "reader sessions cleared");
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::error::HentaiErrorCode;
    use std::io::Write;

    fn write_tiny_cbz(dir: &std::path::Path, name: &str) -> String {
        let zip_path = dir.join(name);
        let file = std::fs::File::create(&zip_path).expect("create");
        let mut zip = zip::ZipWriter::new(file);
        let options = zip::write::SimpleFileOptions::default()
            .compression_method(zip::CompressionMethod::Stored);
        zip.start_file("001.jpg", options).expect("start");
        zip.write_all(b"page").expect("write");
        zip.finish().expect("finish");
        zip_path.to_string_lossy().to_string()
    }

    #[test]
    fn load_without_open_returns_session_not_open() {
        let err = with_session("missing", |_| Ok(())).expect_err("expected error");
        assert_eq!(err.code, HentaiErrorCode::ReaderSessionNotOpen);
    }

    #[test]
    fn close_then_with_session_returns_session_not_open() {
        let temp = tempfile::tempdir().expect("tempdir");
        let path = write_tiny_cbz(temp.path(), "a.cbz");
        open_reader("mgr-close-1", &path, "cbz").expect("open");
        close_reader("mgr-close-1");
        let err = with_session("mgr-close-1", |_| Ok(())).expect_err("expected error");
        assert_eq!(err.code, HentaiErrorCode::ReaderSessionNotOpen);
    }

    #[test]
    fn ephemeral_does_not_close_active_reader_session() {
        let temp = tempfile::tempdir().expect("tempdir");
        let path = write_tiny_cbz(temp.path(), "a.cbz");
        open_reader("mgr-eph-active", &path, "cbz").expect("open");
        with_ephemeral_reader("mgr-eph-active", &path, "cbz", || {
            with_session("mgr-eph-active", |_| Ok(()))
        })
        .expect("ephemeral");
        with_session("mgr-eph-active", |_| Ok(())).expect("reader session still open");
        close_reader("mgr-eph-active");
        let err = with_session("mgr-eph-active", |_| Ok(())).expect_err("closed");
        assert_eq!(err.code, HentaiErrorCode::ReaderSessionNotOpen);
    }

    #[test]
    fn ephemeral_alone_releases_session() {
        let temp = tempfile::tempdir().expect("tempdir");
        let path = write_tiny_cbz(temp.path(), "a.cbz");
        with_ephemeral_reader("mgr-eph-alone", &path, "cbz", || {
            with_session("mgr-eph-alone", |_| Ok(()))
        })
        .expect("ephemeral");
        let err = with_session("mgr-eph-alone", |_| Ok(())).expect_err("should be released");
        assert_eq!(err.code, HentaiErrorCode::ReaderSessionNotOpen);
    }

    #[test]
    fn path_change_while_in_use_is_rejected() {
        let temp = tempfile::tempdir().expect("tempdir");
        let path_a = write_tiny_cbz(temp.path(), "a.cbz");
        let path_b = write_tiny_cbz(temp.path(), "b.cbz");
        open_reader("mgr-path-change", &path_a, "cbz").expect("open a");
        let err = open_reader("mgr-path-change", &path_b, "cbz").expect_err("path change");
        assert_eq!(err.code, HentaiErrorCode::ReaderKindMismatch);
        close_reader("mgr-path-change");
    }
}
