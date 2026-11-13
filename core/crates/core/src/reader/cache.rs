use std::collections::{HashMap, HashSet};
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex, MutexGuard, OnceLock, PoisonError};

use crate::db;
use crate::error::HentaiError;
use crate::resource::{ResourceKind, ResourceStat};

const PAGE_FILE_WIDTH: usize = 5;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(super) struct ReaderSourceVersion {
    modified_ms: i64,
    size: u64,
}

impl ReaderSourceVersion {
    pub(super) fn from_stat(stat: &ResourceStat) -> Option<Self> {
        (stat.kind == ResourceKind::File && stat.modified_ms != 0).then_some(Self {
            modified_ms: stat.modified_ms,
            size: stat.size,
        })
    }
}

#[derive(Default)]
struct ComicCacheState {
    request: Option<Arc<()>>,
    foreground_lifetime: Arc<()>,
    clear_pending: bool,
}

#[derive(Default)]
struct ComicCacheRequests {
    state: Mutex<ComicCacheState>,
}

impl ComicCacheRequests {
    fn lock(&self) -> MutexGuard<'_, ComicCacheState> {
        self.state.lock().unwrap_or_else(PoisonError::into_inner)
    }
}

fn comic_cache_requests(comic_id: &str) -> Arc<ComicCacheRequests> {
    static STORE: OnceLock<Mutex<HashMap<String, Arc<ComicCacheRequests>>>> = OnceLock::new();
    STORE
        .get_or_init(|| Mutex::new(HashMap::new()))
        .lock()
        .unwrap_or_else(PoisonError::into_inner)
        .entry(comic_id.to_string())
        .or_default()
        .clone()
}

pub struct ReaderPageCacheRequest {
    pub(super) comic_id: String,
    owner: Arc<ComicCacheRequests>,
    identity: Arc<()>,
}

impl ReaderPageCacheRequest {
    // Reserve before dispatch: worker scheduling must not decide request ownership.
    pub fn begin(comic_id: &str) -> Self {
        Self::begin_with(comic_id, false)
    }

    pub fn begin_clear(comic_id: &str) -> Self {
        Self::begin_with(comic_id, true)
    }

    fn begin_with(comic_id: &str, clear: bool) -> Self {
        let owner = comic_cache_requests(comic_id);
        let identity = Arc::new(());
        {
            let mut state = owner.lock();
            state.request = Some(identity.clone());
            state.clear_pending = clear;
            if clear {
                state.foreground_lifetime = Arc::new(());
            }
        }
        Self {
            comic_id: comic_id.to_string(),
            owner,
            identity,
        }
    }

    fn owns(&self, state: &ComicCacheState) -> bool {
        state
            .request
            .as_ref()
            .is_some_and(|current| Arc::ptr_eq(current, &self.identity))
    }

    pub(super) fn is_current(&self) -> bool {
        self.owns(&self.owner.lock())
    }

    pub(super) fn apply_if_current<T>(
        &self,
        apply: impl FnOnce() -> Result<T, HentaiError>,
    ) -> Result<Option<T>, HentaiError> {
        let state = self.owner.lock();
        if self.owns(&state) {
            return apply().map(Some);
        }
        Ok(None)
    }

    pub(super) fn clear_with(
        &self,
        clear: impl FnOnce() -> Result<(), HentaiError>,
    ) -> Result<(), HentaiError> {
        let mut state = self.owner.lock();
        if !self.owns(&state) {
            return Ok(());
        }
        let result = clear();
        state.clear_pending = false;
        result
    }
}

pub(super) struct ReaderPageCacheRead {
    owner: Arc<ComicCacheRequests>,
    lifetime: Arc<()>,
}

impl ReaderPageCacheRead {
    pub(super) fn capture(comic_id: &str) -> Self {
        let owner = comic_cache_requests(comic_id);
        let lifetime = owner.lock().foreground_lifetime.clone();
        Self { owner, lifetime }
    }

    pub(super) fn apply_if_current<T>(
        &self,
        apply: impl FnOnce() -> Result<T, HentaiError>,
    ) -> Result<Option<T>, HentaiError> {
        let state = self.owner.lock();
        // A queued clear must not remove a new foreground result after it is returned.
        if !state.clear_pending && Arc::ptr_eq(&state.foreground_lifetime, &self.lifetime) {
            return apply().map(Some);
        }
        Ok(None)
    }
}

