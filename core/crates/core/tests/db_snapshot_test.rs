mod common;

use std::fs;
use std::path::Path;

use hentai_core::init_db_at_path;
use rusqlite::Connection;
use tempfile::TempDir;

fn snapshot_paths(dir: &Path) -> Vec<std::path::PathBuf> {
    let snapshot_dir = dir.join("internal_db_snapshots");
    if !snapshot_dir.is_dir() {
        return Vec::new();
    }
    fs::read_dir(&snapshot_dir)
        .expect("read snapshot dir")
        .filter_map(|entry| entry.ok())
        .map(|entry| entry.path())
        .filter(|path| path.is_file())
        .collect()
}

#[test]
fn init_db_creates_internal_snapshot_before_migration() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
        });

        let snapshots = snapshot_paths(temp.path());
        assert_eq!(snapshots.len(), 1, "expected one pre-migration snapshot");
        let conn = Connection::open(&snapshots[0]).expect("open snapshot");
        let count: i64 = conn
            .query_row("SELECT COUNT(*) FROM comics", [], |row| row.get(0))
            .expect("query comics");
        assert!(count >= 3, "snapshot should preserve drift_v2 comics");
    });
}

#[test]
fn init_db_skips_snapshot_when_no_pending_migration() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("already_migrated.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("first init");
            init_db_at_path(&db_path).await.expect("second init");
        });

        let snapshots = snapshot_paths(temp.path());
        assert!(
            snapshots.is_empty(),
            "fully migrated db should not create snapshots"
        );
    });
}
