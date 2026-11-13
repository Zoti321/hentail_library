mod common;

use std::collections::HashMap;

use hentai_core::resource::{
    parsed_to_comic, read_source_stat_with, FakeResourceAccess, ParsedResource,
};
use hentai_core::sync::plan::build_scan_replace_plan;
use hentai_core::sync::scanner::{scan_roots_with, ScanContext, ScanItem};
use hentai_core::sync::writer::apply_scan_replace_plan;
use hentai_core::{
    connection, create_sync_handle, find_comic_by_id, init_db_at_path, set_comic_meta_locks,
    update_comic_user_meta, ComicDto, ResourceFormatCategory, SetComicMetaLocksDto,
    UpdateComicUserMetaDto,
};
use sea_orm::{ConnectionTrait, DatabaseConnection, Statement};

const LOCATION: &str = "/library/book.cbz";

fn resource_comic(path: &str, title: &str) -> ComicDto {
    parsed_to_comic(&ParsedResource {
        path: path.into(),
        resource_type: "cbz".into(),
        resource_size: 123,
        page_count: 5,
        title: title.into(),
        authors: vec!["Source author".into()],
        description: Some("Source summary".into()),
        published_at: None,
    })
}

fn item(comic: ComicDto) -> ScanItem {
    ScanItem::from_resource(comic)
}

async fn seed(db: &DatabaseConnection) -> ComicDto {
    let comic = resource_comic(LOCATION, "Opening source title");
    let plan = build_scan_replace_plan(db, vec![item(comic.clone())], "")
        .await
        .unwrap();
    apply_scan_replace_plan(db, &plan, "").await.unwrap();
    find_comic_by_id(&comic.comic_id).await.unwrap().unwrap()
}

fn with_db(test: impl FnOnce(&tokio::runtime::Runtime, DatabaseConnection)) {
    common::with_global_db(|| {
        let root = tempfile::tempdir().unwrap().keep();
        let db_path = common::create_fixture_db(&root);
        let runtime = tokio::runtime::Runtime::new().unwrap();
        runtime.block_on(init_db_at_path(&db_path)).unwrap();
        test(&runtime, connection().unwrap());
    });
}

#[test]
fn scan_commit_preserves_user_values_locks_and_page_count_written_after_planning() {
    with_db(|runtime, db| {
        runtime.block_on(async {
            let existing = seed(&db).await;
            let plan = build_scan_replace_plan(
                &db,
                vec![item(resource_comic(LOCATION, "New source title"))],
                "",
            )
            .await
            .unwrap();
            let _library_write = hentai_core::try_acquire_library_write_lock().unwrap();
            update_comic_user_meta(
                &existing.comic_id,
                UpdateComicUserMetaDto {
                    title: Some("Newest user title".into()),
                    authors: Some(vec!["Newest author".into()]),
                    description: Some("Newest summary".into()),
                    languages: Some(vec!["ja".into()]),
                    ..Default::default()
                },
            )
            .await
            .unwrap();
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "UPDATE comic_meta SET page_count = 37 WHERE comic_id = ?",
                [existing.comic_id.clone().into()],
            ))
            .await
            .unwrap();
            let notifications = hentai_core::revision::notify_count();
            apply_scan_replace_plan(&db, &plan, "").await.unwrap();
            let current = find_comic_by_id(&existing.comic_id).await.unwrap().unwrap();
            assert_eq!(current.title, "Newest user title");
            assert_eq!(current.author_names(), ["Newest author"]);
            assert_eq!(current.description.as_deref(), Some("Newest summary"));
            assert_eq!(current.languages, ["ja"]);
            assert!(
                current.locks.title
                    && current.locks.authors
                    && current.locks.description
                    && current.locks.languages
            );
            assert_eq!(current.page_count, 37);
            assert_eq!(hentai_core::revision::notify_count(), notifications + 1);
        })
    });
}

