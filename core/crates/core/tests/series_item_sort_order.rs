use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::sync::series_rebuild::rebuild_series_from_comics;
use hentai_core::{
    connection, find_series_by_id, init_db_at_path, set_series_item_sort_order_locked,
    update_series_item_sort_order,
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

async fn seed_three_comics(db: &DatabaseConnection) {
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM series_items; DELETE FROM series; DELETE FROM comic_meta; DELETE FROM comics"
            .to_string(),
    ))
    .await
    .expect("clear");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
         VALUES ('c1', 'E:/lib/Series/vol1.cbz', 'cbz', 1, 1, 1), \
                ('c2', 'E:/lib/Series/vol2.cbz', 'cbz', 1, 1, 1), \
                ('c3', 'E:/lib/Series/vol3.cbz', 'cbz', 1, 1, 1)"
            .to_string(),
    ))
    .await
    .expect("seed comics");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
         VALUES ('c1', 'Vol1', 'unknown', 1), \
                ('c2', 'Vol2', 'unknown', 1), \
                ('c3', 'Vol3', 'unknown', 1)"
            .to_string(),
    ))
    .await
    .expect("seed meta");
}

#[test]
fn update_series_item_sort_order_sets_value_locks_and_reorders() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_three_comics(&db).await;
            rebuild_series_from_comics(&db, None).await.expect("rebuild");

            let series = find_series_by_id(
                &hentai_core::series_id_from_folder_path("E:/lib/Series"),
            )
            .await
            .expect("find")
            .expect("series exists");
            assert_eq!(series.items.len(), 3);

            update_series_item_sort_order(&series.series_id, "c3", 1.5)
                .await
                .expect("update sort order");

            let series = find_series_by_id(&series.series_id)
                .await
                .expect("find")
                .expect("series exists");
            let by_id: std::collections::HashMap<&str, &hentai_core::SeriesItemDto> = series
                .items
                .iter()
                .map(|i| (i.comic_id.as_str(), i))
                .collect();
            let c3 = by_id.get("c3").expect("c3");
            assert!((c3.sort_order - 1.5).abs() < f64::EPSILON);
            assert!(c3.sort_order_locked);

            let ordered: Vec<&str> = series.items.iter().map(|i| i.comic_id.as_str()).collect();
            assert_eq!(ordered, vec!["c1", "c3", "c2"]);
        });
    });
}

#[test]
fn rebuild_preserves_locked_sort_order_and_renumbers_unlocked() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_three_comics(&db).await;
            rebuild_series_from_comics(&db, None).await.expect("rebuild");

            let series_id = hentai_core::series_id_from_folder_path("E:/lib/Series");
            update_series_item_sort_order(&series_id, "c2", 2.5)
                .await
                .expect("lock c2 at 2.5");

            // New comic sorts between vol2 and vol3 by filename (vol2a after vol2, before vol3).
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
                 VALUES ('c2a', 'E:/lib/Series/vol2a.cbz', 'cbz', 1, 1, 1)"
                    .to_string(),
            ))
            .await
            .expect("insert comic");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
                 VALUES ('c2a', 'Vol2a', 'unknown', 1)"
                    .to_string(),
            ))
            .await
            .expect("insert meta");

            rebuild_series_from_comics(&db, None).await.expect("rebuild again");

            let series = find_series_by_id(&series_id)
                .await
                .expect("find")
                .expect("series exists");
            let by_id: std::collections::HashMap<&str, &hentai_core::SeriesItemDto> = series
                .items
                .iter()
                .map(|i| (i.comic_id.as_str(), i))
                .collect();

            let c2 = by_id.get("c2").expect("c2");
            assert!((c2.sort_order - 2.5).abs() < f64::EPSILON);
            assert!(c2.sort_order_locked);

            // Natural order: vol1, vol2, vol2a, vol3 → unlocked get 1,2,3,4; c2 stays 2.5 locked.
            assert!((by_id.get("c1").expect("c1").sort_order - 1.0).abs() < f64::EPSILON);
            assert!(!by_id.get("c1").expect("c1").sort_order_locked);
            assert!((by_id.get("c2a").expect("c2a").sort_order - 3.0).abs() < f64::EPSILON);
            assert!(!by_id.get("c2a").expect("c2a").sort_order_locked);
            assert!((by_id.get("c3").expect("c3").sort_order - 4.0).abs() < f64::EPSILON);
            assert!(!by_id.get("c3").expect("c3").sort_order_locked);
        });
    });
}

#[test]
fn unlock_sort_order_allows_rebuild_to_renumber() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_three_comics(&db).await;
            rebuild_series_from_comics(&db, None).await.expect("rebuild");

            let series_id = hentai_core::series_id_from_folder_path("E:/lib/Series");
            update_series_item_sort_order(&series_id, "c3", 1.5)
                .await
                .expect("lock c3");

            set_series_item_sort_order_locked(&series_id, "c3", false)
                .await
                .expect("unlock c3");

            rebuild_series_from_comics(&db, None).await.expect("rebuild again");

            let series = find_series_by_id(&series_id)
                .await
                .expect("find")
                .expect("series exists");
            let by_id: std::collections::HashMap<&str, &hentai_core::SeriesItemDto> = series
                .items
                .iter()
                .map(|i| (i.comic_id.as_str(), i))
                .collect();
            assert!((by_id.get("c3").expect("c3").sort_order - 3.0).abs() < f64::EPSILON);
            assert!(!by_id.get("c3").expect("c3").sort_order_locked);
            let ordered: Vec<&str> = series.items.iter().map(|i| i.comic_id.as_str()).collect();
            assert_eq!(ordered, vec!["c1", "c2", "c3"]);
        });
    });
}
