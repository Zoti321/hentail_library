use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::sync::series_rebuild::rebuild_series_from_comics;
use hentai_core::{
    connection, create_local_library, fetch_series_page, init_db_at_path, set_current_library_id,
    update_series_user_meta, PageRequestDto, SeriesFilterDto, SeriesSortOptionDto,
    UpdateSeriesUserMetaDto,
};
use sea_orm::{ConnectionTrait, Database, DatabaseConnection, Statement};
use tempfile::TempDir;

/// `init_db_at_path` ????????????????????
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

async fn seed_two_series(db: &DatabaseConnection) -> (String, String) {
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
         VALUES ('c_ongoing', 'E:/lib/Ongoing/a.cbz', 'cbz', 1, 1, 1), \
                ('c_ended', 'E:/lib/Ended/b.cbz', 'cbz', 1, 1, 1)"
            .to_string(),
    ))
    .await
    .expect("seed comics");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
         VALUES ('c_ongoing', 'A', 'unknown', 1), ('c_ended', 'B', 'unknown', 1)"
            .to_string(),
    ))
    .await
    .expect("seed meta");
    rebuild_series_from_comics(db, None).await.expect("rebuild");

    let lib = create_local_library("E:/lib").await.expect("library");
    set_current_library_id(Some(&lib.library_id))
        .await
        .expect("current");
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

    let rows = db
        .query_all(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT series_id, name FROM series ORDER BY name".to_string(),
        ))
        .await
        .expect("series");
    assert_eq!(rows.len(), 2);
    let ended_id: String = rows[0].try_get_by_index(0).expect("ended id");
    let ongoing_id: String = rows[1].try_get_by_index(0).expect("ongoing id");
    // ORDER BY name: Ended, Ongoing
    let ended_name: String = rows[0].try_get_by_index(1).expect("name");
    let ongoing_name: String = rows[1].try_get_by_index(1).expect("name");
    assert_eq!(ended_name, "Ended");
    assert_eq!(ongoing_name, "Ongoing");

    update_series_user_meta(
        &ongoing_id,
        UpdateSeriesUserMetaDto {
            serialization_status: Some("ongoing".to_string()),
            name: None,
            total_count: None,
            clear_total_count: false,
        },
    )
    .await
    .expect("mark ongoing");
    update_series_user_meta(
        &ended_id,
        UpdateSeriesUserMetaDto {
            serialization_status: Some("ended".to_string()),
            name: None,
            total_count: None,
            clear_total_count: false,
        },
    )
    .await
    .expect("mark ended");

    (ongoing_id, ended_id)
}

#[test]
fn fetch_series_page_filters_by_serialization_status() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            let (ongoing_id, ended_id) = seed_two_series(&db).await;

            let page = fetch_series_page(
                PageRequestDto {
                    page: 1,
                    page_size: 50,
                },
                SeriesFilterDto {
                    show_r18: true,
                    require_items: true,
                    serialization_status: Some("ongoing".to_string()),
                    ..Default::default()
                },
                SeriesSortOptionDto {
                    field: hentai_core::SeriesSortFieldDto::Name,
                    descending: false,
                },
            )
            .await
            .expect("page");

            assert_eq!(page.total_count, 1);
            assert_eq!(page.items.len(), 1);
            assert_eq!(page.items[0].series_id, ongoing_id);
            assert_eq!(page.items[0].serialization_status, "ongoing");
            assert!(!page.items.iter().any(|s| s.series_id == ended_id));
        });
    });
}

#[test]
fn fetch_series_page_without_serialization_status_returns_all_statuses() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            let (ongoing_id, ended_id) = seed_two_series(&db).await;

            let page = fetch_series_page(
                PageRequestDto {
                    page: 1,
                    page_size: 50,
                },
                SeriesFilterDto {
                    show_r18: true,
                    require_items: true,
                    serialization_status: None,
                    ..Default::default()
                },
                SeriesSortOptionDto {
                    field: hentai_core::SeriesSortFieldDto::Name,
                    descending: false,
                },
            )
            .await
            .expect("page");

            assert_eq!(page.total_count, 2);
            let ids: Vec<&str> = page.items.iter().map(|s| s.series_id.as_str()).collect();
            assert!(ids.contains(&ongoing_id.as_str()));
            assert!(ids.contains(&ended_id.as_str()));
        });
    });
}
