use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::sync::series_rebuild::rebuild_series_from_comics;
use hentai_core::util::compute_sort_key;
use hentai_core::{
    connection, create_local_library, fetch_comics_page, fetch_series_page, init_db_at_path,
    set_current_library_id, update_comic_user_meta, ComicFilterDto, ComicSortFieldDto,
    ComicSortOptionDto, PageRequestDto, SeriesFilterDto, SeriesSortFieldDto, SeriesSortOptionDto,
    UpdateComicUserMetaDto,
};
use sea_orm::{ConnectionTrait, Database, DatabaseConnection, Statement};
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

async fn clear_library(db: &DatabaseConnection) {
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM series_items; DELETE FROM series; DELETE FROM comic_meta; DELETE FROM comics"
            .to_string(),
    ))
    .await
    .expect("clear");
}

async fn stamp_all_to_current_library(db: &DatabaseConnection, root: &str) {
    let lib = create_local_library(root, None).await.expect("create library");
    set_current_library_id(Some(&lib.library_id))
        .await
        .expect("set current");
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "UPDATE comics SET library_id = ?",
        [sea_orm::Value::String(Some(Box::new(lib.library_id.clone())))],
    ))
    .await
    .expect("stamp comics");
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "UPDATE series SET library_id = ?",
        [sea_orm::Value::String(Some(Box::new(lib.library_id)))],
    ))
    .await
    .expect("stamp series");
}

async fn insert_comic(db: &DatabaseConnection, comic_id: &str, path: &str, title: &str) {
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
         VALUES (?, ?, 'cbz', 1, 1, 1)",
        [
            sea_orm::Value::String(Some(Box::new(comic_id.to_string()))),
            sea_orm::Value::String(Some(Box::new(path.to_string()))),
        ],
    ))
    .await
    .expect("insert comic");
    let key = compute_sort_key(title);
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comic_meta (comic_id, title, title_sort_key, content_rating, page_count) \
         VALUES (?, ?, ?, 'unknown', 1)",
        [
            sea_orm::Value::String(Some(Box::new(comic_id.to_string()))),
            sea_orm::Value::String(Some(Box::new(title.to_string()))),
            sea_orm::Value::String(Some(Box::new(key))),
        ],
    ))
    .await
    .expect("insert meta");
}

async fn insert_series(
    db: &DatabaseConnection,
    series_id: &str,
    folder_path: &str,
    name: &str,
    library_id: &str,
) {
    let key = compute_sort_key(name);
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO series (series_id, folder_path, name, name_sort_key, serialization_status, library_id) \
         VALUES (?, ?, ?, ?, 'unknown', ?)",
        [
            sea_orm::Value::String(Some(Box::new(series_id.to_string()))),
            sea_orm::Value::String(Some(Box::new(folder_path.to_string()))),
            sea_orm::Value::String(Some(Box::new(name.to_string()))),
            sea_orm::Value::String(Some(Box::new(key))),
            sea_orm::Value::String(Some(Box::new(library_id.to_string()))),
        ],
    ))
    .await
    .expect("insert series");
}

async fn insert_series_item(
    db: &DatabaseConnection,
    series_id: &str,
    comic_id: &str,
    sort_order: f64,
) {
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO series_items (series_id, comic_id, sort_order, sort_order_locked) \
         VALUES (?, ?, ?, 0)",
        [
            sea_orm::Value::String(Some(Box::new(series_id.to_string()))),
            sea_orm::Value::String(Some(Box::new(comic_id.to_string()))),
            sea_orm::Value::Double(Some(sort_order)),
        ],
    ))
    .await
    .expect("insert series item");
}

#[test]
fn fetch_comics_page_title_asc_uses_natural_order() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            clear_library(&db).await;
            insert_comic(&db, "c10", "E:/lib/Vol 10.cbz", "Vol 10").await;
            insert_comic(&db, "c2", "E:/lib/Vol 2.cbz", "Vol 2").await;
            insert_comic(&db, "c1", "E:/lib/Vol 1.cbz", "vol 1").await;
            stamp_all_to_current_library(&db, "E:/lib").await;

            let page = fetch_comics_page(
                PageRequestDto {
                    page: 1,
                    page_size: 50,
                },
                ComicFilterDto {
                    show_r18: true,
                    ..Default::default()
                },
                false,
                ComicSortOptionDto {
                    field: ComicSortFieldDto::Title,
                    descending: false,
                },
            )
            .await
            .expect("page");

            let titles: Vec<&str> = page.items.iter().map(|c| c.title.as_str()).collect();
            assert_eq!(titles, vec!["vol 1", "Vol 2", "Vol 10"]);
        });
    });
}