pub(super) struct ReaderCache {
    root: PathBuf,
}

impl ReaderCache {
    pub(super) fn app() -> Result<Self, HentaiError> {
        let config = db::db_config()?;
        let parent = config
            .db_file_path
            .parent()
            .ok_or_else(|| HentaiError::reader_invalid_content("无法解析应用数据目录"))?;
        Ok(Self {
            root: parent.join("reader_cache"),
        })
    }

    #[cfg(test)]
    pub(super) fn with_root(root: impl Into<PathBuf>) -> Self {
        Self { root: root.into() }
    }

    pub(super) fn cached_page_path(
        &self,
        comic_id: &str,
        source: &ReaderSourceVersion,
        page_index: i32,
    ) -> Result<Option<PathBuf>, HentaiError> {
        let page_index = normalize_page_index(page_index)?;
        let dir = self.comic_cache_dir(comic_id, source);
        if !dir.is_dir() {
            return Ok(None);
        }
        Ok(find_cached_page_file(&dir, page_index))
    }

    pub(super) fn write_page(
        &self,
        comic_id: &str,
        source: &ReaderSourceVersion,
        page_index: i32,
        bytes: &[u8],
    ) -> Result<PathBuf, HentaiError> {
        let page_index = normalize_page_index(page_index)?;
        if bytes.is_empty() {
            return Err(HentaiError::reader_invalid_content("页面数据为空"));
        }
        let dir = self.comic_cache_dir(comic_id, source);
        fs::create_dir_all(&dir).map_err(map_io_err)?;
        let extension = image_extension(bytes);
        let file_path = dir.join(format!("{page_index:0PAGE_FILE_WIDTH$}.{extension}"));
        // Temp name must not match `{index}.` prefix so concurrent lookups never see a
        // zero-byte final path from File::create before write_all completes.
        let tmp_path = dir.join(format!(
            ".partial_{page_index:0PAGE_FILE_WIDTH$}_{}",
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| d.as_nanos())
                .unwrap_or(0)
        ));
        if let Err(err) = write_bytes_atomic(&tmp_path, bytes) {
            let _ = fs::remove_file(&tmp_path);
            return Err(err);
        }
        remove_existing_page_files(&dir, page_index)?;
        if let Err(err) = fs::rename(&tmp_path, &file_path) {
            let _ = fs::remove_file(&tmp_path);
            return Err(map_io_err(err));
        }
        Ok(file_path)
    }

    pub(super) fn evict_outside_pages(
        &self,
        comic_id: &str,
        source: &ReaderSourceVersion,
        keep_page_indexes: &[i32],
    ) -> Result<(), HentaiError> {
        let dir = self.comic_cache_dir(comic_id, source);
        if !dir.is_dir() {
            return Ok(());
        }
        let keep: HashSet<i32> = keep_page_indexes
            .iter()
            .copied()
            .map(normalize_page_index)
            .collect::<Result<HashSet<i32>, HentaiError>>()?;
        for entry in fs::read_dir(&dir).map_err(map_io_err)? {
            let entry = entry.map_err(map_io_err)?;
            if !entry.file_type().map_err(map_io_err)?.is_file() {
                continue;
            }
            let Some(index) = page_index_from_file_name(&entry.file_name().to_string_lossy())
            else {
                continue;
            };
            if !keep.contains(&index) {
                let _ = fs::remove_file(entry.path());
            }
        }
        Ok(())
    }

    pub(super) fn clear_comic(&self, comic_id: &str) -> Result<(), HentaiError> {
        let dir = self.root.join(comic_id);
        if !dir.is_dir() {
            return Ok(());
        }

        for _ in 0..8 {
            match fs::remove_dir_all(&dir) {
                Ok(()) => return Ok(()),
                Err(_) if !dir.exists() => return Ok(()),
                Err(err) if is_retryable_clear_error(&err) => {
                    remove_tree_best_effort(&dir);
                    std::thread::sleep(std::time::Duration::from_millis(1));
                }
                Err(err) => return Err(map_io_err(err)),
            }
        }

        // Last resort on Windows: rename aside so the comic cache key is gone, then
        // best-effort delete the trash. Never fail the exit/clear FRB path on 145.
        let trash = self.root.join(format!(
            ".trash_{comic_id}_{}",
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| d.as_millis())
                .unwrap_or(0)
        ));
        match fs::rename(&dir, &trash) {
            Ok(()) => {
                let _ = fs::remove_dir_all(&trash);
                Ok(())
            }
            Err(_) if !dir.exists() => Ok(()),
            Err(_) => {
                remove_tree_best_effort(&dir);
                Ok(())
            }
        }
    }

    fn comic_cache_dir(&self, comic_id: &str, source: &ReaderSourceVersion) -> PathBuf {
        self.root
            .join(comic_id)
            .join(format!("v2_{}_{}", source.modified_ms, source.size))
    }
}