#[test]
fn scan_commit_uses_source_values_after_a_lock_is_released_after_planning() {
    with_db(|runtime, db| {
        runtime.block_on(async {
            let existing = seed(&db).await;
            update_comic_user_meta(
                &existing.comic_id,
                UpdateComicUserMetaDto {
                    title: Some("Older locked title".into()),
                    ..Default::default()
                },
            )
            .await
            .unwrap();
            let plan = build_scan_replace_plan(
                &db,
                vec![item(resource_comic(LOCATION, "New source title"))],
                "",
            )
            .await
            .unwrap();
            set_comic_meta_locks(
                &existing.comic_id,
                SetComicMetaLocksDto {
                    title: Some(false),
                    ..Default::default()
                },
            )
            .await
            .unwrap();
            apply_scan_replace_plan(&db, &plan, "").await.unwrap();
            let current = find_comic_by_id(&existing.comic_id).await.unwrap().unwrap();
            assert_eq!(current.title, "New source title");
            assert!(!current.locks.title);
        })
    });
}

#[test]
fn scan_commit_missing_source_metadata_keeps_the_latest_unlocked_value() {
    with_db(|runtime, db| {
        runtime.block_on(async {
            let existing = seed(&db).await;
            let mut scanned = resource_comic(LOCATION, "New source title");
            scanned.description = None;
            let plan = build_scan_replace_plan(&db, vec![item(scanned)], "")
                .await
                .unwrap();
            update_comic_user_meta(
                &existing.comic_id,
                UpdateComicUserMetaDto {
                    description: Some("Newest unlocked summary".into()),
                    ..Default::default()
                },
            )
            .await
            .unwrap();
            set_comic_meta_locks(
                &existing.comic_id,
                SetComicMetaLocksDto {
                    description: Some(false),
                    ..Default::default()
                },
            )
            .await
            .unwrap();
            apply_scan_replace_plan(&db, &plan, "").await.unwrap();
            let current = find_comic_by_id(&existing.comic_id).await.unwrap().unwrap();
            assert_eq!(
                current.description.as_deref(),
                Some("Newest unlocked summary")
            );
            assert!(!current.locks.description);
        })
    });
}

#[test]
fn scan_reuse_does_not_treat_an_old_projection_as_resource_metadata() {
    with_db(|runtime, db| {
        runtime.block_on(async {
            let existing = seed(&db).await;
            let mut access = FakeResourceAccess::new();
            access.insert_file(LOCATION, b"reuse should not reopen or decode this stream");
            let stat = read_source_stat_with(&access, LOCATION, "cbz")
                .unwrap()
                .unwrap();
            let context = ScanContext {
                existing_by_id: HashMap::from([(existing.comic_id.clone(), existing.clone())]),
                thumbnail_stats: HashMap::from([(existing.comic_id.clone(), stat)]),
            };
            update_comic_user_meta(
                &existing.comic_id,
                UpdateComicUserMetaDto {
                    title: Some("Newest unlocked title".into()),
                    ..Default::default()
                },
            )
            .await
            .unwrap();
            set_comic_meta_locks(
                &existing.comic_id,
                SetComicMetaLocksDto {
                    title: Some(false),
                    ..Default::default()
                },
            )
            .await
            .unwrap();
            let scanned = scan_roots_with(
                &access,
                &[LOCATION.into()],
                &[],
                &context,
                &create_sync_handle(),
                false,
                &ResourceFormatCategory::ALL,
            )
            .unwrap();
            assert_eq!(scanned.len(), 1);
            let plan = build_scan_replace_plan(&db, scanned, "").await.unwrap();
            apply_scan_replace_plan(&db, &plan, "").await.unwrap();
            let current = find_comic_by_id(&existing.comic_id).await.unwrap().unwrap();
            assert_eq!(current.title, "Newest unlocked title");
            assert!(!current.locks.title);
        })
    });
}

#[test]
fn scan_migration_reloads_latest_metadata_and_keeps_live_child_attachments() {
    with_db(|runtime, db| {
        runtime.block_on(async {
            let existing = seed(&db).await;
            let moved = resource_comic("/moved/book.cbz", "New source title");
            let plan = build_scan_replace_plan(&db, vec![item(moved.clone())], "")
                .await
                .unwrap();
            assert_eq!(plan.migrations.len(), 1);
            update_comic_user_meta(
                &existing.comic_id,
                UpdateComicUserMetaDto {
                    title: Some("Newest moved title".into()),
                    languages: Some(vec!["zh".into()]),
                    tags: Some(vec!["Newest tag".into()]),
                    authors: Some(vec!["Newest author".into()]),
                    ..Default::default()
                },
            )
            .await
            .unwrap();
            apply_scan_replace_plan(&db, &plan, "").await.unwrap();
            assert!(find_comic_by_id(&existing.comic_id)
                .await
                .unwrap()
                .is_none());
            let current = find_comic_by_id(&moved.comic_id).await.unwrap().unwrap();
            assert_eq!(current.title, "Newest moved title");
            assert_eq!(current.languages, ["zh"]);
            assert_eq!(current.tags, ["Newest tag"]);
            assert_eq!(current.author_names(), ["Newest author"]);
            assert!(
                current.locks.title
                    && current.locks.languages
                    && current.locks.tags
                    && current.locks.authors
            );
        })
    });
}

