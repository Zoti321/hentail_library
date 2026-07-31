use std::collections::HashSet;
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

use crate::db;
use crate::error::HentaiError;

const PAGE_FILE_WIDTH: usize = 5;

pub struct ReaderCache {
    root: PathBuf,
}

impl ReaderCache {
    pub fn app() -> Result<Self, HentaiError> {
        let config = db::db_config()?;
        let parent = config.db_file_path.parent().ok_or_else(|| {
            HentaiError::reader_invalid_content("无法解析应用数据目录")
        })?;
        Ok(Self {
            root: parent.join("reader_cache"),
        })
    }

    #[cfg(test)]
    pub fn with_root(root: impl Into<PathBuf>) -> Self {
        Self { root: root.into() }
    }

    pub fn root(&self) -> &Path {
        &self.root
    }

    pub fn cached_page_path(
        &self,
        comic_id: &str,
        source_path: &str,
        page_index: i32,
    ) -> Result<Option<PathBuf>, HentaiError> {
        let page_index = normalize_page_index(page_index)?;
        let dir = self.comic_cache_dir(comic_id, source_path)?;
        if !dir.is_dir() {
            return Ok(None);
        }
        Ok(find_cached_page_file(&dir, page_index))
    }

    pub fn write_page(
        &self,
        comic_id: &str,
        source_path: &str,
        page_index: i32,
        bytes: &[u8],
    ) -> Result<PathBuf, HentaiError> {
        let page_index = normalize_page_index(page_index)?;
        let dir = self.comic_cache_dir(comic_id, source_path)?;
        fs::create_dir_all(&dir).map_err(map_io_err)?;
        remove_existing_page_files(&dir, page_index)?;
        let extension = image_extension(bytes);
        let file_path = dir.join(format!("{page_index:0PAGE_FILE_WIDTH$}.{extension}"));
        let mut file = fs::File::create(&file_path).map_err(map_io_err)?;
        file.write_all(bytes).map_err(map_io_err)?;
        Ok(file_path)
    }

    pub fn evict_outside_pages(
        &self,
        comic_id: &str,
        source_path: &str,
        keep_page_indexes: &[i32],
    ) -> Result<(), HentaiError> {
        let dir = self.comic_cache_dir(comic_id, source_path)?;
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
            let Some(index) = page_index_from_file_name(&entry.file_name().to_string_lossy()) else {
                continue;
            };
            if !keep.contains(&index) {
                let _ = fs::remove_file(entry.path());
            }
        }
        Ok(())
    }

    pub fn clear_comic(&self, comic_id: &str) -> Result<(), HentaiError> {
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

    fn comic_cache_dir(&self, comic_id: &str, source_path: &str) -> Result<PathBuf, HentaiError> {
        let fingerprint = source_fingerprint(source_path)?;
        Ok(self.root.join(comic_id).join(fingerprint))
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

fn source_fingerprint(source_path: &str) -> Result<String, HentaiError> {
    let metadata = fs::metadata(source_path).map_err(map_io_err)?;
    let modified_ms = metadata
        .modified()
        .ok()
        .and_then(|time| time.duration_since(std::time::UNIX_EPOCH).ok())
        .map(|duration| duration.as_millis() as i64)
        .unwrap_or(0);
    Ok(format!("{}_{}", modified_ms, metadata.len()))
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
    fs::read_dir(dir)
        .ok()?
        .filter_map(|entry| entry.ok())
        .find(|entry| entry.file_name().to_string_lossy().starts_with(&prefix))
        .map(|entry| entry.path())
}

fn remove_existing_page_files(dir: &Path, page_index: i32) -> Result<(), HentaiError> {
    let prefix = format!("{page_index:0PAGE_FILE_WIDTH$}.");
    for entry in fs::read_dir(dir).map_err(map_io_err)? {
        let entry = entry.map_err(map_io_err)?;
        if entry
            .file_name()
            .to_string_lossy()
            .starts_with(&prefix)
        {
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
mod tests {
    use super::*;

    #[test]
    fn write_and_read_cached_page_roundtrip() {
        let temp = tempfile::tempdir().expect("tempdir");
        let source = temp.path().join("comic.cbz");
        fs::write(&source, b"archive-bytes").expect("write source");

        let cache = ReaderCache::with_root(temp.path().join("reader_cache"));
        let written = cache
            .write_page("comic-1", &source.to_string_lossy(), 3, b"\xFF\xD8\xFFpage")
            .expect("write");
        assert!(written.exists());

        let hit = cache
            .cached_page_path("comic-1", &source.to_string_lossy(), 3)
            .expect("lookup")
            .expect("cached");
        assert_eq!(hit, written);
    }

    #[test]
    fn evict_outside_pages_removes_stale_entries() {
        let temp = tempfile::tempdir().expect("tempdir");
        let source = temp.path().join("comic.cbz");
        fs::write(&source, b"archive-bytes").expect("write source");
        let cache = ReaderCache::with_root(temp.path().join("reader_cache"));
        cache
            .write_page("comic-1", &source.to_string_lossy(), 1, b"\xFF\xD8\xFFone")
            .expect("write1");
        cache
            .write_page("comic-1", &source.to_string_lossy(), 2, b"\xFF\xD8\xFFtwo")
            .expect("write2");
        cache
            .write_page("comic-1", &source.to_string_lossy(), 8, b"\xFF\xD8\xFFeight")
            .expect("write8");

        cache
            .evict_outside_pages("comic-1", &source.to_string_lossy(), &[2, 3])
            .expect("evict");

        assert!(cache
            .cached_page_path("comic-1", &source.to_string_lossy(), 1)
            .expect("lookup1")
            .is_none());
        assert!(cache
            .cached_page_path("comic-1", &source.to_string_lossy(), 2)
            .expect("lookup2")
            .is_some());
        assert!(cache
            .cached_page_path("comic-1", &source.to_string_lossy(), 8)
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
            .write_page("comic-1", &source.to_string_lossy(), 1, b"\xFF\xD8\xFFone")
            .expect("write1");
        cache
            .write_page("comic-1", &source.to_string_lossy(), 2, b"\xFF\xD8\xFFtwo")
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
                        &source_str,
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