pub fn image_extension(bytes: &[u8]) -> &'static str {
    if bytes.len() >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
        "jpg"
    } else if bytes.len() >= 8 && bytes[..8] == *b"\x89PNG\r\n\x1a\n" {
        "png"
    } else if bytes.len() >= 3 && bytes[..3] == *b"GIF" {
        "gif"
    } else if bytes.len() >= 12 && bytes[..4] == *b"RIFF" && bytes[8..12] == *b"WEBP" {
        "webp"
    } else if bytes.len() >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D {
        "bmp"
    } else {
        "bin"
    }
}

fn normalize_page_index(page_index: i32) -> Result<i32, HentaiError> {
    if page_index < 0 {
        return Err(HentaiError::reader_invalid_content(format!(
            "页索引无效: {page_index}"
        )));
    }
    Ok(page_index)
}

fn find_cached_page_file(dir: &Path, page_index: i32) -> Option<PathBuf> {
    let prefix = format!("{page_index:0PAGE_FILE_WIDTH$}.");
    let Ok(entries) = fs::read_dir(dir) else {
        return None;
    };
    let mut hit = None;
    for entry in entries.flatten() {
        let name = entry.file_name();
        if !name.to_string_lossy().starts_with(&prefix) {
            continue;
        }
        let path = entry.path();
        match fs::metadata(&path) {
            Ok(meta) if meta.is_file() && meta.len() > 0 => {
                if hit.is_none() {
                    hit = Some(path);
                }
            }
            Ok(meta) if meta.is_file() && meta.len() == 0 => {
                // Heal poisoned empty finals left by interrupted / non-atomic writes.
                let _ = fs::remove_file(&path);
            }
            _ => {}
        }
    }
    hit
}

fn write_bytes_atomic(path: &Path, bytes: &[u8]) -> Result<(), HentaiError> {
    let mut file = fs::File::create(path).map_err(map_io_err)?;
    file.write_all(bytes).map_err(map_io_err)?;
    file.sync_all().map_err(map_io_err)?;
    Ok(())
}

fn remove_existing_page_files(dir: &Path, page_index: i32) -> Result<(), HentaiError> {
    let prefix = format!("{page_index:0PAGE_FILE_WIDTH$}.");
    for entry in fs::read_dir(dir).map_err(map_io_err)? {
        let entry = entry.map_err(map_io_err)?;
        if entry.file_name().to_string_lossy().starts_with(&prefix) {
            fs::remove_file(entry.path()).map_err(map_io_err)?;
        }
    }
    Ok(())
}

fn page_index_from_file_name(name: &str) -> Option<i32> {
    let stem = name.rsplit_once('.')?.0;
    stem.parse::<i32>().ok()
}

fn map_io_err(error: std::io::Error) -> HentaiError {
    HentaiError::reader_invalid_content(error.to_string())
}

fn is_retryable_clear_error(error: &std::io::Error) -> bool {
    if error.raw_os_error() == Some(145) {
        return true;
    }
    let message = error.to_string();
    if message.contains("not empty") || message.contains("不是空的") {
        return true;
    }
    matches!(
        error.kind(),
        std::io::ErrorKind::DirectoryNotEmpty
            | std::io::ErrorKind::PermissionDenied
            | std::io::ErrorKind::Interrupted
            | std::io::ErrorKind::TimedOut
            | std::io::ErrorKind::WouldBlock
    )
}

fn remove_tree_best_effort(path: &Path) {
    let Ok(entries) = fs::read_dir(path) else {
        return;
    };
    for entry in entries.flatten() {
        let child = entry.path();
        let is_dir = entry.file_type().map(|t| t.is_dir()).unwrap_or(false);
        if is_dir {
            remove_tree_best_effort(&child);
            let _ = fs::remove_dir(&child);
        } else {
            let _ = fs::remove_file(&child);
        }
    }
    let _ = fs::remove_dir(path);
}

