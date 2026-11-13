mod common;

use hentai_core::{
    connection, fetch_reading_page, get_reading_by_comic_id, init_db_at_path, now_ms,
    reading_history_retention_cutoff_ms, record_reading, PageRequestDto, ReadingHistoryDto,
};
use sea_orm::{ConnectionTrait, DatabaseConnection, Statement};
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
        let temp = TempDir::new().expect("tempdir").keep();
        create_db(&temp);
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

            assert!(get_reading_by_comic_id("stale")
                .await
                .expect("load stale")
                .is_none());
        });
    });
}

async fn history_rows(db: &DatabaseConnection) -> Vec<(String, String, i64, Option<i32>)> {
    db.query_all(Statement::from_string(
        db.get_database_backend(),
        "SELECT comic_id, title, last_read_time, page_index FROM comic_reading_histories ORDER BY comic_id"
            .to_string(),
    ))
    .await
    .expect("history rows")
    .into_iter()
    .map(|row| {
        (
            row.try_get_by_index(0).expect("comic id"),
            row.try_get_by_index(1).expect("title"),
            row.try_get_by_index(2).expect("read time"),
            row.try_get_by_index(3).expect("page index"),
        )
    })
    .collect()
}

fn assert_retention_failure_rolls_back_progress(existing: bool) {
    common::with_global_db(|| {
        // Keep database files for manual cleanup under the repository removal policy.
        let temp = TempDir::new().expect("tempdir").keep();
        create_db(&temp);
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            let db = connection().expect("connection");
            let now = now_ms();
            let expired = reading_history_retention_cutoff_ms(now) - 60_000;
            db.execute(Statement::from_sql_and_values(
                db.get_database_backend(),
                "INSERT INTO comic_reading_histories (comic_id, title, last_read_time, page_index) VALUES ('expired', 'Expired', ?, 2)",
                [expired.into()],
            ))
            .await
            .expect("seed expired history");
            if existing {
                record_reading(&ReadingHistoryDto {
                    comic_id: "target".to_string(),
                    title: "Previous".to_string(),
                    last_read_time_ms: now - 1000,
                    page_index: Some(3),
                    page_count: None,
                })
                .await
                .expect("seed existing progress");
                // The seed command purges expired rows; restore one to exercise retention.
                db.execute(Statement::from_sql_and_values(
                    db.get_database_backend(),
                    "INSERT INTO comic_reading_histories (comic_id, title, last_read_time, page_index) VALUES ('expired', 'Expired', ?, 2)",
                    [expired.into()],
                ))
                .await
                .expect("restore expired history");
            }
            db.execute_unprepared(
                "CREATE TRIGGER block_history_retention BEFORE DELETE ON comic_reading_histories \
                 WHEN OLD.comic_id = 'expired' \
                 BEGIN SELECT RAISE(ABORT, 'history retention blocked'); END",
            )
            .await
            .expect("inject retention failure");
            let before = history_rows(&db).await;
            let notifications = hentai_core::revision::notify_count();
            let changes = hentai_core::revision::subscribe();
            let next = ReadingHistoryDto {
                comic_id: "target".to_string(),
                title: "Next &amp; title".to_string(),
                last_read_time_ms: now,
                page_index: Some(8),
                page_count: None,
            };

            let error = record_reading(&next).await.expect_err("retention fails");

            assert!(error.message.contains("history retention blocked"), "{error:?}");
            assert_eq!(history_rows(&db).await, before);
            assert_eq!(hentai_core::revision::notify_count(), notifications);
            assert!(!changes.has_changed().expect("revision remains open"));

            db.execute_unprepared("DROP TRIGGER block_history_retention")
                .await
                .expect("remove injected failure");
            record_reading(&next).await.expect("new command succeeds");
            assert_eq!(
                history_rows(&db).await,
                vec![("target".to_string(), "Next & title".to_string(), now, Some(8))],
            );
            assert_eq!(hentai_core::revision::notify_count(), notifications + 1);
            assert!(changes.has_changed().expect("revision remains open"));
        });
    });
}

#[test]
fn retention_failure_rolls_back_inserted_progress_without_notification() {
    assert_retention_failure_rolls_back_progress(false);
}

#[test]
fn retention_failure_restores_previous_progress_without_notification() {
    assert_retention_failure_rolls_back_progress(true);
}
