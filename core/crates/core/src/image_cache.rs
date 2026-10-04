//! Author image 高清图的磁盘缓存：App data profile 下 `image_cache/`，平台源与 Comic 封面源共用
//! 固定上限，按最近访问时间（文件 mtime）LRU 淘汰。
//!
//! 分区：`comic_cover/{comic_id}/` 存 Comic 高清封面；平台源按 Author link + slot 另设分区。

use std::collections::HashSet;
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::time::SystemTime;

use crate::db;
use crate::error::HentaiError;

pub const IMAGE_CACHE_LIMIT_BYTES: u64 = 512 * 1024 * 1024;
const EVICT_TARGET_PERCENT: u64 = 80;
const COMIC_COVER_DIR: &str = "comic_cover";
const PARTIAL_PREFIX: &str = ".partial_";

/// Comic 高清封面缓存键：源版本（modified_ms + size）或页码变化即换键。
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ComicCoverKey<'a> {
    pub comic_id: &'a str,
    pub source_modified_ms: i64,
    pub source_size: i64,
    pub page_index: Option<i32>,
}

impl ComicCoverKey<'_> {
    fn file_name(&self) -> String {
        let page = match self.page_index {
            Some(index) => format!("p{index}"),
            None => "cover".to_string(),
        };
        format!(
            "{}_{}_{page}.img",
            self.source_modified_ms, self.source_size
        )
    }
}

#[derive(Debug, Clone)]
pub struct ImageCache {
    root: PathBuf,
    limit_bytes: u64,
    evict_in_background: bool,
}

impl ImageCache {
    pub fn app() -> Result<Self, HentaiError> {
        let config = db::db_config()?;
        let parent = config
            .db_file_path
            .parent()
            .ok_or_else(|| HentaiError::validation("无法解析应用数据目录"))?;
        Ok(Self {
            root: parent.join("image_cache"),
            limit_bytes: IMAGE_CACHE_LIMIT_BYTES,
            evict_in_background: true,
        })
    }

    /// 测试用：指定根目录与上限，写入后不触发后台淘汰。
    pub fn with_root(root: impl Into<PathBuf>, limit_bytes: u64) -> Self {
        Self {
            root: root.into(),
            limit_bytes,
            evict_in_background: false,
        }
    }

    pub fn read_comic_cover(&self, key: &ComicCoverKey<'_>) -> Option<Vec<u8>> {
        let path = self.comic_dir(key.comic_id).join(key.file_name());
        let bytes = fs::read(&path).ok()?;
        touch(&path);
        Some(bytes)
    }

    /// 原子写入（临时文件 + rename），并删除同一 Comic 的旧版本条目。
    pub fn write_comic_cover(
        &self,
        key: &ComicCoverKey<'_>,
        bytes: &[u8],
    ) -> Result<(), HentaiError> {
        let dir = self.comic_dir(key.comic_id);
        fs::create_dir_all(&dir).map_err(map_io_err)?;
        let file_name = key.file_name();
        let tmp_path = dir.join(format!(
            "{PARTIAL_PREFIX}{}",
            SystemTime::now()
                .duration_since(SystemTime::UNIX_EPOCH)
                .map(|d| d.as_nanos())
                .unwrap_or(0)
        ));
        if let Err(err) = write_file(&tmp_path, bytes) {
            let _ = fs::remove_file(&tmp_path);
            return Err(err);
        }
        for entry in fs::read_dir(&dir).map_err(map_io_err)?.flatten() {
            let name = entry.file_name().to_string_lossy().into_owned();
            if name != file_name && !name.starts_with(PARTIAL_PREFIX) {
                let _ = fs::remove_file(entry.path());
            }
        }
        if let Err(err) = fs::rename(&tmp_path, dir.join(&file_name)) {
            let _ = fs::remove_file(&tmp_path);
            return Err(map_io_err(err));
        }
        if self.evict_in_background {
            let cache = self.clone();
            std::thread::spawn(move || {
                if let Err(err) = cache.enforce_limit() {
                    tracing::warn!(error = %err, "image cache eviction failed");
                }
            });
        }
        Ok(())
    }

    /// 超出上限时从最久未访问的条目删起，直到总量降到上限的约 80%。
    pub fn enforce_limit(&self) -> Result<(), HentaiError> {
        if !self.root.is_dir() {
            return Ok(());
        }
        let mut entries: Vec<(PathBuf, u64, SystemTime)> = Vec::new();
        for entry in walkdir::WalkDir::new(&self.root).into_iter().flatten() {
            if !entry.file_type().is_file()
                || entry
                    .file_name()
                    .to_string_lossy()
                    .starts_with(PARTIAL_PREFIX)
            {
                continue;
            }
            let Ok(meta) = entry.metadata() else {
                continue;
            };
            let accessed = meta.modified().unwrap_or(SystemTime::UNIX_EPOCH);
            entries.push((entry.into_path(), meta.len(), accessed));
        }
        let mut total: u64 = entries.iter().map(|(_, size, _)| size).sum();
        if total <= self.limit_bytes {
            return Ok(());
        }
        let target = self.limit_bytes * EVICT_TARGET_PERCENT / 100;
        entries.sort_by_key(|(_, _, accessed)| *accessed);
        for (path, size, _) in entries {
            if total <= target {
                break;
            }
            if fs::remove_file(&path).is_ok() {
                total = total.saturating_sub(size);
            }
        }
        Ok(())
    }

