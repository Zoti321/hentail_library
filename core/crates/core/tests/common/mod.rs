//! Shared DB fixture helpers for hentai-core integration tests.
//!
//! New integration tests must use these helpers instead of copying
//! `DB_INIT_LOCK` / `create_fixture_db` boilerplate.

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
