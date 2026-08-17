use std::path::PathBuf;
use std::sync::Mutex;

use hentai_core::sync::format_group::FormatGroup;
use hentai_core::{
    connection, create_remote_library, delete_library, init_db_at_path, list_libraries,
    update_remote_library,
};
use sea_orm::{ConnectionTrait, Database, Statement};
use tempfile::TempDir;

static DB_INIT_LOCK: Mutex<()> = Mutex::new(());

fn with_global_db(test: impl FnOnce()) {
    let _guard = DB_INIT_LOCK
        .lock()
        .expect("global db tests must run serially");
    test();
}

fn fixture_sql() -> String {
    std::fs::read_to_string(
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/fixtures/drift_v2.sql"),
    )
    .expect("read drift_v2.sql")
}

fn create_fixture_db(dir: &std::path::Path) -> PathBuf {
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

#[test]
fn create_remote_library_defaults_https_and_remote_format_groups() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");

            let lib = create_remote_library(
                "nas.local/webdav/comics",
                "alice",
                false,
                None,
            )
            .await
            .expect("create remote");

            assert_eq!(lib.kind, "remote");
            assert_eq!(lib.root_path, "https://nas.local/webdav/comics");
            assert_eq!(lib.username, "alice");
            assert!(!lib.allow_http);
            assert_eq!(
                lib.enabled_format_groups,
                vec![FormatGroup::Pdf, FormatGroup::Epub, FormatGroup::Archive]
            );

            let db = connection().expect("db");
            let row = db
                .query_one(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT username, allow_http, kind FROM libraries WHERE library_id = ?",
                    [sea_orm::Value::String(Some(Box::new(lib.library_id.clone())))],
                ))
                .await
                .expect("query")
                .expect("row");
            let username: String = row.try_get_by_index(0).expect("username");
            let allow_http: i64 = row.try_get_by_index(1).expect("allow_http");
            let kind: String = row.try_get_by_index(2).expect("kind");
            assert_eq!(username, "alice");
            assert_eq!(allow_http, 0);
            assert_eq!(kind, "remote");

            // Password must never be persisted in SQLite.
            let dump = db
                .query_all(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT sql FROM sqlite_master WHERE type='table' AND name='libraries'"
                        .to_string(),
                ))
                .await
                .expect("schema");
            let schema = format!("{dump:?}").to_ascii_lowercase();
            assert!(!schema.contains("password"));
        });
    });
}

#[test]
fn http_remote_root_requires_explicit_allow() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");

            let denied = create_remote_library("http://nas.local/dav", "u", false, None).await;
            assert!(denied.is_err(), "http without allow must fail");

            let allowed = create_remote_library("http://nas.local/dav", "u", true, None)
                .await
                .expect("http with allow");
            assert_eq!(allowed.root_path, "http://nas.local/dav");
            assert!(allowed.allow_http);
        });
    });
}

#[test]
fn recreate_same_remote_root_updates_metadata() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");

            let first = create_remote_library("https://nas.local/dav", "old", false, None)
                .await
                .expect("create");
            let second = create_remote_library("https://nas.local/dav", "new", true, None)
                .await
                .expect("recreate");

            assert_eq!(second.library_id, first.library_id);
            assert_eq!(second.username, "new");
            assert!(second.allow_http);
        });
    });
}

#[test]
fn update_and_delete_remote_library_keeps_id_and_clears_row() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");

            let created = create_remote_library("https://a.example/dav", "old", false, None)
                .await
                .expect("create");
            let updated = update_remote_library(
                &created.library_id,
                "https://b.example/comics",
                "new",
                true,
            )
            .await
            .expect("update");

            assert_eq!(updated.library_id, created.library_id);
            assert_eq!(updated.root_path, "https://b.example/comics");
            assert_eq!(updated.username, "new");
            assert!(updated.allow_http);

            delete_library(&created.library_id).await.expect("delete");
            let remaining = list_libraries().await.expect("list");
            assert!(remaining.iter().all(|l| l.library_id != created.library_id));
        });
    });
}
