use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::sync::series_rebuild::rebuild_series_from_comics;
use hentai_core::sync::writer::clear_all_comics;
use hentai_core::{
    connection, fetch_comics_page, find_comic_by_id, init_db_at_path, ComicFilterDto,
    ComicSortOptionDto, PageRequestDto,
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

async fn count_comic_reading_histories(db: &DatabaseConnection) -> i64 {
    let row = db
        .query_one(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT COUNT(*) FROM comic_reading_histories".to_string(),
        ))
        .await
        .expect("count query")
        .expect("count row");
    row.try_get_by_index(0).expect("count value")
}

#[test]
fn drift_v2_fixture_comic_rows_preserved() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let comic = find_comic_by_id("86408880d30b0de95ca959feb60a3b72dcb1889b")
                .await
                .expect("find")
                .expect("row");
            assert_eq!(comic.comic_id, "86408880d30b0de95ca959feb60a3b72dcb1889b");
            assert_eq!(comic.title, "测试漫画");
            assert_eq!(comic.authors, vec!["作者A".to_string()]);
            assert_eq!(comic.tags, vec!["冒险".to_string()]);
        });
    });
}

#[test]
fn fetch_comics_page_hides_r18_by_default() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let page = fetch_comics_page(
                PageRequestDto {
                    page: 1,
                    page_size: 50,
                },
                ComicFilterDto {
                    show_r18: false,
                    exclude_comics_in_any_series: false,
                    ..Default::default()
                },
                ComicSortOptionDto::default(),
            )
            .await
            .expect("page");
            assert_eq!(page.total_count, 2);
            assert!(page.items.iter().all(|c| c.content_rating != "r18"));
        });
    });
}

#[test]
fn clear_all_comics_removes_comic_reading_histories() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_reading_histories (comic_id, title, last_read_time, page_index) \
                 VALUES ('af738b6b1b3bbfab9a0fd591459572509d7ef4d5', '测试', 1_700_000_000, 3)"
                    .to_string(),
            ))
            .await
            .expect("seed comic reading");
            assert_eq!(count_comic_reading_histories(&db).await, 1);

            let removed = clear_all_comics(&db).await.expect("clear_all_comics");
            assert_eq!(removed, 3);
            assert_eq!(count_comic_reading_histories(&db).await, 0);
        });
    });
}

#[test]
fn fetch_comics_page_excludes_series_members() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            rebuild_series_from_comics(&db).await.expect("rebuild series");
            let page = fetch_comics_page(
                PageRequestDto {
                    page: 1,
                    page_size: 50,
                },
                ComicFilterDto {
                    show_r18: true,
                    exclude_comics_in_any_series: true,
                    ..Default::default()
                },
                ComicSortOptionDto::default(),
            )
            .await
            .expect("page");
            assert_eq!(page.total_count, 0);
        });
    });
}

#[test]
fn fetch_series_page_hides_r18_series_by_default() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            rebuild_series_from_comics(&db).await.expect("rebuild series");
            use hentai_core::{fetch_series_page, SeriesFilterDto, SeriesSortOptionDto};
            let page = fetch_series_page(
                PageRequestDto {
                    page: 1,
                    page_size: 50,
                },
                SeriesFilterDto {
                    show_r18: false,
                    require_items: true,
                    ..Default::default()
                },
                SeriesSortOptionDto {
                    field: hentai_core::SeriesSortFieldDto::Name,
                    descending: false,
                },
            )
            .await
            .expect("page");
            assert!(page.total_count >= 1);
            assert!(page.items.iter().all(|s| {
                !s.items.iter().any(|i| {
                    i.comic_id == "e931fd412112e427f7335e127af79c8b0f87887b"
                })
            }));
        });
    });
}

#[test]
fn fetch_series_page_returns_series_with_items() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            rebuild_series_from_comics(&db).await.expect("rebuild series");
            use hentai_core::{fetch_series_page, SeriesFilterDto, SeriesSortOptionDto};
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
                    field: hentai_core::SeriesSortFieldDto::Name,
                    descending: false,
                },
            )
            .await
            .expect("page");
            assert!(page.total_count >= 1);
            assert!(page.items.iter().any(|s| s.items.iter().any(|i| {
                i.comic_id == "af738b6b1b3bbfab9a0fd591459572509d7ef4d5"
            })));
        });
    });
}

#[test]
fn fetch_series_page_random_order_varies_between_queries() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            rebuild_series_from_comics(&db).await.expect("rebuild series");
            use hentai_core::{
                fetch_series_page, SeriesFilterDto, SeriesSortFieldDto, SeriesSortOptionDto,
            };
            use std::collections::HashSet;
            let filter = SeriesFilterDto {
                show_r18: true,
                require_items: true,
                ..Default::default()
            };
            let mut orders = HashSet::new();
            for _ in 0..12 {
                let page = fetch_series_page(
                    PageRequestDto {
                        page: 1,
                        page_size: 50,
                    },
                    filter.clone(),
                    SeriesSortOptionDto {
                        field: SeriesSortFieldDto::Random,
                        descending: false,
                    },
                )
                .await
                .expect("page random");
                assert!(page.total_count >= 2);
                let ids: Vec<String> =
                    page.items.iter().map(|s| s.series_id.clone()).collect();
                orders.insert(ids);
            }
            assert!(
                orders.len() > 1,
                "expected RANDOM() to produce varying orders across repeated queries"
            );
        });
    });
}
