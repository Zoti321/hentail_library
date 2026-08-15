use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::{
    create_local_library, init_db_at_path, list_libraries, update_local_library_root,
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

#[test]
fn update_local_library_root_keeps_library_id_and_rejects_nesting() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let root_a = temp.path().join("lib_a");
        let root_b = temp.path().join("lib_b");
        let root_a_child = root_a.join("nested");
        let root_b_child = root_b.join("child");
        let root_a_moved = temp.path().join("lib_a_moved");
        std::fs::create_dir_all(&root_a).expect("mkdir a");
        std::fs::create_dir_all(&root_b).expect("mkdir b");
        std::fs::create_dir_all(&root_a_child).expect("mkdir nested");
        std::fs::create_dir_all(&root_b_child).expect("mkdir b/child");
        std::fs::create_dir_all(&root_a_moved).expect("mkdir moved");

        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");

            let lib_a = create_local_library(&root_a.to_string_lossy(), Some("Alpha"))
                .await
                .expect("create a");
            let _lib_b = create_local_library(&root_b.to_string_lossy(), Some("Beta"))
                .await
                .expect("create b");

            let nested_other = update_local_library_root(
                &lib_a.library_id,
                &root_b_child.to_string_lossy(),
            )
            .await
            .expect_err("nested under other library should fail");
            assert!(
                nested_other.to_string().contains("嵌套"),
                "unexpected: {nested_other}"
            );

            // Moving into a child of the current root is allowed (Komga warns; sync may orphan).
            let into_child = update_local_library_root(
                &lib_a.library_id,
                &root_a_child.to_string_lossy(),
            )
            .await
            .expect("move into own child");
            assert_eq!(into_child.library_id, lib_a.library_id);

            let updated = update_local_library_root(
                &lib_a.library_id,
                &root_a_moved.to_string_lossy(),
            )
            .await
            .expect("move root");
            assert_eq!(updated.library_id, lib_a.library_id);
            assert_eq!(updated.name, "Alpha");
            assert_eq!(
                updated.root_path.replace('\\', "/"),
                root_a_moved.to_string_lossy().replace('\\', "/")
            );

            let listed = list_libraries().await.expect("list");
            let again = listed
                .iter()
                .find(|l| l.library_id == lib_a.library_id)
                .expect("still present");
            assert_eq!(
                again.root_path.replace('\\', "/"),
                updated.root_path.replace('\\', "/")
            );
        });
    });
}
