mod common;

use hentai_core::{
    connection, fetch_reading_page, get_reading_by_comic_id, init_db_at_path, now_ms,
    reading_history_retention_cutoff_ms, record_reading, PageRequestDto, ReadingHistoryDto,
};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;

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

fn create_db(dir: &std::path::Path) {
    let db_path = dir.join("history_retention.sqlite");
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        init_db_at_path(&db_path).await.expect("init_db");
        create_reading_histories_table().await;
    });
}

#[test]
fn fetch_reading_page_hides_expired_rows() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        create_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            let now = now_ms();
            let expired = reading_history_retention_cutoff_ms(now) - 1;

            record_reading(&ReadingHistoryDto {
                comic_id: "fresh".to_string(),
                title: "Fresh".to_string(),
                last_read_time_ms: now,
                page_index: Some(1),
                page_count: None,
            })
            .await
            .expect("record fresh");

            record_reading(&ReadingHistoryDto {
                comic_id: "stale".to_string(),
                title: "Stale".to_string(),
                last_read_time_ms: expired,
                page_index: Some(1),
                page_count: None,
            })
            .await
            .expect("record stale");

            let page = fetch_reading_page(
                PageRequestDto {
                    page: 1,
                    page_size: 10,
                },
                None,
            )
            .await
            .expect("page");

            assert_eq!(page.total_count, 1);
            assert_eq!(page.items.len(), 1);
            assert_eq!(page.items[0].comic_id, "fresh");

            assert!(
                get_reading_by_comic_id("stale")
                    .await
                    .expect("load stale")
                    .is_none()
            );
        });
    });
}