    /// 删除已不在库中的 Comic 的高清封面。
    pub fn prune_comic_covers(&self, keep_comic_ids: &HashSet<String>) -> Result<(), HentaiError> {
        let dir = self.root.join(COMIC_COVER_DIR);
        if !dir.is_dir() {
            return Ok(());
        }
        for entry in fs::read_dir(&dir).map_err(map_io_err)?.flatten() {
            let name = entry.file_name().to_string_lossy().into_owned();
            if !keep_comic_ids.contains(&name) {
                let _ = fs::remove_dir_all(entry.path());
            }
        }
        Ok(())
    }

    fn comic_dir(&self, comic_id: &str) -> PathBuf {
        self.root.join(COMIC_COVER_DIR).join(comic_id)
    }
}

/// 应用启动后台维护：清除已不在库中的 Comic 的高清封面，并按上限淘汰。
pub fn spawn_startup_maintenance() {
    std::thread::spawn(|| {
        if let Err(err) = run_startup_maintenance() {
            tracing::warn!(error = %err, "image cache startup maintenance failed");
        }
    });
}

fn run_startup_maintenance() -> Result<(), HentaiError> {
    use crate::entity::{comics, prelude::*};
    use sea_orm::{EntityTrait, QuerySelect};

    let cache = ImageCache::app()?;
    let db = db::connection()?;
    let comic_ids: Vec<String> = crate::runtime::block_on(
        Comics::find()
            .select_only()
            .column(comics::Column::ComicId)
            .into_tuple()
            .all(&db),
    )
    .map_err(db::map_db_err)?;
    cache.prune_comic_covers(&comic_ids.into_iter().collect())?;
    cache.enforce_limit()
}

fn touch(path: &Path) {
    if let Ok(file) = fs::OpenOptions::new().write(true).open(path) {
        let _ = file.set_modified(SystemTime::now());
    }
}

fn write_file(path: &Path, bytes: &[u8]) -> Result<(), HentaiError> {
    let mut file = fs::File::create(path).map_err(map_io_err)?;
    file.write_all(bytes).map_err(map_io_err)?;
    file.sync_all().map_err(map_io_err)
}

fn map_io_err(err: std::io::Error) -> HentaiError {
    HentaiError::validation(format!("图片缓存读写失败: {err}"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::Duration;

    fn key(comic_id: &str) -> ComicCoverKey<'_> {
        ComicCoverKey {
            comic_id,
            source_modified_ms: 1,
            source_size: 1,
            page_index: None,
        }
    }

    fn pause() {
        std::thread::sleep(Duration::from_millis(30));
    }

    #[test]
    fn eviction_removes_least_recently_used_until_about_80_percent() {
        let temp = tempfile::TempDir::new().expect("tempdir");
        let cache = ImageCache::with_root(temp.path(), 1000);
        let payload = vec![7u8; 300];

        cache.write_comic_cover(&key("a"), &payload).expect("a");
        pause();
        cache.write_comic_cover(&key("b"), &payload).expect("b");
        pause();
        cache.write_comic_cover(&key("c"), &payload).expect("c");
        pause();
        assert!(cache.read_comic_cover(&key("a")).is_some(), "touch a");
        pause();
        cache.write_comic_cover(&key("d"), &payload).expect("d");

        cache.enforce_limit().expect("evict");

        // 1200 > 1000：删到 ≤ 800，最久未访问的 b、c 先走；a 刚被读取而保留。
        assert!(cache.read_comic_cover(&key("a")).is_some());
        assert!(cache.read_comic_cover(&key("b")).is_none());
        assert!(cache.read_comic_cover(&key("c")).is_none());
        assert!(cache.read_comic_cover(&key("d")).is_some());
    }

    #[test]
    fn eviction_keeps_everything_under_limit() {
        let temp = tempfile::TempDir::new().expect("tempdir");
        let cache = ImageCache::with_root(temp.path(), 1000);
        cache.write_comic_cover(&key("a"), &[1u8; 400]).expect("a");
        cache.write_comic_cover(&key("b"), &[1u8; 400]).expect("b");

        cache.enforce_limit().expect("evict");

        assert!(cache.read_comic_cover(&key("a")).is_some());
        assert!(cache.read_comic_cover(&key("b")).is_some());
    }

    #[test]
    fn prune_drops_covers_of_comics_no_longer_in_library() {
        let temp = tempfile::TempDir::new().expect("tempdir");
        let cache = ImageCache::with_root(temp.path(), 1000);
        cache
            .write_comic_cover(&key("kept"), &[1u8; 10])
            .expect("kept");
        cache
            .write_comic_cover(&key("gone"), &[1u8; 10])
            .expect("gone");

        cache
            .prune_comic_covers(&HashSet::from(["kept".to_string()]))
            .expect("prune");

        assert!(cache.read_comic_cover(&key("kept")).is_some());
        assert!(cache.read_comic_cover(&key("gone")).is_none());
    }
}