#[cfg(test)]
mod version_tests {
    use super::*;
    use crate::resource::ResourceAccess;

    pub(super) fn source_version(path: &str) -> ReaderSourceVersion {
        ReaderSourceVersion::from_stat(
            &crate::resource::local_access().stat(path).unwrap().unwrap(),
        )
        .unwrap()
    }

    #[test]
    fn legacy_live_path_cache_is_ignored_without_removing_files() {
        let root = tempfile::tempdir().unwrap().keep();
        let source = ReaderSourceVersion::from_stat(&ResourceStat {
            kind: ResourceKind::File,
            modified_ms: 10,
            size: 20,
        })
        .unwrap();
        let legacy_dir = root.join("comic").join("10_20");
        fs::create_dir_all(&legacy_dir).unwrap();
        let legacy = legacy_dir.join("00000.bin");
        fs::write(&legacy, b"old-cache").unwrap();
        let cache = ReaderCache::with_root(&root);
        assert!(cache
            .cached_page_path("comic", &source, 0)
            .unwrap()
            .is_none());
        let current = cache
            .write_page("comic", &source, 0, b"fresh-cache")
            .unwrap();
        assert_ne!(legacy, current);
        assert_eq!(fs::read(legacy).unwrap(), b"old-cache");
        assert_eq!(fs::read(current).unwrap(), b"fresh-cache");
    }

    #[test]
    fn late_page_write_does_not_populate_replacement_source_version() {
        let root = tempfile::tempdir().unwrap().keep();
        let source = root.join("source.cbz");
        fs::write(&source, b"source-A").unwrap();
        let source_path = source.to_string_lossy();
        let old_version = source_version(&source_path);
        fs::write(&source, b"replacement-source-B-with-another-size").unwrap();
        let new_version = source_version(&source_path);
        assert_ne!(old_version, new_version);
        let cache = ReaderCache::with_root(root.join("cache"));
        cache
            .write_page("versioned", &new_version, 0, b"decoded-B")
            .unwrap();
        cache
            .write_page("versioned", &old_version, 0, b"decoded-A")
            .unwrap();
        let replacement = cache
            .cached_page_path("versioned", &new_version, 0)
            .unwrap()
            .unwrap();
        assert_eq!(fs::read(replacement).unwrap(), b"decoded-B");
        let original = cache
            .cached_page_path("versioned", &old_version, 0)
            .unwrap()
            .unwrap();
        assert_eq!(fs::read(original).unwrap(), b"decoded-A");
    }
}

#[cfg(test)]
mod tests {
    use super::version_tests::source_version;
    use super::*;

    #[test]
    fn write_and_read_cached_page_roundtrip() {
        let temp = tempfile::tempdir().expect("tempdir");
        let source = temp.path().join("comic.cbz");
        fs::write(&source, b"archive-bytes").expect("write source");

        let cache = ReaderCache::with_root(temp.path().join("reader_cache"));
        let written = cache
            .write_page(
                "comic-1",
                &source_version(&source.to_string_lossy()),
                3,
                b"\xFF\xD8\xFFpage",
            )
            .expect("write");
        assert!(written.exists());
        assert!(fs::metadata(&written).expect("meta").len() > 0);

        let hit = cache
            .cached_page_path("comic-1", &source_version(&source.to_string_lossy()), 3)
            .expect("lookup")
            .expect("cached");
        assert_eq!(hit, written);
    }

    #[test]
    fn cached_page_path_ignores_and_removes_empty_files() {
        let temp = tempfile::tempdir().expect("tempdir");
        let source = temp.path().join("comic.cbz");
        fs::write(&source, b"archive-bytes").expect("write source");
        let cache = ReaderCache::with_root(temp.path().join("reader_cache"));
        let dir = cache.comic_cache_dir("comic-1", &source_version(&source.to_string_lossy()));
        fs::create_dir_all(&dir).expect("mkdir");
        let empty = dir.join("00000.webp");
        fs::File::create(&empty).expect("create empty");
        assert_eq!(fs::metadata(&empty).expect("meta").len(), 0);

        assert!(cache
            .cached_page_path("comic-1", &source_version(&source.to_string_lossy()), 0)
            .expect("lookup")
            .is_none());
        assert!(!empty.exists(), "poison empty cache file must be removed");
    }

