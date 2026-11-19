use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::{Arc, Mutex, OnceLock, Weak};

use crate::comic::find_comic_by_id;
use crate::error::HentaiError;
use crate::library::{resolve_access_for_comic, ResolvedAccess};
use crate::resource::{local_access, ResourceAccess, ResourceStat};
use crate::runtime::block_on;

use super::backend::{open_backend_with, ReaderBackend};
use super::cache::ReaderSourceVersion;

struct CachedSession {
    _lifetime: Arc<()>,
    identity: Arc<()>,
    publication: Arc<Mutex<()>>,
    normalized_path: String,
    resource_type: String,
    backend: Arc<Mutex<ReaderBackend>>,
    source_stat: ResourceStat,
    local_source: Option<PathBuf>,
    /// Active acquire count (Flutter open + ephemeral leases).
    ref_count: usize,
    /// Whether the first cache-hit reuse has already been logged for this session.
    reuse_logged: bool,
}

impl CachedSession {
    fn read(&self, comic_id: &str) -> ReaderSessionRead {
        ReaderSessionRead {
            comic_id: comic_id.to_string(),
            identity: self.identity.clone(),
            publication: self.publication.clone(),
            path: self.normalized_path.clone(),
            resource_type: self.resource_type.clone(),
            source_version: ReaderSourceVersion::from_stat(&self.source_stat),
            source_stat: self.source_stat.clone(),
            local_source: self.local_source.clone(),
        }
    }
}

#[derive(Debug)]
pub struct ReaderSessionRead {
    pub(super) comic_id: String,
    identity: Arc<()>,
    publication: Arc<Mutex<()>>,
    pub(super) path: String,
    pub(super) resource_type: String,
    pub(super) source_version: Option<ReaderSourceVersion>,
    pub(super) source_stat: ResourceStat,
    local_source: Option<PathBuf>,
}

impl ReaderSessionRead {
    pub fn capture(comic_id: &str) -> Result<Self, HentaiError> {
        let store = store()
            .lock()
            .map_err(|error| HentaiError::validation(error.to_string()))?;
        let session = store
            .sessions
            .get(comic_id)
            .ok_or_else(|| HentaiError::reader_session_not_open(comic_id))?;
        Ok(session.read(comic_id))
    }

    pub(super) fn with_backend<T>(
        &self,
        read: impl FnOnce(&ReaderBackend) -> Result<T, HentaiError>,
    ) -> Result<T, HentaiError> {
        self.ensure_current()?;
        let backend = {
            let store = store()
                .lock()
                .map_err(|error| HentaiError::validation(error.to_string()))?;
            let session = self.current_session(&store)?;
            session.backend.clone()
        };
        let result = {
            let backend = backend
                .lock()
                .map_err(|error| HentaiError::validation(error.to_string()))?;
            self.ensure_current()?;
            read(&backend)?
        };
        self.ensure_current()?;
        Ok(result)
    }

    pub(super) fn with_current_io<T>(
        &self,
        operation: impl FnOnce() -> Result<T, HentaiError>,
    ) -> Result<T, HentaiError> {
        let _publication = self
            .publication
            .lock()
            .map_err(|error| HentaiError::validation(error.to_string()))?;
        self.ensure_current()?;
        let result = operation()?;
        self.ensure_current()?;
        Ok(result)
    }

    fn current_session<'a>(
        &self,
        store: &'a SessionStore,
    ) -> Result<&'a CachedSession, HentaiError> {
        store
            .sessions
            .get(&self.comic_id)
            .filter(|session| Arc::ptr_eq(&session.identity, &self.identity))
            .ok_or_else(|| HentaiError::reader_session_not_open(&self.comic_id))
    }

    pub(super) fn ensure_current(&self) -> Result<(), HentaiError> {
        {
            let store = store()
                .lock()
                .map_err(|error| HentaiError::validation(error.to_string()))?;
            self.current_session(&store)?;
        }
        self.validate_source()
    }

    fn validate_source(&self) -> Result<(), HentaiError> {
        if let Some(path) = &self.local_source {
            if local_access().stat(&path.to_string_lossy())?.as_ref() != Some(&self.source_stat) {
                return Err(HentaiError::reader_invalid_content(
                    "源文件已改变，请重新打开阅读会话",
                ));
            }
        }
        Ok(())
    }
}

struct SessionStore {
    sessions: HashMap<String, CachedSession>,
    lifetimes: HashMap<String, Weak<()>>,
    order: Vec<String>,
}

impl SessionStore {
    fn new() -> Self {
        Self {
            sessions: HashMap::new(),
            lifetimes: HashMap::new(),
            order: Vec::new(),
        }
    }

