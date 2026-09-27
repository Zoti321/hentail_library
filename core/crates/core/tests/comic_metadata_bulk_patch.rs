mod common;

use hentai_core::{
    apply_comic_metadata_bulk_patch, cancel_sync, connection, create_local_library,
    create_sync_handle, find_comic_by_id, init_db_at_path, set_current_library_id,
    try_acquire_library_write_lock, update_comic_user_meta, ComicMetadataBulkPatch, MultiValueOp,
    MultiValuePatch, PublishedAtPatch, ScalarPatch, UpdateComicUserMetaDto,
};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;

async fn clear_comics(db: &impl ConnectionTrait) {
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM comic_tags; DELETE FROM comic_authors; DELETE FROM comic_parodies; \
         DELETE FROM comic_characters; DELETE FROM comic_meta; DELETE FROM comics"
            .to_string(),
    ))
    .await
    .expect("clear comics");
}

async fn seed_comic(db: &impl ConnectionTrait, library_id: &str, comic_id: &str, title: &str) {
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, \
         last_updated_at, library_id) \
         VALUES (?, ?, 'cbz', 1, 1, 1, ?)",
        [
            sea_orm::Value::String(Some(Box::new(comic_id.to_string()))),
            sea_orm::Value::String(Some(Box::new(format!("E:/lib/{comic_id}.cbz")))),
            sea_orm::Value::String(Some(Box::new(library_id.to_string()))),
        ],
    ))
    .await
    .expect("seed comic");
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) VALUES (?, ?, 'unknown', 1)",
        [
            sea_orm::Value::String(Some(Box::new(comic_id.to_string()))),
            sea_orm::Value::String(Some(Box::new(title.to_string()))),
        ],
    ))
    .await
    .expect("seed meta");
}

async fn seed_two_comics_in_one_library() -> String {
    let lib = create_local_library("E:/lib", None)
        .await
        .expect("library");
    set_current_library_id(Some(&lib.library_id))
        .await
        .expect("current");
    let db = connection().expect("connection");
    clear_comics(&db).await;
    seed_comic(&db, &lib.library_id, "c1", "One").await;
    seed_comic(&db, &lib.library_id, "c2", "Two").await;
    lib.library_id
}

async fn seed_cross_library_comics() {
    let lib_a = create_local_library("E:/lib-a", Some("Lib A"))
        .await
        .expect("library a");
    let lib_b = create_local_library("E:/lib-b", Some("Lib B"))
        .await
        .expect("library b");
    let db = connection().expect("connection");
    clear_comics(&db).await;
    seed_comic(&db, &lib_a.library_id, "c1", "One").await;
    seed_comic(&db, &lib_b.library_id, "c2", "Two").await;
}

#[test]
fn bulk_patch_add_tags_merges_and_auto_locks() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            seed_two_comics_in_one_library().await;

            update_comic_user_meta(
                "c1",
                UpdateComicUserMetaDto {
                    tags: Some(vec!["existing".to_string()]),
                    ..Default::default()
                },
            )
            .await
            .expect("seed tags");

            let handle = create_sync_handle();
            let result = apply_comic_metadata_bulk_patch(
                vec!["c1".to_string(), "c2".to_string()],
                ComicMetadataBulkPatch {
                    tags: Some(MultiValuePatch {
                        op: MultiValueOp::Add,
                        values: vec!["new-tag".to_string()],
                    }),
                    ..Default::default()
                },
                &handle,
            )
            .await
            .expect("bulk patch");

            assert_eq!(result.succeeded, 2);
            assert_eq!(result.failed, 0);
            assert_eq!(result.unchanged, 0);
            assert!(!result.cancelled);

            let c1 = find_comic_by_id("c1").await.expect("find").expect("exists");
            assert_eq!(c1.tags, vec!["existing", "new-tag"]);
            assert!(c1.locks.tags);

            let c2 = find_comic_by_id("c2").await.expect("find").expect("exists");
            assert_eq!(c2.tags, vec!["new-tag"]);
            assert!(c2.locks.tags);
        });
    });
}

#[test]
fn bulk_patch_remove_tags_noop_counts_unchanged() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            seed_two_comics_in_one_library().await;

            update_comic_user_meta(
                "c1",
                UpdateComicUserMetaDto {
                    tags: Some(vec!["keep".to_string()]),
                    ..Default::default()
                },
            )
            .await
            .expect("seed tags");

            let handle = create_sync_handle();
            let result = apply_comic_metadata_bulk_patch(
                vec!["c1".to_string()],
                ComicMetadataBulkPatch {
                    tags: Some(MultiValuePatch {
                        op: MultiValueOp::Remove,
                        values: vec!["missing".to_string()],
                    }),
                    ..Default::default()
                },
                &handle,
            )
            .await
            .expect("bulk patch");

            assert_eq!(result.unchanged, 1);
            assert_eq!(result.succeeded, 0);
        });
    });
}

