use std::sync::Mutex;

use hentai_core::{
    connection, find_comic_by_id, init_db_at_path, record_reading, ReadingHistoryDto,
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

fn seed_comic(comic_id: &str) {
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        let db = connection().expect("connection");
        db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
                 VALUES ('{comic_id}', '/tmp/{comic_id}', 'zip', 1, 1, 1)"
            ),
        ))
        .await
        .expect("seed comic");
        db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
                 VALUES ('{comic_id}', 'Title {comic_id}', 'unknown', 1)"
            ),
        ))
        .await
        .expect("seed meta");
    });
}

#[test]
fn find_comic_by_id_includes_last_read_time_when_history_exists() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("comic_last_read.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(init_db_at_path(&db_path)).expect("init db");

        seed_comic("read-comic");
        seed_comic("unread-comic");

        runtime.block_on(async {
            record_reading(&ReadingHistoryDto {
                comic_id: "read-comic".to_string(),
                title: "Title read-comic".to_string(),
                last_read_time_ms: 9_000,
                page_index: Some(2),
            })
            .await
            .expect("record reading");

            let read = find_comic_by_id("read-comic")
                .await
                .expect("find read")
                .expect("read comic present");
            assert_eq!(read.last_read_time_ms, Some(9_000));

            let unread = find_comic_by_id("unread-comic")
                .await
                .expect("find unread")
                .expect("unread comic present");
            assert_eq!(unread.last_read_time_ms, None);
        });
    });
}
