mod common;

use hentai_core::{
    connection, get_series_reading_context_by_comic_id, init_db_at_path,
};
use sea_orm::{ConnectionTrait, DatabaseConnection, Statement};
use tempfile::TempDir;
async fn clear_library(db: &DatabaseConnection) {
    for table in ["series_items", "series", "comic_meta", "comics"] {
        db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!("DELETE FROM {table}"),
        ))
        .await
        .expect("clear table");
    }
}

async fn seed_series_with_three_comics(db: &DatabaseConnection) {
    clear_library(db).await;
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
         VALUES ('c1', 'E:/lib/Series/a.cbz', 'cbz', 1, 1, 1), \
                ('c2', 'E:/lib/Series/b.cbz', 'cbz', 1, 1, 1), \
                ('c3', 'E:/lib/Series/c.cbz', 'cbz', 1, 1, 1)"
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
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO series (series_id, folder_path, name, serialization_status, total_count) \
         VALUES ('s1', 'E:/lib/Series', 'Series', 'unknown', NULL)"
            .to_string(),
    ))
    .await
    .expect("seed series");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO series_items (series_id, comic_id, sort_order) \
         VALUES ('s1', 'c1', 0), ('s1', 'c2', 1), ('s1', 'c3', 2)"
            .to_string(),
    ))
    .await
    .expect("seed items");
}

#[test]
fn series_reading_context_for_member_comic_returns_ordered_ids_and_index() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_series_with_three_comics(&db).await;

            let ctx = get_series_reading_context_by_comic_id("c2")
                .await
                .expect("query")
                .expect("context present");

            assert_eq!(ctx.series_id, "s1");
            assert_eq!(ctx.series_name, "Series");
            assert_eq!(
                ctx.ordered_comic_ids,
                vec!["c1".to_string(), "c2".to_string(), "c3".to_string()]
            );
            assert_eq!(ctx.current_index, 1);
        });
    });
}

#[test]
fn series_reading_context_for_unassigned_comic_returns_none() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            clear_library(&db).await;
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
                 VALUES ('solo', 'E:/lib/solo.cbz', 'cbz', 1, 1, 1)"
                    .to_string(),
            ))
            .await
            .expect("seed comic");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
                 VALUES ('solo', 'Solo', 'unknown', 1)"
                    .to_string(),
            ))
            .await
            .expect("seed meta");

            let ctx = get_series_reading_context_by_comic_id("solo")
                .await
                .expect("query");
            assert!(ctx.is_none());
        });
    });
}
