//! Catalog kind: Comic vs Image set library creation, nesting, and delete.

mod common;

use hentai_core::library_write::try_acquire_library_write_lock;
use hentai_core::{
    create_image_set_local_library, create_local_library, create_sync_handle, delete_library,
    init_db_at_path, list_image_set_images, list_image_sets, list_libraries, sync_library,
    update_library_settings, update_local_library_root, ResourceFormatCategory, ScanInterval,
    SyncScanMode,
};
use tempfile::TempDir;

#[test]
fn create_image_set_and_comic_libraries_keep_orthogonal_catalog_kind() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("catalog_kind.sqlite");
        let comic_root = temp.path().join("comic");
        let image_root = temp.path().join("images");
        std::fs::create_dir_all(&comic_root).expect("mkdir comic");
        std::fs::create_dir_all(&image_root).expect("mkdir images");

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let comic = create_local_library(&comic_root.to_string_lossy(), Some("Comics"))
                .await
                .expect("create comic");
            let image = create_image_set_local_library(
                &image_root.to_string_lossy(),
                Some("Illustrations"),
            )
            .await
            .expect("create image set");

            assert_eq!(comic.kind, "local");
            assert_eq!(comic.catalog_kind, "comic");
            assert!(!comic.enabled_resource_format_categories.is_empty());

            assert_eq!(image.kind, "local");
            assert_eq!(image.catalog_kind, "image_set");
            assert!(image.enabled_resource_format_categories.is_empty());
            assert!(!image.scan_on_startup);
            assert_eq!(image.scan_interval, ScanInterval::Disabled);

            let listed = list_libraries().await.expect("list");
            assert_eq!(listed.len(), 2);
            assert!(listed.iter().any(|l| l.catalog_kind == "comic"));
            assert!(listed.iter().any(|l| l.catalog_kind == "image_set"));
        });
    });
}

#[test]
fn local_roots_reject_equal_or_nested_across_catalog_kinds() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("nested.sqlite");
        let comic_root = temp.path().join("root");
        let nested = comic_root.join("nested");
        std::fs::create_dir_all(&nested).expect("mkdir nested");

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            create_local_library(&comic_root.to_string_lossy(), Some("Comics"))
                .await
                .expect("create comic");

            let err = create_image_set_local_library(&nested.to_string_lossy(), Some("Nested"))
                .await
                .expect_err("nested image set under comic root");
            assert!(
                err.message.contains("嵌套"),
                "expected nesting error, got {}",
                err.message
            );

            let err = create_image_set_local_library(&comic_root.to_string_lossy(), Some("Same"))
                .await
                .expect_err("same root different catalog kind");
            assert!(
                err.message.contains("catalog kind") || err.message.contains("嵌套"),
                "expected conflict, got {}",
                err.message
            );
        });
    });
}

#[test]
fn image_set_library_allows_scan_settings_and_keeps_files_on_delete() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("image_set_delete.sqlite");
        let root = temp.path().join("images");
        let marker = root.join("keep-me.txt");
        std::fs::create_dir_all(&root).expect("mkdir");
        std::fs::write(&marker, b"stay").expect("write marker");

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let library =
                create_image_set_local_library(&root.to_string_lossy(), Some("Illustrations"))
                    .await
                    .expect("create");

            let updated = update_library_settings(
                &library.library_id,
                "Renamed",
                vec![],
                true,
                ScanInterval::Hourly,
            )
            .await
            .expect("image set startup/interval settings");
            assert!(updated.scan_on_startup);
            assert_eq!(updated.scan_interval, ScanInterval::Hourly);

            let formats_err = update_library_settings(
                &library.library_id,
                "Renamed",
                vec![ResourceFormatCategory::Archive],
                true,
                ScanInterval::Hourly,
            )
            .await
            .expect_err("image set rejects comic formats");
            assert!(
                formats_err.message.contains("格式多选"),
                "{}",
                formats_err.message
            );

            delete_library(&library.library_id)
                .await
                .expect("delete image set library");
            assert!(
                list_libraries().await.expect("list").is_empty(),
                "library row removed"
            );
            assert!(marker.exists(), "disk files must remain");
        });
    });
}