#[test]
fn bulk_patch_replace_authors_overwrites_list() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            seed_two_comics_in_one_library().await;

            update_comic_user_meta(
                "c1",
                UpdateComicUserMetaDto {
                    authors: Some(vec!["Old".to_string()]),
                    ..Default::default()
                },
            )
            .await
            .expect("seed authors");

            let handle = create_sync_handle();
            apply_comic_metadata_bulk_patch(
                vec!["c1".to_string()],
                ComicMetadataBulkPatch {
                    authors: Some(MultiValuePatch {
                        op: MultiValueOp::Replace,
                        values: vec!["New".to_string()],
                    }),
                    ..Default::default()
                },
                &handle,
            )
            .await
            .expect("bulk patch");

            let c1 = find_comic_by_id("c1").await.expect("find").expect("exists");
            assert_eq!(c1.authors, vec!["New"]);
            assert!(c1.locks.authors);
        });
    });
}

#[test]
fn bulk_patch_rejects_cross_library_ids() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            seed_cross_library_comics().await;

            let handle = create_sync_handle();
            let err = apply_comic_metadata_bulk_patch(
                vec!["c1".to_string(), "c2".to_string()],
                ComicMetadataBulkPatch {
                    tags: Some(MultiValuePatch {
                        op: MultiValueOp::Add,
                        values: vec!["tag".to_string()],
                    }),
                    ..Default::default()
                },
                &handle,
            )
            .await
            .expect_err("cross library");

            assert!(err.to_string().contains("跨 Library"));
        });
    });
}

#[test]
fn bulk_patch_cancel_stops_after_first_comic() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            seed_two_comics_in_one_library().await;

            let handle = create_sync_handle();
            apply_comic_metadata_bulk_patch(
                vec!["c1".to_string()],
                ComicMetadataBulkPatch {
                    tags: Some(MultiValuePatch {
                        op: MultiValueOp::Add,
                        values: vec!["first".to_string()],
                    }),
                    ..Default::default()
                },
                &handle,
            )
            .await
            .expect("prime c1");

            cancel_sync(&handle);
            let result = apply_comic_metadata_bulk_patch(
                vec!["c1".to_string(), "c2".to_string()],
                ComicMetadataBulkPatch {
                    tags: Some(MultiValuePatch {
                        op: MultiValueOp::Add,
                        values: vec!["second".to_string()],
                    }),
                    ..Default::default()
                },
                &handle,
            )
            .await
            .expect("cancelled batch");

            assert!(result.cancelled);
            assert_eq!(result.succeeded, 0);

            let c2 = find_comic_by_id("c2").await.expect("find").expect("exists");
            assert!(c2.tags.is_empty());
        });
    });
}

#[test]
fn bulk_patch_cancel_before_loop_processes_nothing() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            seed_two_comics_in_one_library().await;

            let handle = create_sync_handle();
            cancel_sync(&handle);
            let result = apply_comic_metadata_bulk_patch(
                vec!["c1".to_string(), "c2".to_string()],
                ComicMetadataBulkPatch {
                    tags: Some(MultiValuePatch {
                        op: MultiValueOp::Add,
                        values: vec!["tag".to_string()],
                    }),
                    ..Default::default()
                },
                &handle,
            )
            .await
            .expect("cancelled");

            assert!(result.cancelled);
            assert_eq!(result.succeeded, 0);
            assert_eq!(result.failed, 0);

            let c1 = find_comic_by_id("c1").await.expect("find").expect("exists");
            assert!(c1.tags.is_empty());
        });
    });
}

#[test]
fn bulk_patch_modifies_locked_fields() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            seed_two_comics_in_one_library().await;

            update_comic_user_meta(
                "c1",
                UpdateComicUserMetaDto {
                    tags: Some(vec!["locked-tag".to_string()]),
                    ..Default::default()
                },
            )
            .await
            .expect("seed locked tags");

            let handle = create_sync_handle();
            apply_comic_metadata_bulk_patch(
                vec!["c1".to_string()],
                ComicMetadataBulkPatch {
                    tags: Some(MultiValuePatch {
                        op: MultiValueOp::Add,
                        values: vec!["added".to_string()],
                    }),
                    ..Default::default()
                },
                &handle,
            )
            .await
            .expect("bulk patch");

            let c1 = find_comic_by_id("c1").await.expect("find").expect("exists");
            let mut tags = c1.tags.clone();
            tags.sort();
            assert_eq!(tags, vec!["added", "locked-tag"]);
            assert!(c1.locks.tags);
        });
    });
}

