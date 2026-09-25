mod common;

use hentai_core::sync::series_rebuild::rebuild_series_from_comics;
use hentai_core::{
    connection, find_series_by_id, init_db_at_path, set_series_item_sort_order_locked,
    set_series_items_order, update_series_item_sort_order,
};
use sea_orm::{ConnectionTrait, DatabaseConnection, Statement};
use tempfile::TempDir;

async fn seed_three_comics(db: &DatabaseConnection) {
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM series_items; DELETE FROM series; DELETE FROM comic_meta; DELETE FROM comics"
            .to_string(),
    ))
    .await
    .expect("clear");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
         VALUES ('c1', 'E:/lib/Series/vol1.cbz', 'cbz', 1, 1, 1), \
                ('c2', 'E:/lib/Series/vol2.cbz', 'cbz', 1, 1, 1), \
                ('c3', 'E:/lib/Series/vol3.cbz', 'cbz', 1, 1, 1)"
            .to_string(),
    ))
    .await
    .expect("seed comics");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
         VALUES ('c1', 'Vol1', 'unknown', 1), \
                ('c2', 'Vol2', 'unknown', 1), \
                ('c3', 'Vol3', 'unknown', 1)"
            .to_string(),
    ))
    .await
    .expect("seed meta");
}

#[test]
fn update_series_item_sort_order_sets_value_locks_and_reorders() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_three_comics(&db).await;
            rebuild_series_from_comics(&db, None)
                .await
                .expect("rebuild");

            let series =
                find_series_by_id(&hentai_core::series_id_from_folder_path("E:/lib/Series"))
                    .await
                    .expect("find")
                    .expect("series exists");
            assert_eq!(series.items.len(), 3);

            update_series_item_sort_order(&series.series_id, "c3", 1.5)
                .await
                .expect("update sort order");

            let series = find_series_by_id(&series.series_id)
                .await
                .expect("find")
                .expect("series exists");
            let by_id: std::collections::HashMap<&str, &hentai_core::SeriesItemDto> = series
                .items
                .iter()
                .map(|i| (i.comic_id.as_str(), i))
                .collect();
            let c3 = by_id.get("c3").expect("c3");
            assert!((c3.sort_order - 1.5).abs() < f64::EPSILON);
            assert!(c3.sort_order_locked);

            let ordered: Vec<&str> = series.items.iter().map(|i| i.comic_id.as_str()).collect();
            assert_eq!(ordered, vec!["c1", "c3", "c2"]);
        });
    });
}

#[test]
fn rebuild_preserves_locked_sort_order_and_renumbers_unlocked() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_three_comics(&db).await;
            rebuild_series_from_comics(&db, None).await.expect("rebuild");

            let series_id = hentai_core::series_id_from_folder_path("E:/lib/Series");
            update_series_item_sort_order(&series_id, "c2", 2.5)
                .await
                .expect("lock c2 at 2.5");

            // New comic sorts between vol2 and vol3 by filename (vol2a after vol2, before vol3).
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
                 VALUES ('c2a', 'E:/lib/Series/vol2a.cbz', 'cbz', 1, 1, 1)"
                    .to_string(),
            ))
            .await
            .expect("insert comic");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
                 VALUES ('c2a', 'Vol2a', 'unknown', 1)"
                    .to_string(),
            ))
            .await
            .expect("insert meta");

            rebuild_series_from_comics(&db, None).await.expect("rebuild again");

            let series = find_series_by_id(&series_id)
                .await
                .expect("find")
                .expect("series exists");
            let by_id: std::collections::HashMap<&str, &hentai_core::SeriesItemDto> = series
                .items
                .iter()
                .map(|i| (i.comic_id.as_str(), i))
                .collect();

            let c2 = by_id.get("c2").expect("c2");
            assert!((c2.sort_order - 2.5).abs() < f64::EPSILON);
            assert!(c2.sort_order_locked);

            // Natural order: vol1, vol2, vol2a, vol3 → unlocked get 1,2,3,4; c2 stays 2.5 locked.
            assert!((by_id.get("c1").expect("c1").sort_order - 1.0).abs() < f64::EPSILON);
            assert!(!by_id.get("c1").expect("c1").sort_order_locked);
            assert!((by_id.get("c2a").expect("c2a").sort_order - 3.0).abs() < f64::EPSILON);
            assert!(!by_id.get("c2a").expect("c2a").sort_order_locked);
            assert!((by_id.get("c3").expect("c3").sort_order - 4.0).abs() < f64::EPSILON);
            assert!(!by_id.get("c3").expect("c3").sort_order_locked);
        });
    });
}

#[test]
fn unlock_sort_order_allows_rebuild_to_renumber() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_three_comics(&db).await;
            rebuild_series_from_comics(&db, None)
                .await
                .expect("rebuild");

            let series_id = hentai_core::series_id_from_folder_path("E:/lib/Series");
            update_series_item_sort_order(&series_id, "c3", 1.5)
                .await
                .expect("lock c3");

            set_series_item_sort_order_locked(&series_id, "c3", false)
                .await
                .expect("unlock c3");

            rebuild_series_from_comics(&db, None)
                .await
                .expect("rebuild again");

            let series = find_series_by_id(&series_id)
                .await
                .expect("find")
                .expect("series exists");
            let by_id: std::collections::HashMap<&str, &hentai_core::SeriesItemDto> = series
                .items
                .iter()
                .map(|i| (i.comic_id.as_str(), i))
                .collect();
            assert!((by_id.get("c3").expect("c3").sort_order - 3.0).abs() < f64::EPSILON);
            assert!(!by_id.get("c3").expect("c3").sort_order_locked);
            let ordered: Vec<&str> = series.items.iter().map(|i| i.comic_id.as_str()).collect();
            assert_eq!(ordered, vec!["c1", "c2", "c3"]);
        });
    });
}

