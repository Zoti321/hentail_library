#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

mod common;

use hentai_core::{connection, init_db_at_path, record_reading_activity};
use sea_orm::{ConnectionTrait, DatabaseConnection, Statement};
use tempfile::TempDir;

async fn seed_activity_comic(db: &DatabaseConnection) {
    db.execute_unprepared(
        "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
         VALUES ('activity-comic', 'E:/activity.cbz', 'cbz', 1, 1, 1)",
    )
    .await
    .expect("seed comic");
    db.execute_unprepared(
        "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
         VALUES ('activity-comic', 'Activity', 'safe', 10)",
    )
    .await
    .expect("seed metadata");
    db.execute_unprepared(
        "UPDATE reading_duration_total SET total_ms = 5000, updated_at_ms = 123 WHERE id = 1",
    )
    .await
    .expect("seed duration");
}

async fn duration_state(db: &DatabaseConnection) -> (i64, i64) {
    let row = db
        .query_one(Statement::from_string(
            db.get_database_backend(),
            "SELECT total_ms, updated_at_ms FROM reading_duration_total WHERE id = 1".to_string(),
        ))
        .await
        .expect("duration query")
        .expect("duration singleton");
    (
        row.try_get_by_index(0).expect("total duration"),
        row.try_get_by_index(1).expect("duration update time"),
    )
}

async fn finished_at(db: &DatabaseConnection) -> Option<i64> {
    db.query_one(Statement::from_string(
        db.get_database_backend(),
        "SELECT finished_at_ms FROM comic_finished_marks WHERE comic_id = 'activity-comic'"
            .to_string(),
    ))
    .await
    .expect("finished mark query")
    .map(|row| row.try_get_by_index(0).expect("finished timestamp"))
}

#[test]
fn finished_mark_failure_rolls_back_duration_and_timestamp_without_notification() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&path).await.expect("init database");
            let db = connection().expect("connection");
            seed_activity_comic(&db).await;
            db.execute_unprepared(
                "CREATE TRIGGER block_finished_activity BEFORE INSERT ON comic_finished_marks \
                 WHEN NEW.comic_id = 'activity-comic' \
                 BEGIN SELECT RAISE(ABORT, 'finished activity blocked'); END",
            )
            .await
            .expect("inject failure after duration update");
            let notifications = hentai_core::revision::notify_count();
            let changes = hentai_core::revision::subscribe();

            let error = record_reading_activity("activity-comic", Some(12000), true)
                .await
                .expect_err("finished mark insertion fails");

            assert!(
                error.message.contains("finished activity blocked"),
                "{error:?}"
            );
            assert_eq!(duration_state(&db).await, (5000, 123));
            assert_eq!(finished_at(&db).await, None);
            assert_eq!(hentai_core::revision::notify_count(), notifications);
            assert!(!changes.has_changed().expect("revision remains open"));
        });
    });
}

#[test]
fn duration_only_accumulates_positive_values_and_preserves_empty_request_notifications() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&path).await.expect("init database");
            let db = connection().expect("connection");
            seed_activity_comic(&db).await;
            let notifications = hentai_core::revision::notify_count();

            record_reading_activity("activity-comic", Some(12000), false)
                .await
                .expect("duration only");

            let after_positive = duration_state(&db).await;
            assert_eq!(after_positive.0, 17000);
            assert!(after_positive.1 > 123);
            assert_eq!(finished_at(&db).await, None);
            assert_eq!(hentai_core::revision::notify_count(), notifications + 1);
            for delta in [Some(0), Some(-12000), None] {
                let notifications = hentai_core::revision::notify_count();
                record_reading_activity("activity-comic", delta, false)
                    .await
                    .expect("empty activity remains a successful request");
                assert_eq!(duration_state(&db).await, after_positive);
                assert_eq!(finished_at(&db).await, None);
                assert_eq!(hentai_core::revision::notify_count(), notifications + 1);
            }
        });
    });
}