#[test]
fn bulk_patch_write_lock_is_exclusive() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            seed_two_comics_in_one_library().await;

            let _guard = try_acquire_library_write_lock().expect("lock");
            let handle = create_sync_handle();
            let err = apply_comic_metadata_bulk_patch(
                vec!["c1".to_string()],
                ComicMetadataBulkPatch {
                    tags: Some(MultiValuePatch {
                        op: MultiValueOp::Add,
                        values: vec!["tag".to_string()],
                    }),
                    ..Default::default()
                },
                &handle,
            )
            .await
            .expect_err("busy");

            assert!(err.to_string().contains("库写入操作进行中"));
        });
    });
}

#[test]
fn bulk_patch_missing_id_counts_failed() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            seed_two_comics_in_one_library().await;

            let handle = create_sync_handle();
            let result = apply_comic_metadata_bulk_patch(
                vec!["c1".to_string(), "missing".to_string()],
                ComicMetadataBulkPatch {
                    tags: Some(MultiValuePatch {
                        op: MultiValueOp::Add,
                        values: vec!["tag".to_string()],
                    }),
                    ..Default::default()
                },
                &handle,
            )
            .await
            .expect("bulk patch");

            assert_eq!(result.succeeded, 1);
            assert_eq!(result.failed, 1);
            assert!(!result.error_samples.is_empty());
        });
    });
}

#[test]
fn bulk_patch_rejects_over_cap_ids() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let ids: Vec<String> = (0..2001).map(|i| format!("c{i}")).collect();
            let handle = create_sync_handle();
            let err = apply_comic_metadata_bulk_patch(
                ids,
                ComicMetadataBulkPatch {
                    tags: Some(MultiValuePatch {
                        op: MultiValueOp::Add,
                        values: vec!["tag".to_string()],
                    }),
                    ..Default::default()
                },
                &handle,
            )
            .await
            .expect_err("cap");

            assert!(err.to_string().contains("2000"));
        });
    });
}

#[test]
fn bulk_patch_m2_languages_parodies_characters_merge() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            seed_two_comics_in_one_library().await;

            let handle = create_sync_handle();
            let result = apply_comic_metadata_bulk_patch(
                vec!["c1".to_string(), "c2".to_string()],
                ComicMetadataBulkPatch {
                    languages: Some(MultiValuePatch {
                        op: MultiValueOp::Add,
                        values: vec!["Japanese".to_string()],
                    }),
                    parodies: Some(MultiValuePatch {
                        op: MultiValueOp::Add,
                        values: vec!["Touhou".to_string()],
                    }),
                    characters: Some(MultiValuePatch {
                        op: MultiValueOp::Add,
                        values: vec!["Reimu".to_string()],
                    }),
                    ..Default::default()
                },
                &handle,
            )
            .await
            .expect("bulk patch");

            assert_eq!(result.succeeded, 2);
            let c1 = find_comic_by_id("c1").await.expect("find").expect("exists");
            assert_eq!(c1.languages, vec!["Japanese"]);
            assert_eq!(c1.parodies, vec!["Touhou"]);
            assert_eq!(c1.characters, vec!["Reimu"]);
            assert!(c1.locks.languages);
            assert!(c1.locks.parodies);
            assert!(c1.locks.characters);
        });
    });
}

#[test]
fn bulk_patch_m2_content_rating_description_published_at() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            seed_two_comics_in_one_library().await;

            update_comic_user_meta(
                "c1",
                UpdateComicUserMetaDto {
                    description: Some("old".to_string()),
                    published_at: Some(1_700_000_000_000),
                    ..Default::default()
                },
            )
            .await
            .expect("seed meta");

            let handle = create_sync_handle();
            apply_comic_metadata_bulk_patch(
                vec!["c1".to_string()],
                ComicMetadataBulkPatch {
                    content_rating: Some("r18".to_string()),
                    description: Some(ScalarPatch::Replace("new summary".to_string())),
                    published_at: Some(PublishedAtPatch::Clear),
                    ..Default::default()
                },
                &handle,
            )
            .await
            .expect("bulk patch");

            let c1 = find_comic_by_id("c1").await.expect("find").expect("exists");
            assert_eq!(c1.content_rating, "r18");
            assert_eq!(c1.description.as_deref(), Some("new summary"));
            assert!(c1.published_at.is_none());
            assert!(c1.locks.content_rating);
            assert!(c1.locks.description);
            assert!(c1.locks.published_at);
        });
    });
}

#[test]
fn bulk_patch_m2_rejects_invalid_content_rating() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            seed_two_comics_in_one_library().await;

            let handle = create_sync_handle();
            let err = apply_comic_metadata_bulk_patch(
                vec!["c1".to_string()],
                ComicMetadataBulkPatch {
                    content_rating: Some("unknown".to_string()),
                    ..Default::default()
                },
                &handle,
            )
            .await
            .expect_err("invalid rating");

            assert!(err.to_string().contains("safe / r18"));
        });
    });
}