#[test]
fn set_series_items_order_reorders_all_unlocked_and_locks_all() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_three_comics(&db).await;
            rebuild_series_from_comics(&db, None)
                .await
                .expect("rebuild");

            let series_id = hentai_core::series_id_from_folder_path("E:/lib/Series");
            set_series_items_order(
                &series_id,
                vec!["c3".to_string(), "c1".to_string(), "c2".to_string()],
            )
            .await
            .expect("set order");

            let series = find_series_by_id(&series_id)
                .await
                .expect("find")
                .expect("series exists");
            let ordered: Vec<&str> = series.items.iter().map(|i| i.comic_id.as_str()).collect();
            assert_eq!(ordered, vec!["c3", "c1", "c2"]);
            // 全为未锁基线编号 1..n。
            let by_id: std::collections::HashMap<&str, &hentai_core::SeriesItemDto> = series
                .items
                .iter()
                .map(|i| (i.comic_id.as_str(), i))
                .collect();
            assert!((by_id.get("c3").unwrap().sort_order - 1.0).abs() < f64::EPSILON);
            assert!((by_id.get("c1").unwrap().sort_order - 2.0).abs() < f64::EPSILON);
            assert!((by_id.get("c2").unwrap().sort_order - 3.0).abs() < f64::EPSILON);
            // 本次提交成员一律加锁。
            assert!(series.items.iter().all(|i| i.sort_order_locked));
        });
    });
}

#[test]
fn set_series_items_order_preserves_locked_anchor_values() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_three_comics(&db).await;
            rebuild_series_from_comics(&db, None)
                .await
                .expect("rebuild");

            let series_id = hentai_core::series_id_from_folder_path("E:/lib/Series");
            // c1 锁在 1.0，c3 锁在 3.0；c2 保持未锁。
            update_series_item_sort_order(&series_id, "c1", 1.0)
                .await
                .expect("lock c1");
            update_series_item_sort_order(&series_id, "c3", 3.0)
                .await
                .expect("lock c3");
            set_series_item_sort_order_locked(&series_id, "c2", false)
                .await
                .expect("unlock c2");

            // 新序保持 c1, c2, c3；已锁锚点数值应保留，c2 落在夹缝之间。
            set_series_items_order(
                &series_id,
                vec!["c1".to_string(), "c2".to_string(), "c3".to_string()],
            )
            .await
            .expect("set order");

            let series = find_series_by_id(&series_id)
                .await
                .expect("find")
                .expect("series exists");
            let by_id: std::collections::HashMap<&str, &hentai_core::SeriesItemDto> = series
                .items
                .iter()
                .map(|i| (i.comic_id.as_str(), i))
                .collect();
            assert!((by_id.get("c1").unwrap().sort_order - 1.0).abs() < f64::EPSILON);
            assert!((by_id.get("c3").unwrap().sort_order - 3.0).abs() < f64::EPSILON);
            let c2 = by_id.get("c2").unwrap().sort_order;
            assert!(
                c2 > 1.0 && c2 < 3.0,
                "c2 should interpolate between anchors: {c2}"
            );
            // 全部加锁。
            assert!(series.items.iter().all(|i| i.sort_order_locked));
            let ordered: Vec<&str> = series.items.iter().map(|i| i.comic_id.as_str()).collect();
            assert_eq!(ordered, vec!["c1", "c2", "c3"]);
        });
    });
}

#[test]
fn set_series_items_order_reassigns_locked_when_relative_order_changes() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            seed_three_comics(&db).await;
            rebuild_series_from_comics(&db, None)
                .await
                .expect("rebuild");

            let series_id = hentai_core::series_id_from_folder_path("E:/lib/Series");
            update_series_item_sort_order(&series_id, "c1", 1.0)
                .await
                .expect("lock c1");
            update_series_item_sort_order(&series_id, "c2", 2.0)
                .await
                .expect("lock c2");
            update_series_item_sort_order(&series_id, "c3", 3.0)
                .await
                .expect("lock c3");

            // 把已锁的 c3 拖到最前：其原值 3.0 与后续锚点冲突，需重排为严格递增。
            set_series_items_order(
                &series_id,
                vec!["c3".to_string(), "c1".to_string(), "c2".to_string()],
            )
            .await
            .expect("set order");

            let series = find_series_by_id(&series_id)
                .await
                .expect("find")
                .expect("series exists");
            let ordered: Vec<&str> = series.items.iter().map(|i| i.comic_id.as_str()).collect();
            assert_eq!(ordered, vec!["c3", "c1", "c2"]);
            let values: Vec<f64> = series.items.iter().map(|i| i.sort_order).collect();
            for pair in values.windows(2) {
                assert!(pair[1] > pair[0], "strictly increasing: {values:?}");
            }
            assert!(series.items.iter().all(|i| i.sort_order_locked));
        });
    });
}