#[test]
fn fetch_comics_page_expand_by_series_flattens_series_blocks() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            clear_library(&db).await;

            insert_comic(&db, "root-2", "E:/lib/root/vol2.cbz", "Root Vol 2").await;
            insert_comic(&db, "root-1", "E:/lib/root/vol1.cbz", "Root Vol 1").await;
            insert_comic(&db, "beta-2", "E:/lib/beta/vol2.cbz", "Beta Vol 2").await;
            insert_comic(&db, "beta-1", "E:/lib/beta/vol1.cbz", "Beta Vol 1").await;
            insert_comic(&db, "alpha-1", "E:/lib/alpha/vol1.cbz", "Alpha Vol 1").await;
            insert_comic(&db, "loose-b", "E:/lib/loose-b.cbz", "Loose B").await;
            insert_comic(&db, "loose-a", "E:/lib/loose-a.cbz", "Loose A").await;

            let lib = create_local_library("E:/lib", None).await.expect("create library");
            set_current_library_id(Some(&lib.library_id))
                .await
                .expect("set current");
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "UPDATE comics SET library_id = ?",
                [sea_orm::Value::String(Some(Box::new(lib.library_id.clone())))],
            ))
            .await
            .expect("stamp comics");

            insert_series(&db, "series-root", "E:/lib", "Root Series", &lib.library_id).await;
            insert_series(&db, "series-beta", "E:/lib/beta", "Beta Series", &lib.library_id).await;
            insert_series(&db, "series-alpha", "E:/lib/alpha", "Alpha Series", &lib.library_id)
                .await;
            insert_series_item(&db, "series-root", "root-1", 1.0).await;
            insert_series_item(&db, "series-root", "root-2", 2.0).await;
            insert_series_item(&db, "series-beta", "beta-1", 10.0).await;
            insert_series_item(&db, "series-beta", "beta-2", 20.0).await;
            insert_series_item(&db, "series-alpha", "alpha-1", 5.0).await;

            let page = fetch_comics_page(
                PageRequestDto {
                    page: 1,
                    page_size: 50,
                },
                ComicFilterDto {
                    show_r18: true,
                    ..Default::default()
                },
                true,
                ComicSortOptionDto {
                    field: ComicSortFieldDto::CreatedAt,
                    descending: true,
                },
            )
            .await
            .expect("page");

            let ids: Vec<&str> = page.items.iter().map(|c| c.comic_id.as_str()).collect();
            assert_eq!(
                ids,
                vec![
                    "root-1",
                    "root-2",
                    "alpha-1",
                    "beta-1",
                    "beta-2",
                    "loose-a",
                    "loose-b",
                ]
            );
        });
    });
}

#[test]
fn fetch_series_page_name_asc_uses_natural_order() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            clear_library(&db).await;
            insert_comic(&db, "c10", "E:/lib/Vol 10/a.cbz", "a").await;
            insert_comic(&db, "c2", "E:/lib/Vol 2/a.cbz", "a").await;
            insert_comic(&db, "c1", "E:/lib/Vol 1/a.cbz", "a").await;
            rebuild_series_from_comics(&db, None).await.expect("rebuild");
            stamp_all_to_current_library(&db, "E:/lib").await;

            let page = fetch_series_page(
                PageRequestDto {
                    page: 1,
                    page_size: 50,
                },
                SeriesFilterDto {
                    show_r18: true,
                    require_items: true,
                    ..Default::default()
                },
                SeriesSortOptionDto {
                    field: SeriesSortFieldDto::Name,
                    descending: false,
                },
            )
            .await
            .expect("page");

            let names: Vec<&str> = page.items.iter().map(|s| s.name.as_str()).collect();
            assert_eq!(names, vec!["Vol 1", "Vol 2", "Vol 10"]);
        });
    });
}

#[test]
fn update_comic_title_refreshes_title_sort_key() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            clear_library(&db).await;
            insert_comic(&db, "c1", "E:/lib/a.cbz", "Old").await;

            update_comic_user_meta(
                "c1",
                UpdateComicUserMetaDto {
                    title: Some("Vol 2".to_string()),
                    ..Default::default()
                },
            )
            .await
            .expect("update");

            let row = db
                .query_one(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT title_sort_key FROM comic_meta WHERE comic_id = 'c1'".to_string(),
                ))
                .await
                .expect("query")
                .expect("row");
            let key: String = row.try_get_by_index(0).expect("key");
            assert_eq!(key, compute_sort_key("Vol 2"));
        });
    });
}
