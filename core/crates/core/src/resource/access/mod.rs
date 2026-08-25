//! Resource access — list / stat / open-stream over Resources.
//!
//! Local uses the filesystem; tests inject [FakeResourceAccess]. Remote
//! uses [WebDavResourceAccess] (`reqwest_dav` + Basic).

mod fake;
mod local;
mod webdav;

use std::io::{Read, Seek};
use std::time::{SystemTime, UNIX_EPOCH};

use crate::error::HentaiError;

pub use fake::FakeResourceAccess;
pub use local::LocalResourceAccess;
pub use webdav::WebDavResourceAccess;

/// File vs directory at a resource location.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ResourceKind {
    File,
    Dir,
}

/// Attributes from [ResourceAccess::stat].
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ResourceStat {
    pub kind: ResourceKind,
    pub size: u64,
    pub modified_ms: i64,
}

/// One child from [ResourceAccess::list].
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ResourceEntry {
    pub name: String,
    /// Full location key (local path string today; WebDAV URL later).
    pub location: String,
    pub kind: ResourceKind,
}

/// Read + seek stream from [ResourceAccess::open_stream].
pub trait ResourceReadSeek: Read + Seek + Send {}
impl<T: Read + Seek + Send> ResourceReadSeek for T {}

pub type ResourceStream = Box<dyn ResourceReadSeek>;

/// Unified access to resources under a Library root.
pub trait ResourceAccess: Send + Sync {
    fn list(&self, location: &str) -> Result<Vec<ResourceEntry>, HentaiError>;
    fn stat(&self, location: &str) -> Result<Option<ResourceStat>, HentaiError>;
    fn open_stream(&self, location: &str) -> Result<ResourceStream, HentaiError>;
}

pub(crate) fn system_time_to_ms(time: SystemTime) -> i64 {
    time.duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0)
}

/// Default Local adapter for production call sites.
pub fn local_access() -> &'static LocalResourceAccess {
    static LOCAL: LocalResourceAccess = LocalResourceAccess;
    &LOCAL
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Read;

    #[test]
    fn fake_list_stat_open_stream() {
        let mut fake = FakeResourceAccess::new();
        fake.insert_dir("/root");
        fake.insert_file("/root/a.txt", b"hello");
        fake.insert_file("/root/b.txt", b"world!");

        let mut entries = fake.list("/root").expect("list");
        entries.sort_by(|a, b| a.name.cmp(&b.name));
        assert_eq!(entries.len(), 2);
        assert_eq!(entries[0].name, "a.txt");
        assert_eq!(entries[0].kind, ResourceKind::File);
        assert_eq!(entries[0].location, "/root/a.txt");

        let stat = fake.stat("/root/a.txt").expect("stat").expect("exists");
        assert_eq!(stat.kind, ResourceKind::File);
        assert_eq!(stat.size, 5);

        let mut stream = fake.open_stream("/root/a.txt").expect("open");
        let mut buf = String::new();
        stream.read_to_string(&mut buf).expect("read");
        assert_eq!(buf, "hello");
    }

    #[test]
    fn fake_missing_stat_is_none() {
        let fake = FakeResourceAccess::new();
        assert!(fake.stat("/nope").expect("stat").is_none());
    }

    #[test]
    fn local_stat_missing_is_none_and_probe_root_errors() {
        let temp = tempfile::TempDir::new().expect("temp");
        let missing = temp.path().join("missing-root");
        let loc = missing.to_string_lossy().to_string();
        let access = LocalResourceAccess;
        assert!(access.stat(&loc).expect("stat").is_none());
        assert!(access.probe_root(&loc).is_err());
    }

    #[test]
    fn local_list_stat_open_stream_matches_disk() {
        let temp = tempfile::TempDir::new().expect("temp");
        let root = temp.path().join("root");
        std::fs::create_dir(&root).expect("mkdir");
        let file = root.join("page.jpg");
        std::fs::write(&file, b"jpeg-bytes").expect("write");

        let access = LocalResourceAccess;
        let root_loc = root.to_string_lossy().to_string();
        let file_loc = file.to_string_lossy().to_string();

        let entries = access.list(&root_loc).expect("list");
        assert_eq!(entries.len(), 1);
        assert_eq!(entries[0].name, "page.jpg");
        assert_eq!(entries[0].kind, ResourceKind::File);

        let stat = access.stat(&file_loc).expect("stat").expect("exists");
        assert_eq!(stat.kind, ResourceKind::File);
        assert_eq!(stat.size, 10);

        let mut stream = access.open_stream(&file_loc).expect("open");
        let mut buf = Vec::new();
        stream.read_to_end(&mut buf).expect("read");
        assert_eq!(buf, b"jpeg-bytes");
    }
}
