//! Catalog kind: Comic vs Image set library creation, nesting, and delete.

mod common;

use hentai_core::library_write::try_acquire_library_write_lock;
use hentai_core::{
    create_image_set_local_library, create_local_library, delete_library, init_db_at_path,
    list_libraries, update_library_settings, update_local_library_root, ScanInterval,
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
fn image_set_library_rejects_root_remap_and_keeps_files_on_delete() {
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

            let remap_err = update_local_library_root(
                &library.library_id,
                &temp.path().join("other").to_string_lossy(),
            )
            .await
            .expect_err("image set root remap");
            assert!(
                remap_err.message.contains("不支持更改 Local root"),
                "{}",
                remap_err.message
            );

            let settings_err = update_library_settings(
                &library.library_id,
                "Renamed",
                vec![],
                true,
                ScanInterval::Hourly,
            )
            .await
            .expect_err("image set scheduled sync");
            assert!(
                settings_err.message.contains("手动同步"),
                "{}",
                settings_err.message
            );

            update_library_settings(
                &library.library_id,
                "Renamed",
                vec![],
                false,
                ScanInterval::Disabled,
            )
            .await
            .expect("rename only");

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