    fn capture_lifetime(&mut self, comic_id: &str) -> Arc<()> {
        let lifetime = self.lifetimes.entry(comic_id.to_string()).or_default();
        if let Some(identity) = lifetime.upgrade() {
            return identity;
        }
        let identity = Arc::new(());
        *lifetime = Arc::downgrade(&identity);
        identity
    }

    fn is_current(&self, comic_id: &str, identity: &Arc<()>) -> bool {
        self.lifetimes
            .get(comic_id)
            .and_then(Weak::upgrade)
            .is_some_and(|current| Arc::ptr_eq(&current, identity))
    }

    fn close(&mut self, comic_id: &str) -> bool {
        self.lifetimes.remove(comic_id);
        self.remove_session(comic_id)
    }

    fn clear(&mut self) {
        self.lifetimes.clear();
        self.sessions.clear();
        self.order.clear();
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
    /// In-use sessions are never evicted; the store may temporarily exceed [`MAX_SESSIONS`].
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

// Capture before access checks and backend I/O, so close also invalidates pending opens.
fn capture_open_lifetime(comic_id: &str) -> Result<Arc<()>, HentaiError> {
    let mut store = store()
        .lock()
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    Ok(store.capture_lifetime(comic_id))
}

fn acquire_reader(
    comic_id: &str,
    path: &str,
    resource_type: &str,
    identity: Arc<()>,
) -> Result<ReaderSessionRead, HentaiError> {
    let access = resolve_access_for_open(comic_id)?;
    acquire_reader_with(access.as_dyn(), comic_id, path, resource_type, identity)
}

fn resolve_access_for_open(comic_id: &str) -> Result<ResolvedAccess, HentaiError> {
    match block_on(find_comic_by_id(comic_id)) {
        Ok(Some(comic)) => resolve_access_for_comic(&comic),
        Ok(None) => Ok(ResolvedAccess::Local(local_access())),
        Err(err) if is_db_unavailable_for_open(&err) => {
            // No usable DB yet, or connection became invalid (e.g. temp DB
            // deleted by parallel tests) → Local FS path open.
            Ok(ResolvedAccess::Local(local_access()))
        }
        Err(err) => Err(err),
    }
}

fn is_db_unavailable_for_open(err: &HentaiError) -> bool {
    match err.code {
        crate::error::HentaiErrorCode::DbInitFailed => true,
        crate::error::HentaiErrorCode::DbQueryFailed => {
            let lower = err.message.to_ascii_lowercase();
            lower.contains("unable to open database file") || lower.contains("(code: 14)")
        }
        _ => false,
    }
}

fn acquire_reader_with(
    access: &dyn ResourceAccess,
    comic_id: &str,
    path: &str,
    resource_type: &str,
    lifetime: Arc<()>,
) -> Result<ReaderSessionRead, HentaiError> {
    let normalized_path = super::backend::normalize_reader_location_for_session(path);
    let mut store = store()
        .lock()
        .map_err(|e| HentaiError::validation(e.to_string()))?;

    if !store.is_current(comic_id, &lifetime) {
        return Err(HentaiError::reader_session_not_open(comic_id));
    }

    match store.sessions.get_mut(comic_id) {
        Some(existing) if existing.normalized_path == normalized_path => {
            existing.ref_count = existing.ref_count.saturating_add(1);
            if !existing.reuse_logged {
                existing.reuse_logged = true;
                tracing::debug!(comic_id, "reader session reused");
            }
            let read = existing.read(comic_id);
            store.touch(comic_id);
            return Ok(read);
        }
        Some(existing) if existing.ref_count > 0 => {
            return Err(HentaiError::reader_kind_mismatch(format!(
                "阅读会话仍在使用中，无法切换路径: {comic_id}"
            )));
        }
        Some(_) => {
            store.remove_session(comic_id);
        }
        None => {}
    }

    // Release the store lock while opening the backend (can be slow / I/O).
    drop(store);
    let backend = open_backend_with(access, path, resource_type)?;
    let mut store = self::store()
        .lock()
        .map_err(|e| HentaiError::validation(e.to_string()))?;

    if !store.is_current(comic_id, &lifetime) {
        return Err(HentaiError::reader_session_not_open(comic_id));
    }

    // Another acquire may have won the race; reuse if path matches.
    match store.sessions.get_mut(comic_id) {
        Some(existing) if existing.normalized_path == normalized_path => {
            existing.ref_count = existing.ref_count.saturating_add(1);
            if !existing.reuse_logged {
                existing.reuse_logged = true;
                tracing::debug!(comic_id, "reader session reused");
            }
            let read = existing.read(comic_id);
            store.touch(comic_id);
            return Ok(read);
        }
        Some(existing) if existing.ref_count > 0 => {
            return Err(HentaiError::reader_kind_mismatch(format!(
                "阅读会话仍在使用中，无法切换路径: {comic_id}"
            )));
        }
        Some(_) => {
            store.remove_session(comic_id);
        }
        None => {}
    }

    let session = CachedSession {
        _lifetime: lifetime,
        identity: Arc::new(()),
        publication: Arc::new(Mutex::new(())),
        normalized_path,
        resource_type: resource_type.to_string(),
        backend: Arc::new(Mutex::new(backend.backend)),
        source_stat: backend.source_stat,
        local_source: backend.local_source,
        ref_count: 1,
        reuse_logged: false,
    };
    let read = session.read(comic_id);
    store.sessions.insert(comic_id.to_string(), session);
    store.touch(comic_id);
    store.evict_if_needed();
    tracing::info!(comic_id, resource_type, "reader opened");
    Ok(read)
}

fn release_reader(comic_id: &str, identity: &Arc<()>) {
    let Ok(mut store) = store().lock() else {
        return;
    };
    let Some(session) = store.sessions.get_mut(comic_id) else {
        return;
    };
    if !Arc::ptr_eq(&session.identity, identity) {
        return;
    }
    session.ref_count = session.ref_count.saturating_sub(1);
    if session.ref_count == 0 {
        store.remove_session(comic_id);
        tracing::debug!(comic_id, "reader session released");
    }
}

struct EphemeralReaderLease<'a> {
    comic_id: &'a str,
    identity: Arc<()>,
}

impl Drop for EphemeralReaderLease<'_> {
    fn drop(&mut self) {
        release_reader(self.comic_id, &self.identity);
    }
}

