mod common;

use hentai_core::{
    connection, find_comics_by_ids, init_db_at_path,
};
use sea_orm::{ConnectionTrait, DatabaseConnection, Statement};
use tempfile::TempDir;

async fn clear_comics(db: &DatabaseConnection) {
    for table in ["comic_meta", "comics"] {
        db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!("DELETE FROM {table}"),
        ))
        .await
        .expect("clear table");
    }
}

async fn seed_three_comics(db: &DatabaseConnection) {
    clear_comics(db).await;
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
         VALUES ('c1', 'E:/lib/a.cbz', 'cbz', 1, 1, 1), \
                ('c2', 'E:/lib/b.cbz', 'cbz', 1, 1, 1), \
                ('c3', 'E:/lib/c.cbz', 'cbz', 1, 1, 1)"
            .to_string(),
    ))
    .await
    .expect("seed comics");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
         VALUES ('c1', 'A', 'unknown', 1), ('c2', 'B', 'unknown', 1), ('c3', 'C', 'unknown', 1)"
            .to_string(),
    ))
    .await
    .expect("seed meta");
}

#[test]
fn find_comics_by_ids_preserves_request_order_and_skips_missing() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_three_comics(&db).await;

            let rows = find_comics_by_ids(vec![
                "c3".to_string(),
                "missing".to_string(),
                "c1".to_string(),
            ])
            .await
            .expect("batch find");

            assert_eq!(
                rows.iter().map(|c| c.comic_id.as_str()).collect::<Vec<_>>(),
                vec!["c3", "c1"]
            );
            assert_eq!(
                rows.iter().map(|c| c.title.as_str()).collect::<Vec<_>>(),
                vec!["C", "A"]
            );
        });
    });
}

#[test]
fn find_comics_by_ids_empty_returns_empty_without_rows() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let rows = find_comics_by_ids(vec![])
                .await
                .expect("empty batch find");
            assert!(rows.is_empty());
        });
    });
}
