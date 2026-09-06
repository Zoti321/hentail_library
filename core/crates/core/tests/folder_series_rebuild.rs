use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::sync::series_rebuild::rebuild_series_from_comics;
use hentai_core::{
    connection, find_series_by_id, init_db_at_path, set_series_meta_locks,
    update_series_user_meta, SetSeriesMetaLocksDto, UpdateSeriesUserMetaDto,
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

async fn seed_minimal_comics(db: &DatabaseConnection) {
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM series_items".to_string(),
    ))
    .await
    .expect("clear items");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM series".to_string(),
    ))
    .await
    .expect("clear series");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM comic_meta".to_string(),
    ))
    .await
    .expect("clear meta");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM comics".to_string(),
    ))
    .await
    .expect("clear comics");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
         VALUES ('c1', 'E:/lib/Series/a.cbz', 'cbz', 1, 1, 1), \
                ('c2', 'E:/lib/Series/b.cbz', 'cbz', 1, 1, 1)"
            .to_string(),
    ))
    .await
    .expect("seed comics");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
         VALUES ('c1', 'A', 'unknown', 1), ('c2', 'B', 'unknown', 1)"
            .to_string(),
    ))
    .await
    .expect("seed meta");
}

#[test]
fn rebuild_series_groups_comics_by_parent_folder() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_minimal_comics(&db).await;
            rebuild_series_from_comics(&db, None).await.expect("rebuild");

            let row = db
                .query_one(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT COUNT(*) FROM series".to_string(),
                ))
                .await
                .expect("count series")
                .expect("row");
            let series_count: i64 = row.try_get_by_index(0).expect("count");
            assert_eq!(series_count, 1);

            let items = db
                .query_all(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT sort_order FROM series_items ORDER BY sort_order".to_string(),
                ))
                .await
                .expect("items");
            assert_eq!(items.len(), 2);
        });
    });
}

#[test]
fn update_series_user_meta_preserves_fields_on_rebuild() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
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
                 VALUES ('c1', 'E:/lib/Series/a.cbz', 'cbz', 1, 1, 1)"
                    .to_string(),
            ))
            .await
            .expect("seed comic");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
                 VALUES ('c1', 'A', 'unknown', 1)"
                    .to_string(),
            ))
            .await
            .expect("seed meta");
            rebuild_series_from_comics(&db, None).await.expect("rebuild");

            let series_id: String = db
                .query_one(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT series_id FROM series LIMIT 1".to_string(),
                ))
                .await
                .expect("query")
                .expect("row")
                .try_get_by_index(0)
                .expect("id");

            update_series_user_meta(
                &series_id,
                UpdateSeriesUserMetaDto {
                    name: Some("自定义系列名".to_string()),
                    serialization_status: Some("ongoing".to_string()),
                    total_count: Some(12),
                    clear_total_count: false,
                },
            )
            .await
            .expect("update meta");

            rebuild_series_from_comics(&connection().expect("connection"), None)
                .await
                .expect("rebuild again");

            let row = db
                .query_one(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    format!(
                        "SELECT name, serialization_status, total_count FROM series WHERE series_id = '{series_id}'"
                    ),
                ))
                .await
                .expect("query")
                .expect("row");
            let name: String = row.try_get_by_index(0).expect("name");
            let status: String = row.try_get_by_index(1).expect("status");
            let total: Option<i32> = row.try_get_by_index(2).expect("total");
            assert_eq!(name, "自定义系列名");
            assert_eq!(status, "ongoing");
            assert_eq!(total, Some(12));
            let series = find_series_by_id(&series_id)
                .await
                .expect("find")
                .expect("series");
            assert!(series.locks.name);
            assert!(series.locks.serialization_status);
            assert!(series.locks.total_count);
        });
    });
}

