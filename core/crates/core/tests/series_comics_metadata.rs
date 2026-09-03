use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::{
    connection, fetch_series_comics_metadata, init_db_at_path, update_comic_user_meta,
    UpdateComicUserMetaDto,
};
use sea_orm::{ConnectionTrait, Database, DatabaseConnection, Statement};
use tempfile::TempDir;

/// `init_db_at_path` 使用进程级全局连接，并行测试会互相覆盖。
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

async fn clear_library(db: &DatabaseConnection) {
    for table in [
        "series_items",
        "series",
        "comic_tags",
        "comic_authors",
        "comic_parodies",
        "comic_characters",
        "comic_meta",
        "comics",
        "parodies",
        "characters",
        "authors",
        "tags",
    ] {
        db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!("DELETE FROM {table}"),
        ))
        .await
        .expect("clear table");
    }
}

async fn seed_series_with_three_comics(db: &DatabaseConnection) {
    clear_library(db).await;
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
         VALUES ('c1', 'E:/lib/Series/a.cbz', 'cbz', 1, 1, 1), \
                ('c2', 'E:/lib/Series/b.cbz', 'cbz', 1, 1, 1), \
                ('c3', 'E:/lib/Series/c.cbz', 'cbz', 1, 1, 1)"
            .to_string(),
    ))
    .await
    .expect("seed comics");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
         VALUES ('c1', 'A', 'unknown', 1), ('c2', 'B', 'unknown', 1), ('c3', 'C', 'unknown', 1)"
            .to_string(),
    ))
    .await
    .expect("seed meta");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO series (series_id, folder_path, name, serialization_status, total_count) \
         VALUES ('s1', 'E:/lib/Series', 'Series', 'unknown', NULL)"
            .to_string(),
    ))
    .await
    .expect("seed series");
    // Member order deliberately not alphabetical by comic_id: c2 → c3 → c1
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO series_items (series_id, comic_id, sort_order) \
         VALUES ('s1', 'c2', 0), ('s1', 'c3', 1), ('s1', 'c1', 2)"
            .to_string(),
    ))
    .await
    .expect("seed items");
}

#[test]
fn fetch_series_comics_metadata_aggregates_language_parody_character_first_seen_by_member_order() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_series_with_three_comics(&db).await;

            // Member walk order: c2 → c3 → c1. Names chosen so alphabetical ≠ first-seen.
            update_comic_user_meta(
                "c2",
                UpdateComicUserMetaDto {
                    languages: Some(vec!["Japanese".to_string(), "Chinese".to_string()]),
                    parodies: Some(vec!["Zebra".to_string()]),
                    characters: Some(vec!["Zelda".to_string()]),
                    ..Default::default()
                },
            )
            .await
            .expect("update c2");
            update_comic_user_meta(
                "c3",
                UpdateComicUserMetaDto {
                    languages: Some(vec!["Chinese".to_string(), "English".to_string()]),
                    parodies: Some(vec!["Apple".to_string(), "Zebra".to_string()]),
                    characters: Some(vec!["Alice".to_string(), "Zelda".to_string()]),
                    ..Default::default()
                },
            )
            .await
            .expect("update c3");
            update_comic_user_meta(
                "c1",
                UpdateComicUserMetaDto {
                    languages: Some(vec!["Korean".to_string()]),
                    parodies: Some(vec!["Mango".to_string()]),
                    characters: Some(vec!["Bob".to_string()]),
                    ..Default::default()
                },
            )
            .await
            .expect("update c1");

            let metadata = fetch_series_comics_metadata("s1")
                .await
                .expect("fetch metadata");

            assert_eq!(
                metadata.languages,
                vec![
                    "Japanese".to_string(),
                    "Chinese".to_string(),
                    "English".to_string(),
                    "Korean".to_string(),
                ],
                "languages: member order + first-seen (not alpha)"
            );
            // Within each comic, Parody/Character are read alphabetically; across members = first-seen.
            assert_eq!(
                metadata.parodies,
                vec![
                    "Zebra".to_string(),
                    "Apple".to_string(),
                    "Mango".to_string(),
                ],
                "parodies: member order + first-seen (not alpha)"
            );
            assert_eq!(
                metadata.characters,
                vec![
                    "Zelda".to_string(),
                    "Alice".to_string(),
                    "Bob".to_string(),
                ],
                "characters: member order + first-seen (not alpha)"
            );
        });
    });
}

#[test]
fn fetch_series_comics_metadata_omits_empty_language_parody_character() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_series_with_three_comics(&db).await;

            let metadata = fetch_series_comics_metadata("s1")
                .await
                .expect("fetch metadata");

            assert!(metadata.languages.is_empty());
            assert!(metadata.parodies.is_empty());
            assert!(metadata.characters.is_empty());
        });
    });
}