/// Flutter / explicit open: acquire a session (create or reuse).
#[tracing::instrument(err, fields(comic_id, resource_type, path))]
pub fn open_reader(comic_id: &str, path: &str, resource_type: &str) -> Result<(), HentaiError> {
    let identity = capture_open_lifetime(comic_id)?;
    match block_on(crate::comic::is_comic_trashed(comic_id)) {
        Ok(true) => return Err(HentaiError::comic_trashed(comic_id)),
        Ok(false) => {}
        Err(err) if is_db_unavailable_for_open(&err) => {}
        Err(err) => return Err(err),
    }
    acquire_reader(comic_id, path, resource_type, identity).map(|_| ())
}

/// Test / injected-access open (`FakeResourceAccess`, etc.).
pub fn open_reader_with(
    access: &dyn ResourceAccess,
    comic_id: &str,
    path: &str,
    resource_type: &str,
) -> Result<(), HentaiError> {
    let identity = capture_open_lifetime(comic_id)?;
    acquire_reader_with(access, comic_id, path, resource_type, identity).map(|_| ())
}

/// Cold-path helper: acquire → run → release (drops session when ref hits 0).
pub fn with_ephemeral_reader<T>(
    comic_id: &str,
    path: &str,
    resource_type: &str,
    f: impl FnOnce(&ReaderSessionRead) -> Result<T, HentaiError>,
) -> Result<T, HentaiError> {
    let identity = capture_open_lifetime(comic_id)?;
    let read = acquire_reader(comic_id, path, resource_type, identity)?;
    let _lease = EphemeralReaderLease {
        comic_id,
        identity: read.identity.clone(),
    };
    f(&read)
}

/// Returns `(normalized_path, resource_type)` for an open session.
pub fn session_path_and_type(comic_id: &str) -> Result<(String, String), HentaiError> {
    let store = store()
        .lock()
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    let Some(session) = store.sessions.get(comic_id) else {
        return Err(HentaiError::reader_session_not_open(comic_id));
    };
    Ok((
        session.normalized_path.clone(),
        session.resource_type.clone(),
    ))
}

/// Force-remove a session regardless of ref count (leave reader / cancel).
pub fn close_reader(comic_id: &str) {
    let Ok(mut store) = store().lock() else {
        return;
    };
    let publication = store
        .sessions
        .get(comic_id)
        .map(|session| session.publication.clone());
    let removed = store.close(comic_id);
    drop(store);
    if let Some(publication) = publication {
        let _guard = publication.lock();
    }
    if removed {
        tracing::info!(comic_id, "reader closed");
    }
}