#[test]
fn scan_commit_does_not_recreate_a_kept_comic_removed_after_planning() {
    with_db(|runtime, db| {
        runtime.block_on(async {
            let existing = seed(&db).await;
            let plan = build_scan_replace_plan(
                &db,
                vec![item(resource_comic(LOCATION, "New source title"))],
                "",
            )
            .await
            .unwrap();
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "DELETE FROM comics WHERE comic_id = ?",
                [existing.comic_id.clone().into()],
            ))
            .await
            .unwrap();
            let notifications = hentai_core::revision::notify_count();
            assert!(apply_scan_replace_plan(&db, &plan, "").await.is_err());
            assert!(find_comic_by_id(&existing.comic_id)
                .await
                .unwrap()
                .is_none());
            assert_eq!(hentai_core::revision::notify_count(), notifications);
        })
    });
}

#[test]
fn scan_commit_preserves_trash_for_kept_and_migrated_comics() {
    for destination in [LOCATION, "/moved/book.cbz"] {
        with_db(|runtime, db| {
            runtime.block_on(async {
                let existing = seed(&db).await;
                let scanned = resource_comic(destination, "New source title");
                let target_id = scanned.comic_id.clone();
                let plan = build_scan_replace_plan(&db, vec![item(scanned)], "")
                    .await
                    .unwrap();
                db.execute(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "UPDATE comics SET deleted_at = 20 WHERE comic_id = ?",
                    [existing.comic_id.into()],
                ))
                .await
                .unwrap();
                apply_scan_replace_plan(&db, &plan, "").await.unwrap();
                assert!(hentai_core::is_comic_trashed(&target_id).await.unwrap());
            })
        });
    }
}

#[test]
fn scan_reuse_requires_the_catalog_record_it_reused() {
    for another_record_remains in [false, true] {
        with_db(|runtime, db| {
            runtime.block_on(async {
                let existing = seed(&db).await;
                if another_record_remains {
                    let other = resource_comic("/library/other.cbz", "Other title");
                    let plan =
                        build_scan_replace_plan(&db, vec![item(existing.clone()), item(other)], "")
                            .await
                            .unwrap();
                    apply_scan_replace_plan(&db, &plan, "").await.unwrap();
                }
                let mut access = FakeResourceAccess::new();
                access.insert_file(LOCATION, vec![0; 123]);
                let stat = read_source_stat_with(&access, LOCATION, "cbz")
                    .unwrap()
                    .unwrap();
                let context = ScanContext {
                    existing_by_id: HashMap::from([(existing.comic_id.clone(), existing.clone())]),
                    thumbnail_stats: HashMap::from([(existing.comic_id.clone(), stat)]),
                };
                db.execute(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "DELETE FROM comics WHERE comic_id = ?",
                    [existing.comic_id.clone().into()],
                ))
                .await
                .unwrap();
                let scanned = scan_roots_with(
                    &access,
                    &[LOCATION.into()],
                    &[],
                    &context,
                    &create_sync_handle(),
                    false,
                    &ResourceFormatCategory::ALL,
                )
                .unwrap();
                assert_eq!(scanned.len(), 1);
                let notifications = hentai_core::revision::notify_count();
                let result = match build_scan_replace_plan(&db, scanned, "").await {
                    Ok(plan) => apply_scan_replace_plan(&db, &plan, "").await,
                    Err(error) => Err(error),
                };
                assert!(result.is_err());
                assert!(find_comic_by_id(&existing.comic_id)
                    .await
                    .unwrap()
                    .is_none());
                assert_eq!(hentai_core::revision::notify_count(), notifications);
            })
        });
    }
}
