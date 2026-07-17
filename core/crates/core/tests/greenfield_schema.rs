use std::sync::Mutex;

use hentai_core::{connection, count_all, init_db_at_path};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;

static DB_INIT_LOCK: Mutex<()> = Mutex::new(());

#[test]
fn greenfield_init_creates_comics_table() {
    let _guard = DB_INIT_LOCK.lock().expect("serial db tests");
    let temp = TempDir::new().expect("tempdir");
    let db_path = temp.path().join("greenfield.sqlite");
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        init_db_at_path(&db_path).await.expect("init_db");
        let db = connection().expect("connection");
        let row = db
            .query_one(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "SELECT 1 FROM sqlite_master WHERE type='table' AND name='comics' LIMIT 1"
                    .to_string(),
            ))
            .await
            .expect("query")
            .expect("comics table missing");
        assert_eq!(row.try_get_by_index::<i64>(0).unwrap_or(0), 1);

        let history = db
            .query_one(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "SELECT 1 FROM sqlite_master WHERE type='table' AND name='comic_reading_histories' LIMIT 1"
                    .to_string(),
            ))
            .await
            .expect("query")
            .expect("comic_reading_histories table missing");
        assert_eq!(history.try_get_by_index::<i64>(0).unwrap_or(0), 1);

        assert_eq!(count_all().await.expect("count"), 0);
    });
}
