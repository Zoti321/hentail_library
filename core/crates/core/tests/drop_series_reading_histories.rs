mod common;

use hentai_core::{connection, init_db_at_path};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;
#[test]
fn migrated_db_has_no_series_reading_histories_table() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            let row = db
                .query_one(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT 1 FROM sqlite_master \
                     WHERE type='table' AND name='series_reading_histories' \
                     LIMIT 1"
                        .to_string(),
                ))
                .await
                .expect("query");
            assert!(
                row.is_none(),
                "series_reading_histories must be dropped (ADR-0005)"
            );
        });
    });
}
