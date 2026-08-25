use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::{
    comic_id_from_path, create_local_library, find_comic_by_id, init_db_at_path, set_current_library_id,
    sync_library, SyncLibraryPhaseDto, SyncLibraryProgressDto, SyncScanMode, create_sync_handle,
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

fn write_image_comic(dir: &Path) {
    std::fs::create_dir_all(dir).expect("mkdir comic");
    std::fs::write(dir.join("01.jpg"), b"fake-jpeg").expect("jpg");
}

fn last_done(events: &[SyncLibraryProgressDto]) -> &SyncLibraryProgressDto {
    events
        .iter()
        .rev()
        .find(|e| e.phase == SyncLibraryPhaseDto::Done)
        .expect("Done progress")
}

#[test]
fn local_sync_missing_root_ends_with_warning_not_silent_empty_align() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let missing = temp.path().join("does_not_exist");

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib = create_local_library(&missing.to_string_lossy(), Some("Missing"))
                .await
                .expect("create");
            set_current_library_id(Some(&lib.library_id))
                .await
                .expect("current");

            let handle = create_sync_handle();
            let mut events = Vec::new();
            sync_library(
                handle,
                SyncScanMode::Full,
                false,
                None,
                vec![],
                |p| events.push(p),
            )
            .await
            .expect("sync");

            let done = last_done(&events);
            let message = done
                .error_message
                .as_deref()
                .expect("must surface unreadability, not silent empty success");
            assert!(
                message.contains("本地库"),
                "warning should name local root unreadability, got {message}"
            );
            assert!(
                done.removed_count.is_none() && done.added_count.is_none(),
                "must not report an empty replace plan when the root cannot be read"
            );
        });
    });
}

#[test]
fn local_sync_unreadable_root_keeps_existing_comics() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let root = temp.path().join("lib");
        std::fs::create_dir_all(&root).expect("mkdir");
        let comic_dir = root.join("vol1");
        write_image_comic(&comic_dir);

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib = create_local_library(&root.to_string_lossy(), Some("Lib"))
                .await
                .expect("create");
            set_current_library_id(Some(&lib.library_id))
                .await
                .expect("current");

            let handle = create_sync_handle();
            sync_library(handle, SyncScanMode::Full, false, None, vec![], |_| {})
                .await
                .expect("first sync");
            let comic_id = comic_id_from_path(&comic_dir.to_string_lossy());
            assert!(find_comic_by_id(&comic_id).await.unwrap().is_some());

            std::fs::remove_dir_all(&root).expect("remove root");

            let handle = create_sync_handle();
            let mut events = Vec::new();
            sync_library(
                handle,
                SyncScanMode::Full,
                false,
                None,
                vec![],
                |p| events.push(p),
            )
            .await
            .expect("second sync");

            let done = last_done(&events);
            assert!(
                done.error_message.as_ref().is_some_and(|m| !m.is_empty()),
                "must warn when the saved root is gone or unreadable"
            );
            assert!(
                find_comic_by_id(&comic_id).await.unwrap().is_some(),
                "must not orphan-delete comics when the root cannot be read"
            );
        });
    });
}