#[test]
fn rebuild_migrates_comic_between_folder_series_without_unique_conflict() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "DELETE FROM series_items; DELETE FROM series; DELETE FROM comic_meta; DELETE FROM comics"
                    .to_string(),
            ))
            .await
            .expect("clear");
            // Zeta (source) and Alpha (dest) both stay non-empty.
            // Ascending folder iteration processes Alpha before Zeta; without
            // pre-clearing comic_id rows, inserting m1 into Alpha UNIQUE-fails.
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
                 VALUES ('a1', 'E:/lib/Alpha/a1.cbz', 'cbz', 1, 1, 1), \
                        ('m1', 'E:/lib/Zeta/m1.cbz', 'cbz', 1, 1, 1), \
                        ('z1', 'E:/lib/Zeta/z1.cbz', 'cbz', 1, 1, 1)"
                    .to_string(),
            ))
            .await
            .expect("seed comics");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
                 VALUES ('a1', 'A1', 'unknown', 1), \
                        ('m1', 'M1', 'unknown', 1), \
                        ('z1', 'Z1', 'unknown', 1)"
                    .to_string(),
            ))
            .await
            .expect("seed meta");
            rebuild_series_from_comics(&db, None)
                .await
                .expect("initial rebuild");

            let alpha_id = hentai_core::series_id_from_folder_path("E:/lib/Alpha");
            let zeta_id = hentai_core::series_id_from_folder_path("E:/lib/Zeta");
            update_series_item_sort_order_via_sql(&db, &zeta_id, "m1", 9.5).await;

            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "UPDATE comics SET path = 'E:/lib/Alpha/m1.cbz' WHERE comic_id = 'm1'".to_string(),
            ))
            .await
            .expect("migrate path");

            rebuild_series_from_comics(&db, None)
                .await
                .expect("rebuild after folder migrate");

            let memberships = db
                .query_all(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT comic_id, series_id, sort_order, sort_order_locked \
                     FROM series_items ORDER BY comic_id"
                        .to_string(),
                ))
                .await
                .expect("memberships");
            assert_eq!(memberships.len(), 3);

            let mut by_comic: std::collections::HashMap<String, (String, f64, i64)> =
                std::collections::HashMap::new();
            for row in memberships {
                let comic_id: String = row.try_get_by_index(0).expect("comic_id");
                let series_id: String = row.try_get_by_index(1).expect("series_id");
                let sort_order: f64 = row.try_get_by_index(2).expect("sort_order");
                let locked: i64 = row.try_get_by_index(3).expect("locked");
                by_comic.insert(comic_id, (series_id, sort_order, locked));
            }

            assert_eq!(by_comic.get("a1").expect("a1").0, alpha_id);
            assert_eq!(by_comic.get("z1").expect("z1").0, zeta_id);
            let m1 = by_comic.get("m1").expect("m1");
            assert_eq!(m1.0, alpha_id, "migrated comic belongs to destination series");
            assert!((m1.1 - 9.5).abs() < f64::EPSILON);
            assert_eq!(m1.2, 1, "locked sort order survives migrate rebuild");

            let dup = db
                .query_one(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT COUNT(*) FROM series_items GROUP BY comic_id HAVING COUNT(*) > 1"
                        .to_string(),
                ))
                .await
                .expect("dup query");
            assert!(dup.is_none(), "each comic_id appears in at most one series");
        });
    });
}

async fn update_series_item_sort_order_via_sql(
    db: &DatabaseConnection,
    series_id: &str,
    comic_id: &str,
    sort_order: f64,
) {
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        format!(
            "UPDATE series_items SET sort_order = {sort_order}, sort_order_locked = 1 \
             WHERE series_id = '{series_id}' AND comic_id = '{comic_id}'"
        ),
    ))
    .await
    .expect("lock sort order");
}

#[test]
fn rebuild_overwrites_unlocked_series_name_from_folder() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
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
                 VALUES ('c1', 'E:/lib/Series/a.cbz', 'cbz', 1, 1, 1)"
                    .to_string(),
            ))
            .await
            .expect("seed comic");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
                 VALUES ('c1', 'A', 'unknown', 1)"
                    .to_string(),
            ))
            .await
            .expect("seed meta");
            rebuild_series_from_comics(&db, None).await.expect("rebuild");

            let series_id: String = db
                .query_one(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT series_id FROM series LIMIT 1".to_string(),
                ))
                .await
                .expect("query")
                .expect("row")
                .try_get_by_index(0)
                .expect("id");

            update_series_user_meta(
                &series_id,
                UpdateSeriesUserMetaDto {
                    name: Some("自定义系列名".to_string()),
                    ..Default::default()
                },
            )
            .await
            .expect("update name");

            set_series_meta_locks(
                &series_id,
                SetSeriesMetaLocksDto {
                    name: Some(false),
                    ..Default::default()
                },
            )
            .await
            .expect("unlock name");

            rebuild_series_from_comics(&connection().expect("connection"), None)
                .await
                .expect("rebuild again");

            let series = find_series_by_id(&series_id)
                .await
                .expect("find")
                .expect("series");
            assert_eq!(series.name, "Series");
            assert!(!series.locks.name);
        });
    });
}