#[test]
fn image_set_library_root_remap_preserves_relative_catalog_ids() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("image_set_remap.sqlite");
        let root = temp.path().join("images");
        let moved = temp.path().join("images_moved");
        std::fs::create_dir_all(root.join("album")).expect("mkdir album");
        std::fs::write(root.join("album/01.jpg"), b"img").expect("write");

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let library =
                create_image_set_local_library(&root.to_string_lossy(), Some("Illustrations"))
                    .await
                    .expect("create");
            sync_library(
                create_sync_handle(),
                SyncScanMode::Full,
                false,
                Some(library.library_id.as_str()),
                vec![],
                |_| {},
            )
            .await
            .expect("sync");

            let before_sets = list_image_sets(&library.library_id).await.expect("sets");
            assert_eq!(before_sets.len(), 1);
            let set_id = before_sets[0].image_set_id.clone();
            let before_images = list_image_set_images(&library.library_id, &set_id)
                .await
                .expect("images");
            assert_eq!(before_images.len(), 1);
            let image_id = before_images[0].image_set_image_id.clone();

            std::fs::rename(&root, &moved).expect("move root");
            let updated = update_local_library_root(&library.library_id, &moved.to_string_lossy())
                .await
                .expect("remap");
            assert_eq!(updated.library_id, library.library_id);
            assert_eq!(updated.root_path, moved.to_string_lossy());

            let after_sets = list_image_sets(&library.library_id)
                .await
                .expect("sets after");
            assert_eq!(after_sets.len(), 1);
            assert_eq!(after_sets[0].image_set_id, set_id);
            let after_images = list_image_set_images(&library.library_id, &set_id)
                .await
                .expect("images after");
            assert_eq!(after_images[0].image_set_image_id, image_id);
        });
    });
}

#[test]
fn image_set_library_unreadable_root_updates_path_without_dropping_catalog() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("image_set_unreadable.sqlite");
        let root = temp.path().join("images");
        std::fs::create_dir_all(root.join("album")).expect("mkdir");
        std::fs::write(root.join("album/01.jpg"), b"img").expect("write");
        let missing = temp.path().join("missing_root");

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let library =
                create_image_set_local_library(&root.to_string_lossy(), Some("Illustrations"))
                    .await
                    .expect("create");
            sync_library(
                create_sync_handle(),
                SyncScanMode::Full,
                false,
                Some(library.library_id.as_str()),
                vec![],
                |_| {},
            )
            .await
            .expect("sync");
            let before = list_image_sets(&library.library_id).await.expect("sets");
            assert_eq!(before.len(), 1);

            let updated =
                update_local_library_root(&library.library_id, &missing.to_string_lossy())
                    .await
                    .expect("save unreadable root");
            assert_eq!(updated.root_path, missing.to_string_lossy());
            let after = list_image_sets(&library.library_id)
                .await
                .expect("sets after");
            assert_eq!(after.len(), 1);
            assert_eq!(after[0].image_set_id, before[0].image_set_id);
        });
    });
}

#[test]
fn delete_image_set_library_fails_fast_while_write_lock_busy() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("busy.sqlite");
        let root = temp.path().join("images");
        std::fs::create_dir_all(&root).expect("mkdir");

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let library =
                create_image_set_local_library(&root.to_string_lossy(), Some("Illustrations"))
                    .await
                    .expect("create");

            let _guard = try_acquire_library_write_lock().expect("hold lock");
            let err = delete_library(&library.library_id)
                .await
                .expect_err("busy delete");
            assert!(err.message.contains("库写入操作进行中"), "{}", err.message);
            drop(_guard);

            delete_library(&library.library_id)
                .await
                .expect("delete after unlock");
        });
    });
}
