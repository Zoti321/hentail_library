use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::{
    connection, find_comic_by_id, init_db_at_path, set_comic_meta_locks, update_comic_user_meta,
    SetComicMetaLocksDto, UpdateComicUserMetaDto,
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
    let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    fs::read_to_string(manifest_dir.join("../../tests/fixtures/drift_v2.sql"))
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

async fn seed_comic(db: &impl ConnectionTrait) {
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM comic_tags; DELETE FROM comic_authors; DELETE FROM comic_meta; DELETE FROM comics"
            .to_string(),
    ))
    .await
    .expect("clear");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
         VALUES ('c1', 'E:/lib/a.cbz', 'cbz', 1, 1, 1)"
            .to_string(),
    ))
    .await
    .expect("seed comic");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
         VALUES ('c1', 'Old', 'unknown', 1)"
            .to_string(),
    ))
    .await
    .expect("seed meta");
}

#[test]
fn update_comic_user_meta_locks_only_written_fields() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_comic(&db).await;

            update_comic_user_meta(
                "c1",
                UpdateComicUserMetaDto {
                    title: Some("新标题".to_string()),
                    ..Default::default()
                },
            )
            .await
            .expect("update");

            let comic = find_comic_by_id("c1")
                .await
                .expect("find")
                .expect("exists");
            assert_eq!(comic.title, "新标题");
            assert!(comic.locks.title);
            assert!(!comic.locks.description);
            assert!(!comic.locks.content_rating);
            assert!(!comic.locks.authors);
            assert!(!comic.locks.tags);
        });
    });
}

#[test]
fn set_comic_meta_locks_changes_flags_without_changing_values() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_comic(&db).await;

            update_comic_user_meta(
                "c1",
                UpdateComicUserMetaDto {
                    title: Some("锁定标题".to_string()),
                    ..Default::default()
                },
            )
            .await
            .expect("update");

            set_comic_meta_locks(
                "c1",
                SetComicMetaLocksDto {
                    title: Some(false),
                    description: Some(true),
                    ..Default::default()
                },
            )
            .await
            .expect("set locks");

            let comic = find_comic_by_id("c1")
                .await
                .expect("find")
                .expect("exists");
            assert_eq!(comic.title, "锁定标题");
            assert!(!comic.locks.title);
            assert!(comic.locks.description);
        });
    });
}
