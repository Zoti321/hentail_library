mod common;

use hentai_core::{connection, find_series_item_by_comic_id, init_db_at_path};
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

async fn seed_series_with_locked_member(db: &DatabaseConnection) {
    clear_library(db).await;
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
         VALUES ('c1', 'E:/lib/Series/a.cbz', 'cbz', 1, 1, 1), \
                ('c2', 'E:/lib/Series/b.cbz', 'cbz', 1, 1, 1), \
                ('solo', 'E:/lib/solo.cbz', 'cbz', 1, 1, 1)"
            .to_string(),
    ))
    .await
    .expect("seed comics");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
         VALUES ('c1', 'A', 'unknown', 1), ('c2', 'B', 'unknown', 1), ('solo', 'Solo', 'unknown', 1)"
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
        "INSERT INTO series_items (series_id, comic_id, sort_order, sort_order_locked) \
         VALUES ('s1', 'c1', 0, 0), ('s1', 'c2', 7.5, 1)"
            .to_string(),
    ))
    .await
    .expect("seed items");
}

#[test]
fn membership_for_member_comic_returns_series_id_and_sort_state() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_series_with_locked_member(&db).await;

            let item = find_series_item_by_comic_id("c2")
                .await
                .expect("query")
                .expect("membership present");

            assert_eq!(item.series_id, "s1");
            assert_eq!(item.comic_id, "c2");
            assert_eq!(item.sort_order, 7.5);
            assert!(item.sort_order_locked);

            let unlocked = find_series_item_by_comic_id("c1")
                .await
                .expect("query")
                .expect("membership present");
            assert_eq!(unlocked.sort_order, 0.0);
            assert!(!unlocked.sort_order_locked);
        });
    });
}

/// 锁住 `find_series_item_by_comic_id` / reading context 的 `.one()` 前提：
/// 一本 Comic 至多属于一个 Series（`CONTEXT.md` 的 Folder series 语义，
/// 由 `series_items` 的 `UNIQUE (comic_id)` 保证）。
#[test]
fn series_items_rejects_same_comic_in_two_series() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_series_with_locked_member(&db).await;
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO series (series_id, folder_path, name, serialization_status, total_count) \
                 VALUES ('s2', 'E:/lib/Other', 'Other', 'unknown', NULL)"
                    .to_string(),
            ))
            .await
            .expect("seed second series");

            let duplicate = db
                .execute(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    "INSERT INTO series_items (series_id, comic_id, sort_order, sort_order_locked) \
                     VALUES ('s2', 'c2', 0, 0)"
                        .to_string(),
                ))
                .await;
            assert!(
                duplicate.is_err(),
                "series_items should reject a comic already owned by another series"
            );

            let item = find_series_item_by_comic_id("c2")
                .await
                .expect("query")
                .expect("membership present");
            assert_eq!(item.series_id, "s1");
        });
    });
}

#[test]
fn membership_for_unassigned_or_blank_comic_returns_none() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_series_with_locked_member(&db).await;

            assert!(find_series_item_by_comic_id("solo")
                .await
                .expect("query")
                .is_none());
            assert!(find_series_item_by_comic_id("   ")
                .await
                .expect("query")
                .is_none());
        });
    });
}