    #[test]
    fn write_page_rejects_empty_bytes() {
        let temp = tempfile::tempdir().expect("tempdir");
        let source = temp.path().join("comic.cbz");
        fs::write(&source, b"archive-bytes").expect("write source");
        let cache = ReaderCache::with_root(temp.path().join("reader_cache"));
        assert!(cache
            .write_page(
                "comic-1",
                &source_version(&source.to_string_lossy()),
                0,
                &[]
            )
            .is_err());
    }

    #[test]
    fn evict_outside_pages_removes_stale_entries() {
        let temp = tempfile::tempdir().expect("tempdir");
        let source = temp.path().join("comic.cbz");
        fs::write(&source, b"archive-bytes").expect("write source");
        let cache = ReaderCache::with_root(temp.path().join("reader_cache"));
        cache
            .write_page(
                "comic-1",
                &source_version(&source.to_string_lossy()),
                1,
                b"\xFF\xD8\xFFone",
            )
            .expect("write1");
        cache
            .write_page(
                "comic-1",
                &source_version(&source.to_string_lossy()),
                2,
                b"\xFF\xD8\xFFtwo",
            )
            .expect("write2");
        cache
            .write_page(
                "comic-1",
                &source_version(&source.to_string_lossy()),
                8,
                b"\xFF\xD8\xFFeight",
            )
            .expect("write8");

        cache
            .evict_outside_pages(
                "comic-1",
                &source_version(&source.to_string_lossy()),
                &[2, 3],
            )
            .expect("evict");

        assert!(cache
            .cached_page_path("comic-1", &source_version(&source.to_string_lossy()), 1)
            .expect("lookup1")
            .is_none());
        assert!(cache
            .cached_page_path("comic-1", &source_version(&source.to_string_lossy()), 2)
            .expect("lookup2")
            .is_some());
        assert!(cache
            .cached_page_path("comic-1", &source_version(&source.to_string_lossy()), 8)
            .expect("lookup8")
            .is_none());
    }

    #[test]
    fn clear_comic_succeeds_while_cached_page_file_is_open() {
        let temp = tempfile::tempdir().expect("tempdir");
        let source = temp.path().join("comic.cbz");
        fs::write(&source, b"archive-bytes").expect("write source");
        let cache = ReaderCache::with_root(temp.path().join("reader_cache"));
        let written = cache
            .write_page(
                "comic-1",
                &source_version(&source.to_string_lossy()),
                1,
                b"\xFF\xD8\xFFone",
            )
            .expect("write1");
        cache
            .write_page(
                "comic-1",
                &source_version(&source.to_string_lossy()),
                2,
                b"\xFF\xD8\xFFtwo",
            )
            .expect("write2");

        // Simulate Flutter still decoding/holding the cached page file on exit.
        let _held = fs::File::open(&written).expect("hold open");

        let result = cache.clear_comic("comic-1");
        assert!(
            result.is_ok(),
            "clear_comic must tolerate open cache files (got {result:?})"
        );
    }

    #[test]
    fn clear_comic_succeeds_under_concurrent_writers() {
        use std::sync::atomic::{AtomicBool, Ordering};
        use std::sync::Arc;
        use std::thread;
        use std::time::Duration;

        let temp = tempfile::tempdir().expect("tempdir");
        let source = temp.path().join("comic.cbz");
        fs::write(&source, b"archive-bytes").expect("write source");
        let cache_root = temp.path().join("reader_cache");
        let source_str = source.to_string_lossy().to_string();

        let stop = Arc::new(AtomicBool::new(false));
        let mut handles = Vec::new();
        for worker in 0..4 {
            let cache_root = cache_root.clone();
            let source_str = source_str.clone();
            let stop = Arc::clone(&stop);
            handles.push(thread::spawn(move || {
                let cache = ReaderCache::with_root(cache_root);
                let mut page = worker;
                while !stop.load(Ordering::Relaxed) {
                    let _ = cache.write_page(
                        "comic-1",
                        &source_version(&source_str),
                        page,
                        b"\xFF\xD8\xFFpage",
                    );
                    page = (page + 4) % 200;
                }
            }));
        }

        thread::sleep(Duration::from_millis(20));
        let cache = ReaderCache::with_root(&cache_root);
        let result = cache.clear_comic("comic-1");
        stop.store(true, Ordering::Relaxed);
        for handle in handles {
            let _ = handle.join();
        }

        assert!(
            result.is_ok(),
            "clear_comic must not fail under concurrent writers (got {result:?})"
        );
        let _ = cache.clear_comic("comic-1");
    }
}
