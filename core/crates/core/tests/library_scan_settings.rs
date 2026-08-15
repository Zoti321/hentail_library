use std::path::PathBuf;
use std::sync::Mutex;

use hentai_core::sync::format_group::FormatGroup;
use hentai_core::{
    create_local_library, create_remote_library, init_db_at_path, list_libraries,
    parse_scan_interval, update_library_settings, ScanInterval,
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
fn new_local_library_defaults_scan_settings_off() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let root = temp.path().join("lib_root");
        std::fs::create_dir_all(&root).expect("mkdir");

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib = create_local_library(&root.to_string_lossy(), None)
                .await
                .expect("create");
            assert!(!lib.scan_on_startup);
            assert_eq!(lib.scan_interval, ScanInterval::Disabled);
            assert_eq!(lib.name, "lib_root");
        });
    });
}

#[test]
fn create_local_library_accepts_optional_name() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let root = temp.path().join("disk_folder");
        std::fs::create_dir_all(&root).expect("mkdir");

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib = create_local_library(&root.to_string_lossy(), Some("My Library"))
                .await
                .expect("create");
            assert_eq!(lib.name, "My Library");
            assert_eq!(lib.root_path, root.to_string_lossy());
        });
    });
}

#[test]
fn update_library_settings_renames_without_changing_identity_or_root() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let root = temp.path().join("lib_root");
        std::fs::create_dir_all(&root).expect("mkdir");

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let created = create_local_library(&root.to_string_lossy(), None)
                .await
                .expect("create");
            let updated = update_library_settings(
                &created.library_id,
                "Renamed",
                vec![FormatGroup::Pdf, FormatGroup::Archive],
                true,
                ScanInterval::Daily,
            )
            .await
            .expect("update");

            assert_eq!(updated.library_id, created.library_id);
            assert_eq!(updated.root_path, created.root_path);
            assert_eq!(updated.name, "Renamed");
            assert!(updated.scan_on_startup);
            assert_eq!(updated.scan_interval, ScanInterval::Daily);
            assert_eq!(
                updated.enabled_format_groups,
                vec![FormatGroup::Pdf, FormatGroup::Archive]
            );
        });
    });
}

#[test]
fn update_library_settings_rejects_invalid_interval_string_helper() {
    assert!(parse_scan_interval("disabled").is_ok());
    assert!(parse_scan_interval("hourly").is_ok());
    assert!(parse_scan_interval("every_6_hours").is_ok());
    assert!(parse_scan_interval("every_12_hours").is_ok());
    assert!(parse_scan_interval("daily").is_ok());
    assert!(parse_scan_interval("weekly").is_ok());
    assert!(parse_scan_interval("monthly").is_err());
    assert!(parse_scan_interval("").is_err());
}

#[test]
fn remote_library_shares_scan_setting_defaults() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib = create_remote_library(
                "https://example.com/dav/comics",
                "user",
                false,
                None,
            )
            .await
            .expect("create remote");
            assert!(!lib.scan_on_startup);
            assert_eq!(lib.scan_interval, ScanInterval::Disabled);
            assert_eq!(lib.kind, "remote");
        });
    });
}

#[test]
fn set_all_libraries_scan_on_startup_enables_every_library() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let root_a = temp.path().join("a");
        let root_b = temp.path().join("b");
        std::fs::create_dir_all(&root_a).expect("mkdir a");
        std::fs::create_dir_all(&root_b).expect("mkdir b");

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            create_local_library(&root_a.to_string_lossy(), None)
                .await
                .expect("a");
            create_local_library(&root_b.to_string_lossy(), None)
                .await
                .expect("b");

            hentai_core::set_all_libraries_scan_on_startup(true)
                .await
                .expect("migrate");

            let libs = list_libraries().await.expect("list");
            assert_eq!(libs.len(), 2);
            assert!(libs.iter().all(|l| l.scan_on_startup));
        });
    });
}
