//! Shared DB fixture helpers for hentai-core integration tests.
//!
//! New integration tests must use these helpers instead of copying
//! `DB_INIT_LOCK` / `create_fixture_db` boilerplate.
//!
//! Each integration test binary compiles this module separately and uses only
//! a subset of helpers.
#![allow(dead_code)]

use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use sea_orm::{ConnectionTrait, Database, Statement};

static DB_INIT_LOCK: Mutex<()> = Mutex::new(());

/// Serializes tests that mutate the process-global DB connection.
pub fn with_global_db(test: impl FnOnce()) {
    let _guard = DB_INIT_LOCK
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner());
    test();
}

/// SQL fixture used by drift-v2 takeover / catalog integration tests.
pub fn fixture_sql() -> String {
    let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    fs::read_to_string(manifest_dir.join("../../tests/fixtures/drift_v2.sql"))
        .expect("read drift_v2.sql")
}

/// Creates a SQLite file under [dir] seeded from [fixture_sql].
pub fn create_fixture_db(dir: &Path) -> PathBuf {
    let db_path = dir.join("fixture.sqlite");
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        let conn = Database::connect(format!(
            "sqlite://{}?mode=rwc",
            db_path.to_string_lossy().replace('\\', "/")
        ))
        .await
        .expect("connect");
        for stmt in fixture_sql().split(';') {
            let sql = stmt.trim();
            if sql.is_empty() || sql.starts_with("--") {
                continue;
            }
            conn.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                sql.to_string(),
            ))
            .await
            .expect("execute sql");
        }
    });
    db_path
}

/// Writes a minimal CBZ (`pages` stored page entries) at [path].
pub fn write_cbz(path: &Path, pages: usize) {
    use std::io::Write as _;

    fs::create_dir_all(path.parent().expect("parent")).expect("mkdir");
    let file = fs::File::create(path).expect("create cbz");
    let mut archive = zip::ZipWriter::new(file);
    let options =
        zip::write::SimpleFileOptions::default().compression_method(zip::CompressionMethod::Stored);
    for page in 0..pages {
        archive
            .start_file(format!("{page:03}.jpg"), options)
            .expect("start");
        archive.write_all(b"page").expect("write");
    }
    archive.finish().expect("finish");
}

/// Creates a Local library holding [comics] (`(relative path, page count)`) and syncs it.
///
/// Runs under [with_global_db] and hands the synced library plus the setup runtime
/// to [test], so the caller can `runtime.block_on` the assertions.
pub fn with_local_library<F>(db_file: &str, comics: &[(&str, usize)], test: F)
where
    F: FnOnce(hentai_core::LibraryDto, &tokio::runtime::Runtime),
{
    with_global_db(|| {
        let temp = tempfile::TempDir::new().expect("tempdir");
        let root = temp.path().join("lib");
        for (relative, pages) in comics {
            write_cbz(&root.join(relative), *pages);
        }
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        let library = runtime.block_on(async {
            hentai_core::init_db_at_path(&temp.path().join(db_file))
                .await
                .expect("init db");
            let library = hentai_core::create_local_library(&root.to_string_lossy(), Some("Lib"))
                .await
                .expect("create local library");
            hentai_core::set_current_library_id(Some(&library.library_id))
                .await
                .expect("set current library");
            hentai_core::sync_library(
                hentai_core::create_sync_handle(),
                hentai_core::SyncScanMode::Full,
                false,
                Some(library.library_id.as_str()),
                vec![],
                |_| {},
            )
            .await
            .expect("sync local library");
            library
        });
        test(library, &runtime);
    });
}
