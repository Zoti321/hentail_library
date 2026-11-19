#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

mod common;
use hentai_core::*;
use sea_orm::{ConnectionTrait, Statement};

async fn sync(library_id: &str) {
    sync_library(
        create_sync_handle(),
        SyncScanMode::Full,
        false,
        Some(library_id),
        vec![],
        |_| {},
    )
    .await
    .unwrap();
}

#[test]
fn full_content_match_preserves_comic_and_series_state_after_folder_move() {
    common::with_global_db(|| {
        let root = tempfile::tempdir().unwrap().keep();
        let library_root = root.join("library");
        let old_folder = library_root.join("old");
        let old_path = old_folder.join("book.cbz");
        common::write_cbz(&old_path, 1);
        tokio::runtime::Runtime::new().unwrap().block_on(async {
            init_db_at_path(&root.join("db.sqlite")).await.unwrap();
            let library = create_local_library(&library_root.to_string_lossy(), None).await.unwrap();
            sync(&library.library_id).await;
            let old_id = comic_id_from_path(&old_path.to_string_lossy());
            let old_series = series_id_from_folder_path(&old_folder.to_string_lossy());
            update_comic_user_meta(&old_id, UpdateComicUserMetaDto { title: Some("My title".into()), tags: Some(vec!["My tag".into()]), ..Default::default() }).await.unwrap();
            record_reading(&ReadingHistoryDto { comic_id: old_id.clone(), title: "My title".into(), last_read_time_ms: now_ms(), page_index: Some(1), page_count: None }).await.unwrap();
            update_series_user_meta(&old_series, UpdateSeriesUserMetaDto { name: Some("My series".into()), ..Default::default() }).await.unwrap();
            update_series_item_sort_order(&old_series, &old_id, 9.5).await.unwrap();
            let db = connection().unwrap();
            db.execute(Statement::from_sql_and_values(sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_thumbnails (comic_id, thumbnail, updated_at, is_user_set) VALUES (?, X'0102', 1, 1)", [old_id.clone().into()])).await.unwrap();
            db.execute(Statement::from_sql_and_values(sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_finished_marks (comic_id, finished_at_ms) VALUES (?, 1)", [old_id.clone().into()])).await.unwrap();
            let new_folder = library_root.join("new");
            std::fs::rename(&old_folder, &new_folder).unwrap();
            let new_id = comic_id_from_path(&new_folder.join("book.cbz").to_string_lossy());
            sync(&library.library_id).await;
            assert!(find_comic_by_id(&old_id).await.unwrap().is_none());
            let comic = find_comic_by_id(&new_id).await.unwrap().unwrap();
            assert_eq!(comic.title, "My title");
            assert_eq!(comic.tags, ["My tag"]);
            assert!(comic.locks.title && comic.locks.tags);
            assert_eq!(get_reading_by_comic_id(&new_id).await.unwrap().unwrap().page_index, Some(1));
            let new_series = series_id_from_folder_path(&new_folder.to_string_lossy());
            let series = find_series_by_id(&new_series).await.unwrap().unwrap();
            assert_eq!(series.name, "My series");
            assert!(series.items[0].sort_order_locked);
            assert_eq!(series.items[0].sort_order, 9.5);
            let thumb = db.query_one(Statement::from_sql_and_values(sea_orm::DatabaseBackend::Sqlite,
                "SELECT thumbnail FROM comic_thumbnails WHERE comic_id = ?", [new_id.clone().into()])).await.unwrap().unwrap();
            assert_eq!(thumb.try_get::<Vec<u8>>("", "thumbnail").unwrap(), [1, 2]);
            let finished = db.query_one(Statement::from_sql_and_values(sea_orm::DatabaseBackend::Sqlite,
                "SELECT comic_id FROM comic_finished_marks WHERE comic_id = ?", [new_id.into()])).await.unwrap();
            assert!(finished.is_some());
            sync(&library.library_id).await;
        });
    });
}

#[test]
fn equal_size_different_content_and_ambiguous_copies_never_inherit_state() {
    for identical in [false, true] {
        common::with_global_db(|| {
            let root = tempfile::tempdir().unwrap().keep();
            let library_root = root.join("library");
            let old = library_root.join("old.cbz");
            common::write_cbz(&old, 1);
            tokio::runtime::Runtime::new().unwrap().block_on(async {
                init_db_at_path(&root.join("db.sqlite")).await.unwrap();
                let library = create_local_library(&library_root.to_string_lossy(), None)
                    .await
                    .unwrap();
                sync(&library.library_id).await;
                let old_id = comic_id_from_path(&old.to_string_lossy());
                update_comic_user_meta(
                    &old_id,
                    UpdateComicUserMetaDto {
                        title: Some("Private title".into()),
                        ..Default::default()
                    },
                )
                .await
                .unwrap();
                let bytes = std::fs::read(&old).unwrap();
                std::fs::rename(&old, root.join("outside.cbz")).unwrap();
                let added = library_root.join("new.cbz");
                if identical {
                    std::fs::write(&added, &bytes).unwrap();
                    std::fs::write(library_root.join("copy.cbz"), &bytes).unwrap();
                } else {
                    // Stored page bytes have the same length, so the weak tuple is unchanged.
                    let mut changed = bytes.clone();
                    let offset = changed.windows(4).position(|part| part == b"page").unwrap();
                    changed[offset..offset + 4].copy_from_slice(b"else");
                    std::fs::write(&added, changed).unwrap();
                }
                sync(&library.library_id).await;
                let new_id = comic_id_from_path(&added.to_string_lossy());
                assert_ne!(
                    find_comic_by_id(&new_id).await.unwrap().unwrap().title,
                    "Private title"
                );
            });
        });
    }
}

#[test]
fn image_directory_rename_preserves_state_but_page_order_is_part_of_digest() {
    common::with_global_db(|| {
        let root = tempfile::tempdir().unwrap().keep();
        let library_root = root.join("library");
        let old = library_root.join("pages");
        std::fs::create_dir_all(&old).unwrap();
        std::fs::write(old.join("1.jpg"), b"first").unwrap();
        std::fs::write(old.join("2.jpg"), b"second").unwrap();
        tokio::runtime::Runtime::new().unwrap().block_on(async {
            init_db_at_path(&root.join("db.sqlite")).await.unwrap();
            let library = create_local_library(&library_root.to_string_lossy(), None)
                .await
                .unwrap();
            sync(&library.library_id).await;
            let old_id = comic_id_from_path(&old.to_string_lossy());
            update_comic_user_meta(
                &old_id,
                UpdateComicUserMetaDto {
                    title: Some("Directory title".into()),
                    ..Default::default()
                },
            )
            .await
            .unwrap();
            let new = library_root.join("renamed");
            std::fs::rename(&old, &new).unwrap();
            sync(&library.library_id).await;
            let new_id = comic_id_from_path(&new.to_string_lossy());
            assert_eq!(
                find_comic_by_id(&new_id).await.unwrap().unwrap().title,
                "Directory title"
            );
            let changed = library_root.join("reordered");
            std::fs::rename(&new, &changed).unwrap();
            std::fs::write(changed.join("1.jpg"), b"second").unwrap();
            std::fs::write(changed.join("2.jpg"), b"first").unwrap();
            sync(&library.library_id).await;
            let changed_id = comic_id_from_path(&changed.to_string_lossy());
            assert_ne!(
                find_comic_by_id(&changed_id).await.unwrap().unwrap().title,
                "Directory title"
            );
        });
    });
}

#[test]
fn remote_hash_is_cached_and_renamed_content_is_verified_before_rekey() {
    use hentai_core::resource::{
        FakeResourceAccess, ResourceAccess, ResourceEntry, ResourceStat, ResourceStream,
    };
    use hentai_core::sync::{
        fingerprint::prepare_content_fingerprints,
        plan::build_scan_replace_plan,
        remote::{scan_remote_lightweight, RemoteScanOutcome},
        scanner::ScanContext,
        writer::apply_scan_replace_plan,
    };
    use std::sync::atomic::{AtomicUsize, Ordering};
    struct Access {
        fake: FakeResourceAccess,
        opens: AtomicUsize,
    }
    impl ResourceAccess for Access {
        fn stat(&self, path: &str) -> Result<Option<ResourceStat>, HentaiError> {
            self.fake.stat(path)
        }
        fn list(&self, path: &str) -> Result<Vec<ResourceEntry>, HentaiError> {
            self.fake.list(path)
        }
        fn open_stream(&self, path: &str) -> Result<ResourceStream, HentaiError> {
            self.opens.fetch_add(1, Ordering::SeqCst);
            self.fake.open_stream(path)
        }
    }
    common::with_global_db(|| {
        let root = tempfile::tempdir().unwrap().keep();
        tokio::runtime::Runtime::new().unwrap().block_on(async {
            init_db_at_path(&root.join("db.sqlite")).await.unwrap();
            let library = create_remote_library("https://example.test/dav", "u", false, None)
                .await
                .unwrap();
            let db = connection().unwrap();
            for (index, name) in ["old.cbz", "old.cbz", "new.cbz"].into_iter().enumerate() {
                let mut fake = FakeResourceAccess::new();
                fake.insert_dir(&library.root_path);
                let path = format!("{}/{name}", library.root_path);
                fake.insert_file(&path, b"exact-content");
                fake.set_modified_ms(&path, 100);
                let access = Access {
                    fake,
                    opens: AtomicUsize::new(0),
                };
                let context = ScanContext {
                    existing_by_id: Default::default(),
                    thumbnail_stats: Default::default(),
                };
                let RemoteScanOutcome::Scanned(mut items) = scan_remote_lightweight(
                    &access,
                    &library.root_path,
                    &context,
                    &create_sync_handle(),
                    &ResourceFormatCategory::ALL,
                )
                .unwrap() else {
                    panic!("scanned");
                };
                for item in &mut items {
                    item.comic.library_id = library.library_id.clone();
                }
                assert!(prepare_content_fingerprints(
                    &db,
                    &library.library_id,
                    &access,
                    &mut items,
                    &create_sync_handle()
                )
                .await
                .unwrap());
                assert_eq!(access.opens.load(Ordering::SeqCst), usize::from(index != 1));
                let plan = build_scan_replace_plan(&db, items, &library.library_id)
                    .await
                    .unwrap();
                assert_eq!(plan.migrated_count, i32::from(index == 2));
                apply_scan_replace_plan(&db, &plan, &library.library_id)
                    .await
                    .unwrap();
                let id = sync::remote::comic_id_for_remote_location(&path);
                if index == 0 {
                    update_comic_user_meta(
                        &id,
                        UpdateComicUserMetaDto {
                            title: Some("Remote title".into()),
                            ..Default::default()
                        },
                    )
                    .await
                    .unwrap();
                }
                assert_eq!(
                    find_comic_by_id(&id).await.unwrap().unwrap().title,
                    "Remote title"
                );
            }
        });
    });
}