/// Force-clear all sessions (library sync / delete).
pub fn clear_reader_sessions() {
    let Ok(mut store) = store().lock() else {
        return;
    };
    let count = store.sessions.len();
    let publications: Vec<_> = store
        .sessions
        .values()
        .map(|session| session.publication.clone())
        .collect();
    store.clear();
    drop(store);
    for publication in publications {
        let _guard = publication.lock();
    }
    if count > 0 {
        tracing::info!(count, "reader sessions cleared");
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::error::HentaiErrorCode;
    use crate::resource::FakeResourceAccess;
    use std::io::Cursor;
    use std::io::Write;

    fn with_session<T>(
        comic_id: &str,
        f: impl FnOnce(&ReaderBackend) -> Result<T, HentaiError>,
    ) -> Result<T, HentaiError> {
        ReaderSessionRead::capture(comic_id)?.with_backend(f)
    }

    #[test]
    fn blocked_decode_allows_other_sessions_and_rejects_closed_completion() {
        use std::sync::mpsc;
        use std::time::Duration;
        let access = fake_cbz();
        let a = "decode_isolation_a";
        let b = "decode_isolation_b";
        open_reader_with(&access, a, "/lease/comic.cbz", "cbz").unwrap();
        let read = ReaderSessionRead::capture(a).unwrap();
        let (entered_tx, entered_rx) = mpsc::channel();
        let (release_tx, release_rx) = mpsc::channel();
        let worker = std::thread::spawn(move || {
            read.with_backend(|_| {
                entered_tx.send(()).unwrap();
                release_rx.recv_timeout(Duration::from_secs(10)).unwrap();
                Ok(vec![42])
            })
        });
        entered_rx.recv_timeout(Duration::from_secs(10)).unwrap();
        let (done_tx, done_rx) = mpsc::channel();
        let other = std::thread::spawn(move || {
            open_reader_with(&access, b, "/lease/comic.cbz", "cbz").unwrap();
            let bytes =
                super::super::open::load_page_bytes(&ReaderSessionRead::capture(b).unwrap(), 0)
                    .unwrap();
            close_reader(b);
            close_reader(a);
            open_reader_with(&access, a, "/lease/reopened.cbz", "cbz").unwrap();
            done_tx.send(bytes).unwrap();
        });
        let completed = done_rx.recv_timeout(Duration::from_secs(5));
        release_tx.send(()).unwrap();
        other.join().unwrap();
        assert_eq!(completed.unwrap(), b"page");
        assert_eq!(
            worker.join().unwrap().unwrap_err().code,
            HentaiErrorCode::ReaderSessionNotOpen
        );
        let bytes = super::super::open::load_page_bytes(&ReaderSessionRead::capture(a).unwrap(), 0)
            .unwrap();
        assert_eq!(bytes, b"replacement-page");
        close_reader(a);
    }

    fn fake_cbz() -> FakeResourceAccess {
        let mut access = FakeResourceAccess::new();
        access.insert_file("/lease/comic.cbz", fake_archive(b"page"));
        access.insert_file("/lease/reopened.cbz", fake_archive(b"replacement-page"));
        access
    }

    fn fake_archive(page: &[u8]) -> Vec<u8> {
        let mut bytes = Vec::new();
        {
            let mut archive = zip::ZipWriter::new(Cursor::new(&mut bytes));
            archive
                .start_file("001.jpg", zip::write::SimpleFileOptions::default())
                .unwrap();
            archive.write_all(page).unwrap();
            archive.finish().unwrap();
        }
        bytes
    }

    #[test]
    fn unknown_source_time_skips_persistent_cache_for_all_page_consumers() {
        use crate::reader::{
            load_reader_page, prefetch_reader_pages, ReaderPageCacheRequest, ReaderPageRead,
        };
        let location = "https://example.test/no-time.cbz";
        let comic_id = "source_unknown_time";
        let mut access = FakeResourceAccess::new();
        access.insert_file(location, fake_archive(b"uncached-page"));
        access.set_modified_ms(location, 0);
        open_reader_with(&access, comic_id, location, "cbz").unwrap();
        let session = ReaderSessionRead::capture(comic_id).unwrap();
        assert!(session.source_version.is_none());
        let page = load_reader_page(&ReaderPageRead::capture(comic_id).unwrap(), 0).unwrap();
        assert!(
            matches!(page, crate::reader::ReaderPageDto::Bytes { data } if data == b"uncached-page")
        );
        let bytes = crate::reader::load_page_image_bytes(comic_id, location, "cbz", 0).unwrap();
        assert_eq!(bytes, b"uncached-page");
        prefetch_reader_pages(ReaderPageCacheRequest::begin(comic_id), &session, &[0]).unwrap();
        close_reader(comic_id);
    }

    #[test]
    fn local_source_change_rejects_decode_and_cached_page_lookup() {
        let root = tempfile::tempdir().unwrap().keep();
        let path = write_tiny_cbz(&root, "mutable.cbz");
        let comic_id = "source_local_changed";
        open_reader_with(local_access(), comic_id, &path, "cbz").unwrap();
        let read = ReaderSessionRead::capture(comic_id).unwrap();
        let page = crate::reader::ReaderPageRead::capture(comic_id).unwrap();
        std::fs::write(&path, b"replacement-with-different-size").unwrap();
        assert_eq!(
            super::super::open::load_page_bytes(&read, 0)
                .unwrap_err()
                .code,
            HentaiErrorCode::ReaderInvalidContent
        );
        assert_eq!(
            crate::reader::load_reader_page(&page, 0).unwrap_err().code,
            HentaiErrorCode::ReaderInvalidContent
        );
        close_reader(comic_id);
    }

    #[test]
    fn local_source_change_during_decode_rejects_the_completed_bytes() {
        let root = tempfile::tempdir().unwrap().keep();
        let path = write_tiny_cbz(&root, "mutable.cbz");
        let comic_id = "source_changed_while_decoding";
        open_reader_with(local_access(), comic_id, &path, "cbz").unwrap();
        let read = ReaderSessionRead::capture(comic_id).unwrap();
        let result = read.with_backend(|_| {
            std::fs::write(&path, b"replacement-with-different-size").unwrap();
            Ok(vec![42])
        });
        assert_eq!(
            result.unwrap_err().code,
            HentaiErrorCode::ReaderInvalidContent
        );
        close_reader(comic_id);
    }

    #[test]
    fn path_bound_sevenz_rejects_a_changed_source_before_reopening_it() {
        // Prebuilt fixture: sevenz_rust's LZMA encoder hits Stacked Borrows UB under Miri.
        const CB7: &[u8] = include_bytes!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tests/fixtures/snapshot_page.cb7"
        ));
        let root = tempfile::tempdir().unwrap().keep();
        let path = root.join("mutable.cb7");
        std::fs::write(&path, CB7).unwrap();
        let location = path.to_string_lossy();
        let comic_id = "source_sevenz_changed";
        open_reader_with(local_access(), comic_id, &location, "cb7").unwrap();
        let read = ReaderSessionRead::capture(comic_id).unwrap();
        assert_eq!(
            super::super::open::load_page_bytes(&read, 0).unwrap(),
            b"snapshot-page"
        );
        std::fs::write(&path, b"changed-7z-source").unwrap();
        let error = super::super::open::load_page_bytes(&read, 0).unwrap_err();
        assert!(error.message.contains("源文件已改变"));
        close_reader(comic_id);
    }

    #[test]
    fn directory_list_remains_a_session_snapshot_when_children_change() {
        let root = tempfile::tempdir().unwrap().keep();
        std::fs::write(root.join("1.jpg"), b"page-one").unwrap();
        let comic_id = "source_directory_snapshot";
        open_reader_with(local_access(), comic_id, &root.to_string_lossy(), "dir").unwrap();
        let read = ReaderSessionRead::capture(comic_id).unwrap();
        std::fs::write(root.join("2.jpg"), b"page-two").unwrap();
        assert!(read.source_version.is_none());
        assert_eq!(
            super::super::open::load_page_list(&read)
                .unwrap()
                .page_count,
            1
        );
        close_reader(comic_id);
    }

    #[test]
    fn old_ephemeral_read_cannot_use_reopened_backend() {
        let access = fake_cbz();
        let comic_id = "read_identity_replacement";
        let path = "/lease/comic.cbz";
        open_reader_with(&access, comic_id, path, "cbz").unwrap();
        let result = with_ephemeral_reader(comic_id, path, "cbz", |read| {
            close_reader(comic_id);
            open_reader_with(&access, comic_id, "/lease/reopened.cbz", "cbz")?;
            super::super::open::load_page_bytes(read, 0)
        });
        assert_eq!(
            result.unwrap_err().code,
            HentaiErrorCode::ReaderSessionNotOpen
        );
        with_session(comic_id, |_| Ok(())).unwrap();
        close_reader(comic_id);
    }

    #[test]
    fn old_read_snapshots_reject_same_path_and_different_path_replacements() {
        use crate::reader::{load_page_bytes, load_page_list, load_reader_page, ReaderPageRead};
        for (comic_id, replacement_path) in [
            ("bound_read_same_path", "/lease/comic.cbz"),
            ("bound_read_new_path", "/lease/reopened.cbz"),
        ] {
            let access = fake_cbz();
            open_reader_with(&access, comic_id, "/lease/comic.cbz", "cbz").unwrap();
            let old = ReaderSessionRead::capture(comic_id).unwrap();
            let old_page = ReaderPageRead::capture(comic_id).unwrap();
            let original_path = old.path.clone();
            close_reader(comic_id);
            let mut replacement = fake_cbz();
            replacement.insert_file(replacement_path, fake_archive(b"new-backend"));
            open_reader_with(&replacement, comic_id, replacement_path, "cbz").unwrap();
            assert_eq!(old.path, original_path);
            assert_eq!(
                load_page_bytes(&old, 0).unwrap_err().code,
                HentaiErrorCode::ReaderSessionNotOpen
            );
            assert_eq!(
                load_page_list(&old).unwrap_err().code,
                HentaiErrorCode::ReaderSessionNotOpen
            );
            assert_eq!(
                load_reader_page(&old_page, 0).unwrap_err().code,
                HentaiErrorCode::ReaderSessionNotOpen
            );
            let current = ReaderSessionRead::capture(comic_id).unwrap();
            assert_eq!(load_page_bytes(&current, 0).unwrap(), b"new-backend");
            close_reader(comic_id);
        }
    }

    #[test]
    fn new_backend_in_same_open_lifetime_does_not_revalidate_old_reads() {
        let access = fake_cbz();
        let comic_id = "bound_read_same_lifetime";
        let lifetime = capture_open_lifetime(comic_id).unwrap();
        let old = acquire_reader_with(
            &access,
            comic_id,
            "/lease/comic.cbz",
            "cbz",
            lifetime.clone(),
        )
        .unwrap();
        let pending = capture_open_lifetime(comic_id).unwrap();
        assert!(Arc::ptr_eq(&lifetime, &pending));
        release_reader(comic_id, &old.identity);
        let current =
            acquire_reader_with(&access, comic_id, "/lease/reopened.cbz", "cbz", pending).unwrap();
        assert_eq!(
            super::super::open::load_page_bytes(&old, 0)
                .unwrap_err()
                .code,
            HentaiErrorCode::ReaderSessionNotOpen
        );
        assert_eq!(
            super::super::open::load_page_bytes(&current, 0).unwrap(),
            b"replacement-page"
        );
        release_reader(comic_id, &current.identity);
    }

    #[test]
    fn prefetch_cannot_pair_one_comics_cache_with_another_session() {
        let access = fake_cbz();
        let comic_id = "bound_prefetch_mismatch";
        open_reader_with(&access, comic_id, "/lease/comic.cbz", "cbz").unwrap();
        let read = ReaderSessionRead::capture(comic_id).unwrap();
        let cache = crate::reader::ReaderPageCacheRequest::begin("another-comic");
        let error = crate::reader::prefetch_reader_pages(cache, &read, &[0]).unwrap_err();
        assert_eq!(error.code, HentaiErrorCode::ReaderInvalidContent);
        close_reader(comic_id);
    }

    struct ReaderChangeDuringOpen {
        access: FakeResourceAccess,
        comic_id: &'static str,
        close: bool,
        reopen: bool,
        fired: std::sync::atomic::AtomicBool,
    }

    impl ResourceAccess for ReaderChangeDuringOpen {
        fn local_path(&self, location: &str) -> Option<PathBuf> {
            self.access.local_path(location)
        }

        fn list(&self, location: &str) -> Result<Vec<crate::resource::ResourceEntry>, HentaiError> {
            self.access.list(location)
        }

        fn stat(
            &self,
            location: &str,
        ) -> Result<Option<crate::resource::ResourceStat>, HentaiError> {
            if !self.fired.swap(true, std::sync::atomic::Ordering::SeqCst) {
                if self.close {
                    close_reader(self.comic_id);
                }
                if self.reopen {
                    open_reader_with(&self.access, self.comic_id, location, "cbz")?;
                }
            }
            self.access.stat(location)
        }

        fn open_stream(
            &self,
            location: &str,
        ) -> Result<crate::resource::ResourceStream, HentaiError> {
            self.access.open_stream(location)
        }
    }

    #[test]
    fn close_during_backend_open_cancels_completion() {
        let access = ReaderChangeDuringOpen {
            access: fake_cbz(),
            comic_id: "open_cancel_during_backend",
            close: true,
            reopen: false,
            fired: std::sync::atomic::AtomicBool::new(false),
        };
        let result = open_reader_with(&access, access.comic_id, "/lease/comic.cbz", "cbz");
        assert_eq!(
            result.unwrap_err().code,
            HentaiErrorCode::ReaderSessionNotOpen
        );
        assert!(session_path_and_type(access.comic_id).is_err());
    }

    #[test]
    fn close_then_reopen_during_backend_open_preserves_new_session() {
        let access = ReaderChangeDuringOpen {
            access: fake_cbz(),
            comic_id: "open_cancel_before_replacement",
            close: true,
            reopen: true,
            fired: std::sync::atomic::AtomicBool::new(false),
        };
        let result = open_reader_with(&access, access.comic_id, "/lease/comic.cbz", "cbz");
        assert_eq!(
            result.unwrap_err().code,
            HentaiErrorCode::ReaderSessionNotOpen
        );
        assert!(session_path_and_type(access.comic_id).is_ok());
        close_reader(access.comic_id);
    }

    #[test]
    fn concurrent_same_path_open_reuses_the_shared_lifetime() {
        let access = ReaderChangeDuringOpen {
            access: fake_cbz(),
            comic_id: "open_same_lifetime_race",
            close: false,
            reopen: true,
            fired: std::sync::atomic::AtomicBool::new(false),
        };
        let identity = capture_open_lifetime(access.comic_id).unwrap();
        let acquired = acquire_reader_with(
            &access,
            access.comic_id,
            "/lease/comic.cbz",
            "cbz",
            identity.clone(),
        )
        .unwrap();
        assert!(store()
            .lock()
            .unwrap()
            .is_current(access.comic_id, &identity));
        release_reader(access.comic_id, &acquired.identity);
        with_session(access.comic_id, |_| Ok(())).expect("peer open retains its reference");
        close_reader(access.comic_id);
    }

    #[test]
    fn close_invalidates_pending_open_before_cache_reuse() {
        let access = fake_cbz();
        let comic_id = "open_cancel_before_cache_hit";
        let old = capture_open_lifetime(comic_id).unwrap();
        close_reader(comic_id);
        open_reader_with(&access, comic_id, "/lease/comic.cbz", "cbz").unwrap();
        let error =
            acquire_reader_with(&access, comic_id, "/lease/comic.cbz", "cbz", old).unwrap_err();
        assert_eq!(error.code, HentaiErrorCode::ReaderSessionNotOpen);
        with_session(comic_id, |_| Ok(())).unwrap();
        close_reader(comic_id);
    }

    #[test]
    fn ordinary_release_keeps_another_pending_acquire_valid() {
        let access = fake_cbz();
        let comic_id = "open_pending_after_release";
        let identity = capture_open_lifetime(comic_id).unwrap();
        let acquired =
            acquire_reader_with(&access, comic_id, "/lease/comic.cbz", "cbz", identity).unwrap();
        let pending = capture_open_lifetime(comic_id).unwrap();
        release_reader(comic_id, &acquired.identity);
        assert!(session_path_and_type(comic_id).is_err());
        let completed =
            acquire_reader_with(&access, comic_id, "/lease/comic.cbz", "cbz", pending).unwrap();
        assert!(!Arc::ptr_eq(&acquired.identity, &completed.identity));
        release_reader(comic_id, &completed.identity);
        assert!(session_path_and_type(comic_id).is_err());
    }

    #[test]
    fn store_close_invalidates_only_its_comic_even_before_publication() {
        let mut store = SessionStore::new();
        let first = store.capture_lifetime("first");
        let shared = store.capture_lifetime("first");
        let other = store.capture_lifetime("other");
        assert!(Arc::ptr_eq(&first, &shared));
        assert!(!store.close("first"));
        assert!(!store.is_current("first", &first));
        assert!(store.is_current("other", &other));
        let reopened = store.capture_lifetime("first");
        assert!(!Arc::ptr_eq(&first, &reopened));
        assert!(store.is_current("first", &reopened));
    }

    #[test]
    fn store_clear_invalidates_all_pending_acquires() {
        let mut store = SessionStore::new();
        let first = store.capture_lifetime("first");
        let other = store.capture_lifetime("other");
        store.clear();
        assert!(!store.is_current("first", &first));
        assert!(!store.is_current("other", &other));
        let reopened = store.capture_lifetime("first");
        assert!(!Arc::ptr_eq(&first, &reopened));
        assert!(store.is_current("first", &reopened));
    }

    #[test]
    fn old_ephemeral_release_keeps_reopened_session() {
        let access = fake_cbz();
        let path = "/lease/comic.cbz";
        for (comic_id, replacement_path) in [
            ("lease_reopen_same", path),
            ("lease_reopen_different", "/lease/reopened.cbz"),
        ] {
            open_reader_with(&access, comic_id, path, "cbz").unwrap();
            with_ephemeral_reader(comic_id, path, "cbz", |_| {
                close_reader(comic_id);
                open_reader_with(&access, comic_id, replacement_path, "cbz")?;
                Ok(())
            })
            .unwrap();
            assert!(
                session_path_and_type(comic_id).is_ok(),
                "old lease closed replacement"
            );
            close_reader(comic_id);
        }
    }

    #[test]
    fn failed_old_ephemeral_read_keeps_its_error_and_reopened_session() {
        let access = fake_cbz();
        let comic_id = "lease_failed_reopen";
        let path = "/lease/comic.cbz";
        open_reader_with(&access, comic_id, path, "cbz").unwrap();
        let result: Result<(), HentaiError> = with_ephemeral_reader(comic_id, path, "cbz", |_| {
            close_reader(comic_id);
            open_reader_with(&access, comic_id, path, "cbz")?;
            Err(HentaiError::reader_invalid_content("original page failure"))
        });
        assert_eq!(result.unwrap_err().message, "original page failure");
        assert!(
            session_path_and_type(comic_id).is_ok(),
            "failed old lease closed replacement"
        );
        close_reader(comic_id);
    }

    #[test]
    fn unwinding_old_ephemeral_lease_keeps_reopened_session() {
        let access = fake_cbz();
        let comic_id = "lease_unwind_reopen";
        let path = "/lease/comic.cbz";
        open_reader_with(&access, comic_id, path, "cbz").unwrap();
        let result = std::panic::catch_unwind(|| {
            let _: Result<(), HentaiError> = with_ephemeral_reader(comic_id, path, "cbz", |_| {
                close_reader(comic_id);
                open_reader_with(&access, comic_id, path, "cbz")?;
                panic!("page callback panicked");
            });
        });
        assert!(result.is_err());
        assert!(session_path_and_type(comic_id).is_ok());
        close_reader(comic_id);
    }

    #[test]
    fn failed_ephemeral_read_releases_its_session() {
        let root = tempfile::tempdir().unwrap().keep();
        let path = write_tiny_cbz(&root, "page.cbz");
        let comic_id = "lease_error_release";
        let result: Result<(), HentaiError> = with_ephemeral_reader(comic_id, &path, "cbz", |_| {
            Err(HentaiError::reader_invalid_content("page failure"))
        });
        assert_eq!(result.unwrap_err().message, "page failure");
        assert!(session_path_and_type(comic_id).is_err());
    }

    #[test]
    fn unwinding_ephemeral_read_releases_its_session() {
        let root = tempfile::tempdir().unwrap().keep();
        let path = write_tiny_cbz(&root, "page.cbz");
        let comic_id = "lease_unwind_release";
        let result = std::panic::catch_unwind(|| {
            let _: Result<(), HentaiError> = with_ephemeral_reader(comic_id, &path, "cbz", |_| {
                panic!("page callback panicked");
            });
        });
        assert!(result.is_err());
        assert!(session_path_and_type(comic_id).is_err());
    }

    #[test]
    fn nested_ephemeral_leases_keep_the_explicit_reader_open() {
        let access = fake_cbz();
        let comic_id = "lease_nested";
        let path = "/lease/comic.cbz";
        open_reader_with(&access, comic_id, path, "cbz").unwrap();
        let result = with_ephemeral_reader(comic_id, path, "cbz", |_| {
            let value = with_ephemeral_reader(comic_id, path, "cbz", |_| Ok(7))?;
            with_session(comic_id, |_| Ok(()))?;
            Ok(value)
        })
        .unwrap();
        assert_eq!(result, 7);
        with_session(comic_id, |_| Ok(())).unwrap();
        close_reader(comic_id);
    }

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
        let temp = tempfile::tempdir().expect("tempdir").keep();
        let path = write_tiny_cbz(&temp, "a.cbz");
        open_reader("mgr-close-1", &path, "cbz").expect("open");
        close_reader("mgr-close-1");
        let err = with_session("mgr-close-1", |_| Ok(())).expect_err("expected error");
        assert_eq!(err.code, HentaiErrorCode::ReaderSessionNotOpen);
    }

    #[test]
    fn ephemeral_does_not_close_active_reader_session() {
        let temp = tempfile::tempdir().expect("tempdir").keep();
        let path = write_tiny_cbz(&temp, "a.cbz");
        open_reader("mgr-eph-active", &path, "cbz").expect("open");
        with_ephemeral_reader("mgr-eph-active", &path, "cbz", |_| {
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
        let temp = tempfile::tempdir().expect("tempdir").keep();
        let path = write_tiny_cbz(&temp, "a.cbz");
        with_ephemeral_reader("mgr-eph-alone", &path, "cbz", |_| {
            with_session("mgr-eph-alone", |_| Ok(()))
        })
        .expect("ephemeral");
        let err = with_session("mgr-eph-alone", |_| Ok(())).expect_err("should be released");
        assert_eq!(err.code, HentaiErrorCode::ReaderSessionNotOpen);
    }

    #[test]
    fn path_change_while_in_use_is_rejected() {
        let temp = tempfile::tempdir().expect("tempdir").keep();
        let path_a = write_tiny_cbz(&temp, "a.cbz");
        let path_b = write_tiny_cbz(&temp, "b.cbz");
        open_reader("mgr-path-change", &path_a, "cbz").expect("open a");
        let err = open_reader("mgr-path-change", &path_b, "cbz").expect_err("path change");
        assert_eq!(err.code, HentaiErrorCode::ReaderKindMismatch);
        close_reader("mgr-path-change");
    }
}
