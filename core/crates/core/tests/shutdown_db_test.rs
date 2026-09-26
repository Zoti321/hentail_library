mod common;

use hentai_core::{connection, count_all, init_db_at_path, shutdown_db};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;

#[test]
fn shutdown_db_before_init_is_no_op() {
    common::with_global_db(|| {
        shutdown_db();
        shutdown_db();
        assert!(connection().is_err());
    });
}

#[test]
fn shutdown_db_is_idempotent_after_init() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("shutdown_idempotent.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            shutdown_db();
            shutdown_db();
            assert!(connection().is_err());
        });
    });
}

#[test]
fn shutdown_db_allows_reinit_empty_database() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("shutdown_reinit.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            shutdown_db();
            assert!(connection().is_err());

            init_db_at_path(&db_path).await.expect("reinit_db");
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
            assert_eq!(count_all().await.expect("count"), 0);
        });
    });
}
