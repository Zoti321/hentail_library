use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::{
    create_local_library, init_db_at_path, list_libraries, update_library_sidebar_layout,
    LibrarySidebarPlacement,
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

fn create_fixture_db(dir: &Path) -> PathBuf {
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

fn mkdir_lib(dir: &Path, name: &str) -> PathBuf {
    let root = dir.join(name);
    std::fs::create_dir_all(&root).expect("mkdir");
    root
}

#[test]
fn new_libraries_are_pinned_and_append_in_create_order() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let zebra = mkdir_lib(temp.path(), "zebra");
        let apple = mkdir_lib(temp.path(), "apple");

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let first = create_local_library(&zebra.to_string_lossy(), Some("Zebra"))
                .await
                .expect("zebra");
            let second = create_local_library(&apple.to_string_lossy(), Some("Apple"))
                .await
                .expect("apple");

            let listed = list_libraries().await.expect("list");
            assert_eq!(listed.len(), 2);
            assert_eq!(listed[0].library_id, first.library_id);
            assert_eq!(listed[1].library_id, second.library_id);
            assert!(listed[0].pinned);
            assert!(listed[1].pinned);
            assert_eq!(listed[0].sidebar_order, 0);
            assert_eq!(listed[1].sidebar_order, 1);
        });
    });
}

#[test]
fn list_libraries_returns_pinned_then_unpinned_by_sidebar_order() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let a = mkdir_lib(temp.path(), "a");
        let b = mkdir_lib(temp.path(), "b");
        let c = mkdir_lib(temp.path(), "c");

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib_a = create_local_library(&a.to_string_lossy(), Some("A"))
                .await
                .expect("a");
            let lib_b = create_local_library(&b.to_string_lossy(), Some("B"))
                .await
                .expect("b");
            let lib_c = create_local_library(&c.to_string_lossy(), Some("C"))
                .await
                .expect("c");

            update_library_sidebar_layout(vec![
                LibrarySidebarPlacement {
                    library_id: lib_c.library_id.clone(),
                    pinned: true,
                    sidebar_order: 0,
                },
                LibrarySidebarPlacement {
                    library_id: lib_a.library_id.clone(),
                    pinned: true,
                    sidebar_order: 1,
                },
                LibrarySidebarPlacement {
                    library_id: lib_b.library_id.clone(),
                    pinned: false,
                    sidebar_order: 0,
                },
            ])
            .await
            .expect("reorder");

            let listed = list_libraries().await.expect("list");
            assert_eq!(
                listed.iter().map(|l| l.name.as_str()).collect::<Vec<_>>(),
                vec!["C", "A", "B"]
            );
            assert!(listed[0].pinned);
            assert!(listed[1].pinned);
            assert!(!listed[2].pinned);
        });
    });
}

#[test]
fn new_library_appends_to_pinned_end_when_unpinned_exist() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let a = mkdir_lib(temp.path(), "a");
        let b = mkdir_lib(temp.path(), "b");
        let c = mkdir_lib(temp.path(), "c");

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib_a = create_local_library(&a.to_string_lossy(), Some("A"))
                .await
                .expect("a");
            let lib_b = create_local_library(&b.to_string_lossy(), Some("B"))
                .await
                .expect("b");

            update_library_sidebar_layout(vec![
                LibrarySidebarPlacement {
                    library_id: lib_a.library_id.clone(),
                    pinned: true,
                    sidebar_order: 0,
                },
                LibrarySidebarPlacement {
                    library_id: lib_b.library_id.clone(),
                    pinned: false,
                    sidebar_order: 0,
                },
            ])
            .await
            .expect("unpin b");

            let lib_c = create_local_library(&c.to_string_lossy(), Some("C"))
                .await
                .expect("c");

            let listed = list_libraries().await.expect("list");
            assert_eq!(
                listed.iter().map(|l| l.name.as_str()).collect::<Vec<_>>(),
                vec!["A", "C", "B"]
            );
            assert_eq!(lib_c.pinned, true);
            assert_eq!(lib_c.sidebar_order, 1);
            assert!(!listed[2].pinned);
        });
    });
}

#[test]
fn update_library_sidebar_layout_rejects_incomplete_set() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let a = mkdir_lib(temp.path(), "a");
        let b = mkdir_lib(temp.path(), "b");

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib_a = create_local_library(&a.to_string_lossy(), Some("A"))
                .await
                .expect("a");
            create_local_library(&b.to_string_lossy(), Some("B"))
                .await
                .expect("b");

            let err = update_library_sidebar_layout(vec![LibrarySidebarPlacement {
                library_id: lib_a.library_id.clone(),
                pinned: true,
                sidebar_order: 0,
            }])
            .await
            .expect_err("incomplete");
            assert!(err.to_string().contains("Library sidebar"));
        });
    });
}

#[test]
fn saved_paths_migrate_to_pinned_in_root_path_order() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let zebra = mkdir_lib(temp.path(), "zebra");
        let apple = mkdir_lib(temp.path(), "apple");
        let db_path = create_fixture_db(temp.path());

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            let conn = Database::connect(format!(
                "sqlite://{}?mode=rwc",
                db_path.to_string_lossy().replace('\\', "/")
            ))
            .await
            .expect("connect");
            for raw_path in [zebra.to_string_lossy().to_string(), apple.to_string_lossy().to_string()]
            {
                conn.execute(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "INSERT OR IGNORE INTO saved_paths (raw_path, security_bookmark) VALUES (?, NULL)",
                    [sea_orm::Value::String(Some(Box::new(raw_path)))],
                ))
                .await
                .expect("insert path");
            }

            init_db_at_path(&db_path).await.expect("init");
            let listed = list_libraries().await.expect("list");
            assert_eq!(listed.len(), 2);
            assert!(listed.iter().all(|l| l.pinned));
            let names: Vec<&str> = listed.iter().map(|l| l.name.as_str()).collect();
            assert_eq!(names, vec!["apple", "zebra"]);
            assert_eq!(listed[0].sidebar_order, 0);
            assert_eq!(listed[1].sidebar_order, 1);
        });
    });
}
