use std::path::Path;
use std::sync::Mutex;

use hentai_core::{
    connection, fetch_reading_page, init_db_at_path, record_reading, ReadingHistoryDto,
};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;

static DB_INIT_LOCK: Mutex<()> = Mutex::new(());

fn with_global_db(test: impl FnOnce()) {
    let _guard = DB_INIT_LOCK
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner());
    test();
}
async fn create_reading_histories_table() {
    let db = connection().expect("connection");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "CREATE TABLE IF NOT EXISTS comic_reading_histories (
            comic_id TEXT NOT NULL PRIMARY KEY,
            title TEXT NOT NULL,
            last_read_time INTEGER NOT NULL,
            page_index INTEGER
        )"
        .to_string(),
    ))
    .await
    .expect("create comic_reading_histories");
}

fn create_db(dir: &Path) {
    let db_path = dir.join("history_page.sqlite");
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        init_db_at_path(&db_path).await.expect("init_db");
        create_reading_histories_table().await;
    });
}

async fn seed_histories() {
    for (comic_id, title, last_read_time_ms) in [
        ("c1", "Alpha Comic", 5_000_i64),
        ("c2", "Beta Story", 4_000_i64),
        ("c3", "Gamma alpha", 3_000_i64),
        ("c4", "Delta", 2_000_i64),
        ("c5", "Epsilon", 1_000_i64),
    ] {
        record_reading(&ReadingHistoryDto {
            comic_id: comic_id.to_string(),
            title: title.to_string(),
            last_read_time_ms,
            page_index: Some(1),
        })
        .await
        .expect("record reading");
    }
}

#[test]
fn fetch_reading_page_returns_descending_pages() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        create_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            seed_histories().await;

            let page1 = fetch_reading_page(1, 2, None)
                .await
                .expect("page1");
            assert_eq!(page1.total_count, 5);
            assert_eq!(page1.items.len(), 2);
            assert_eq!(page1.items[0].comic_id, "c1");
            assert_eq!(page1.items[1].comic_id, "c2");

            let page2 = fetch_reading_page(2, 2, None)
                .await
                .expect("page2");
            assert_eq!(page2.items.len(), 2);
            assert_eq!(page2.items[0].comic_id, "c3");
            assert_eq!(page2.items[1].comic_id, "c4");

            let page3 = fetch_reading_page(3, 2, None)
                .await
                .expect("page3");
            assert_eq!(page3.items.len(), 1);
            assert_eq!(page3.items[0].comic_id, "c5");
        });
    });
}

#[test]
fn fetch_reading_page_filters_by_keyword_case_insensitively() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        create_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            seed_histories().await;

            let filtered = fetch_reading_page(1, 50, Some("ALPHA".to_string()))
                .await
                .expect("filtered");
            assert_eq!(filtered.total_count, 2);
            assert_eq!(filtered.items.len(), 2);
            let comic_ids: Vec<String> = filtered
                .items
                .into_iter()
                .map(|item| item.comic_id)
                .collect();
            assert!(comic_ids.contains(&"c1".to_string()));
            assert!(comic_ids.contains(&"c3".to_string()));
        });
    });
}

#[test]
fn fetch_reading_page_treats_blank_keyword_as_unfiltered() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        create_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            seed_histories().await;

            let page = fetch_reading_page(1, 50, Some("   ".to_string()))
                .await
                .expect("page");
            assert_eq!(page.total_count, 5);
            assert_eq!(page.items.len(), 5);
        });
    });
}