#[test]
fn mark_only_creates_a_sticky_finish_timestamp_without_changing_duration() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&path).await.expect("init database");
            let db = connection().expect("connection");
            seed_activity_comic(&db).await;
            let notifications = hentai_core::revision::notify_count();

            record_reading_activity("activity-comic", None, true)
                .await
                .expect("mark only");

            assert!(finished_at(&db).await.expect("finished mark") > 0);
            assert_eq!(duration_state(&db).await, (5000, 123));
            assert_eq!(hentai_core::revision::notify_count(), notifications + 1);
            // A fixed historical timestamp makes replacement detectable without waiting for time to pass.
            db.execute_unprepared(
                "UPDATE comic_finished_marks SET finished_at_ms = 77 WHERE comic_id = 'activity-comic'",
            )
            .await
            .expect("historical first finish");

            record_reading_activity("activity-comic", Some(-1), true)
                .await
                .expect("repeated mark");

            assert_eq!(finished_at(&db).await, Some(77));
            assert_eq!(duration_state(&db).await, (5000, 123));
            assert_eq!(hentai_core::revision::notify_count(), notifications + 2);
        });
    });
}

#[test]
fn watcher_observes_complete_commits_and_failure_does_not_refresh_its_snapshot() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&path).await.expect("init database");
            let db = connection().expect("connection");
            seed_activity_comic(&db).await;
            let baseline = hentai_core::load_reading_activity_stats(&db).await.expect("baseline");
            let (sender, mut snapshots) = tokio::sync::mpsc::unbounded_channel();
            let watch = tokio::spawn(async move {
                hentai_core::watch_reading_activity_stats(|stats| {
                    sender.send(stats).map_err(|_| hentai_core::HentaiError::validation("watch receiver closed"))
                }).await
            });
            let initial = tokio::time::timeout(std::time::Duration::from_secs(5), snapshots.recv())
                .await.expect("initial snapshot timeout").expect("initial snapshot");
            assert_eq!(initial, baseline);
            let notifications = hentai_core::revision::notify_count();
            let _library_write = hentai_core::try_acquire_library_write_lock().expect("hold unrelated bulk write lock");

            record_reading_activity("activity-comic", Some(12000), true)
                .await.expect("single session activity does not acquire the library write lock");

            let committed = tokio::time::timeout(std::time::Duration::from_secs(5), snapshots.recv())
                .await.expect("committed snapshot timeout").expect("committed snapshot");
            assert_eq!(committed.total_duration_ms, 17000);
            assert_eq!(committed.finished_count, baseline.finished_count + 1);
            assert_eq!(hentai_core::revision::notify_count(), notifications + 1);
            let committed_duration = duration_state(&db).await;
            let committed_finish = finished_at(&db).await;
            db.execute_unprepared(
                "CREATE TRIGGER block_repeated_finished_activity BEFORE INSERT ON comic_finished_marks \
                 WHEN NEW.comic_id = 'activity-comic' \
                 BEGIN SELECT RAISE(ABORT, 'repeated finished activity blocked'); END",
            ).await.expect("inject second activity failure");
            let changes = hentai_core::revision::subscribe();

            let error = record_reading_activity("activity-comic", Some(9000), true)
                .await.expect_err("mark failure after duration update");

            assert!(error.message.contains("repeated finished activity blocked"), "{error:?}");
            assert_eq!(duration_state(&db).await, committed_duration);
            assert_eq!(finished_at(&db).await, committed_finish);
            assert_eq!(hentai_core::load_reading_activity_stats(&db).await.expect("unchanged stats"), committed);
            assert_eq!(hentai_core::revision::notify_count(), notifications + 1);
            assert!(!changes.has_changed().expect("revision remains open"));
            assert!(matches!(snapshots.try_recv(), Err(tokio::sync::mpsc::error::TryRecvError::Empty)));
            watch.abort();
            assert!(watch.await.expect_err("watch cancelled after assertions").is_cancelled());
        });
    });
}
