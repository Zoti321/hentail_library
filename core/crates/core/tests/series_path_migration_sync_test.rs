#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

mod common;

use std::collections::HashMap;
use std::fs::File;
use std::io::Write;
use std::path::Path;

use hentai_core::sync::handle::create_sync_handle;
use hentai_core::sync::plan::build_scan_replace_plan;
use hentai_core::sync::resource_format_category::ResourceFormatCategory;
use hentai_core::sync::scanner::{scan_roots, ScanContext};
use hentai_core::sync::writer::apply_scan_replace_plan;
use hentai_core::{
    comic_id_from_path, connection, find_comic_by_id, find_series_by_id,
    find_series_thumbnail_by_series_id, init_db_at_path, series_id_from_folder_path,
    set_series_meta_locks, update_series_item_sort_order, update_series_user_meta,
    SetSeriesMetaLocksDto, UpdateSeriesUserMetaDto,
};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;
use zip::write::SimpleFileOptions;
use zip::ZipWriter;

/// Distinct page counts → unique weak fingerprints for Path migration pairing.
fn write_cbz_pages(path: &Path, page_count: usize) {
    let file = File::create(path).expect("create");
    let mut zip = ZipWriter::new(file);
    for i in 1..=page_count {
        zip.start_file(format!("{i:02}.jpg"), SimpleFileOptions::default())
            .expect("start");
        zip.write_all(format!("page-{i}").as_bytes())
            .expect("write");
    }
    zip.finish().expect("finish");
}

fn norm(path: &Path) -> String {
    path.to_string_lossy().replace('\\', "/")
}

async fn sync_once(root: &Path) {
    let db = connection().expect("connection");
    let handle = create_sync_handle();
    let empty_ctx = ScanContext {
        existing_by_id: HashMap::new(),
        thumbnail_stats: HashMap::new(),
    };
    let scanned = scan_roots(
        std::slice::from_ref(&root.to_path_buf()),
        &empty_ctx,
        &handle,
        true,
        &ResourceFormatCategory::ALL,
    )
    .expect("scan");
    let plan = build_scan_replace_plan(&db, scanned, "")
        .await
        .expect("plan");
    apply_scan_replace_plan(&db, &plan, "")
        .await
        .expect("apply");
}

async fn seed_series_user_state(
    series_id: &str,
    first_comic_id: &str,
    second_comic_id: &str,
    lock_name: bool,
) {
    update_series_user_meta(
        series_id,
        UpdateSeriesUserMetaDto {
            name: if lock_name {
                Some("自定义系列名".to_string())
            } else {
                None
            },
            serialization_status: Some("ongoing".to_string()),
            total_count: Some(12),
            clear_total_count: false,
        },
    )
    .await
    .expect("series meta");
    if !lock_name {
        set_series_meta_locks(
            series_id,
            SetSeriesMetaLocksDto {
                name: Some(false),
                serialization_status: Some(true),
                total_count: Some(true),
            },
        )
        .await
        .expect("locks");
    }
    update_series_item_sort_order(series_id, first_comic_id, 9.5)
        .await
        .expect("lock order 1");
    update_series_item_sort_order(series_id, second_comic_id, 2.5)
        .await
        .expect("lock order 2");

    let db = connection().expect("connection");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        format!(
            "INSERT INTO series_thumbnails (series_id, thumbnail, updated_at, source_comic_id, source_page_index) \
             VALUES ('{series_id}', X'0102', 7, '{first_comic_id}', 0)"
        ),
    ))
    .await
    .expect("series thumb");
}

#[test]
fn unverified_folder_rename_creates_default_series() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir").keep();
        let db_path = common::create_fixture_db(temp.as_path());
        let root = temp.as_path().join("library");
        let series_dir = root.join("SeriesOld");
        std::fs::create_dir_all(&series_dir).expect("mkdir");
        write_cbz_pages(&series_dir.join("01.cbz"), 1);
        write_cbz_pages(&series_dir.join("02.cbz"), 2);
        let comic_a = comic_id_from_path(&norm(&series_dir.join("01.cbz")));
        let comic_b = comic_id_from_path(&norm(&series_dir.join("02.cbz")));
        let old_series_id = series_id_from_folder_path(&norm(&series_dir));

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            sync_once(&root).await;
            seed_series_user_state(&old_series_id, &comic_a, &comic_b, false).await;

            let renamed = root.join("SeriesNew");
            std::fs::rename(&series_dir, &renamed).expect("rename folder");
            let new_series_id = series_id_from_folder_path(&norm(&renamed));

            let db = connection().expect("connection");
            let handle = create_sync_handle();
            let empty_ctx = ScanContext {
                existing_by_id: HashMap::new(),
                thumbnail_stats: HashMap::new(),
            };
            let scanned = scan_roots(
                std::slice::from_ref(&root),
                &empty_ctx,
                &handle,
                true,
                &ResourceFormatCategory::ALL,
            )
            .expect("scan");
            let plan = build_scan_replace_plan(&db, scanned, "")
                .await
                .expect("plan");
            assert_eq!(plan.migrated_count, 0);
            assert_eq!(plan.series_migrations.len(), 0);
            apply_scan_replace_plan(&db, &plan, "")
                .await
                .expect("apply");

            assert!(find_series_by_id(&old_series_id)
                .await
                .expect("old")
                .is_none());
            let series = find_series_by_id(&new_series_id)
                .await
                .expect("new")
                .expect("exists");
            assert_eq!(series.name, "SeriesNew");
            assert!(!series.locks.name);
            assert_eq!(series.serialization_status, "unknown");
            assert_eq!(series.total_count, None);
            assert!(!series.locks.serialization_status);
            assert!(!series.locks.total_count);
            assert_eq!(series.items.len(), 2);
            assert!(series.items.iter().all(|item| !item.sort_order_locked));

            assert!(find_series_thumbnail_by_series_id(&new_series_id)
                .await
                .unwrap()
                .is_none());
        });
    });
}

#[test]
fn unverified_folder_move_does_not_transfer_locked_state() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir").keep();
        let db_path = common::create_fixture_db(temp.as_path());
        let root = temp.as_path().join("library");
        let series_dir = root.join("SeriesOld");
        std::fs::create_dir_all(&series_dir).expect("mkdir");
        write_cbz_pages(&series_dir.join("01.cbz"), 1);
        write_cbz_pages(&series_dir.join("02.cbz"), 2);
        let comic_a = comic_id_from_path(&norm(&series_dir.join("01.cbz")));
        let comic_b = comic_id_from_path(&norm(&series_dir.join("02.cbz")));
        let old_series_id = series_id_from_folder_path(&norm(&series_dir));

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            sync_once(&root).await;
            seed_series_user_state(&old_series_id, &comic_a, &comic_b, true).await;

            let nested = root.join("shelf").join("SeriesMoved");
            std::fs::create_dir_all(nested.parent().unwrap()).expect("mkdir parent");
            std::fs::rename(&series_dir, &nested).expect("move folder");
            let new_series_id = series_id_from_folder_path(&norm(&nested));

            sync_once(&root).await;

            assert!(find_series_by_id(&old_series_id)
                .await
                .expect("old")
                .is_none());
            let series = find_series_by_id(&new_series_id)
                .await
                .expect("new")
                .expect("exists");
            assert_ne!(series.name, "自定义系列名");
            assert!(!series.locks.name);
            assert_eq!(series.serialization_status, "unknown");
            assert_eq!(series.total_count, None);
            assert!(!series.locks.serialization_status);
            assert!(!series.locks.total_count);
            assert_eq!(series.items.len(), 2);
            assert!(series.items.iter().all(|item| !item.sort_order_locked));

            assert!(find_series_thumbnail_by_series_id(&new_series_id)
                .await
                .unwrap()
                .is_none());
        });
    });
}

#[test]
fn partial_member_move_keeps_old_series_state_and_creates_default_destination() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir").keep();
        let db_path = common::create_fixture_db(temp.as_path());
        let root = temp.as_path().join("library");
        let series_dir = root.join("SeriesOld");
        std::fs::create_dir_all(&series_dir).expect("mkdir");
        write_cbz_pages(&series_dir.join("01.cbz"), 1);
        write_cbz_pages(&series_dir.join("02.cbz"), 2);
        let comic_a = comic_id_from_path(&norm(&series_dir.join("01.cbz")));
        let comic_b = comic_id_from_path(&norm(&series_dir.join("02.cbz")));
        let old_series_id = series_id_from_folder_path(&norm(&series_dir));

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            sync_once(&root).await;
            seed_series_user_state(&old_series_id, &comic_a, &comic_b, true).await;

            let dest = root.join("SeriesSplit");
            std::fs::create_dir_all(&dest).expect("mkdir dest");
            std::fs::rename(series_dir.join("01.cbz"), dest.join("01.cbz")).expect("move one");
            let dest_series_id = series_id_from_folder_path(&norm(&dest));

            let db = connection().expect("connection");
            let handle = create_sync_handle();
            let empty_ctx = ScanContext {
                existing_by_id: HashMap::new(),
                thumbnail_stats: HashMap::new(),
            };
            let scanned = scan_roots(
                std::slice::from_ref(&root),
                &empty_ctx,
                &handle,
                true,
                &ResourceFormatCategory::ALL,
            )
            .expect("scan");
            let plan = build_scan_replace_plan(&db, scanned, "")
                .await
                .expect("plan");
            assert_eq!(plan.migrated_count, 0);
            assert_eq!(plan.series_migrations.len(), 0);
            apply_scan_replace_plan(&db, &plan, "")
                .await
                .expect("apply");

            let old = find_series_by_id(&old_series_id)
                .await
                .expect("old")
                .expect("still exists");
            assert_eq!(old.name, "自定义系列名");
            assert_eq!(old.serialization_status, "ongoing");
            assert_eq!(old.total_count, Some(12));
            assert_eq!(old.items.len(), 1);
            assert_eq!(old.items[0].comic_id, comic_b);

            let dest_series = find_series_by_id(&dest_series_id)
                .await
                .expect("dest")
                .expect("new series");
            assert_eq!(dest_series.name, "SeriesSplit");
            assert_eq!(dest_series.serialization_status, "unknown");
            assert_eq!(dest_series.total_count, None);
            assert!(!dest_series.locks.name);
            assert!(!dest_series.locks.serialization_status);
            assert!(!dest_series.locks.total_count);
        });
    });
}

#[test]
fn ambiguous_comic_fingerprints_skip_series_migration() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir").keep();
        let db_path = common::create_fixture_db(temp.as_path());
        let root = temp.as_path().join("library");
        let series_dir = root.join("SeriesOld");
        std::fs::create_dir_all(&series_dir).expect("mkdir");
        // Same page count → identical weak fingerprint → comic migration skipped.
        write_cbz_pages(&series_dir.join("01.cbz"), 1);
        write_cbz_pages(&series_dir.join("02.cbz"), 1);
        let comic_a = comic_id_from_path(&norm(&series_dir.join("01.cbz")));
        let comic_b = comic_id_from_path(&norm(&series_dir.join("02.cbz")));
        let old_series_id = series_id_from_folder_path(&norm(&series_dir));

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            sync_once(&root).await;
            seed_series_user_state(&old_series_id, &comic_a, &comic_b, true).await;

            let renamed = root.join("SeriesNew");
            std::fs::rename(&series_dir, &renamed).expect("rename");
            let new_series_id = series_id_from_folder_path(&norm(&renamed));

            let db = connection().expect("connection");
            let handle = create_sync_handle();
            let empty_ctx = ScanContext {
                existing_by_id: HashMap::new(),
                thumbnail_stats: HashMap::new(),
            };
            let scanned = scan_roots(
                std::slice::from_ref(&root),
                &empty_ctx,
                &handle,
                true,
                &ResourceFormatCategory::ALL,
            )
            .expect("scan");
            let plan = build_scan_replace_plan(&db, scanned, "")
                .await
                .expect("plan");
            assert_eq!(plan.migrated_count, 0);
            assert_eq!(plan.series_migrations.len(), 0);
            apply_scan_replace_plan(&db, &plan, "")
                .await
                .expect("apply");

            assert!(find_series_by_id(&old_series_id)
                .await
                .expect("old")
                .is_none());
            let series = find_series_by_id(&new_series_id)
                .await
                .expect("new")
                .expect("imported");
            assert_eq!(series.name, "SeriesNew");
            assert_eq!(series.serialization_status, "unknown");
            assert_eq!(series.total_count, None);
        });
    });
}

#[test]
fn unverified_folder_move_with_extra_comic_creates_default_series() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir").keep();
        let db_path = common::create_fixture_db(temp.as_path());
        let root = temp.as_path().join("library");
        let series_dir = root.join("SeriesOld");
        std::fs::create_dir_all(&series_dir).expect("mkdir");
        write_cbz_pages(&series_dir.join("01.cbz"), 1);
        write_cbz_pages(&series_dir.join("02.cbz"), 2);
        let comic_a = comic_id_from_path(&norm(&series_dir.join("01.cbz")));
        let comic_b = comic_id_from_path(&norm(&series_dir.join("02.cbz")));
        let old_series_id = series_id_from_folder_path(&norm(&series_dir));

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            sync_once(&root).await;
            seed_series_user_state(&old_series_id, &comic_a, &comic_b, true).await;

            let renamed = root.join("SeriesNew");
            std::fs::rename(&series_dir, &renamed).expect("rename");
            write_cbz_pages(&renamed.join("03.cbz"), 3);
            let new_series_id = series_id_from_folder_path(&norm(&renamed));

            sync_once(&root).await;

            let series = find_series_by_id(&new_series_id)
                .await
                .expect("new")
                .expect("exists");
            assert_ne!(series.name, "自定义系列名");
            assert!(!series.locks.name);
            assert_eq!(series.serialization_status, "unknown");
            assert_eq!(series.total_count, None);
            assert!(!series.locks.serialization_status);
            assert!(!series.locks.total_count);
            assert_eq!(series.items.len(), 3);
            assert!(series.items.iter().all(|item| !item.sort_order_locked));

            assert!(find_series_thumbnail_by_series_id(&new_series_id)
                .await
                .unwrap()
                .is_none());
        });
    });
}

#[test]
fn unverified_member_move_keeps_destination_state_without_source_order() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir").keep();
        let db_path = common::create_fixture_db(temp.as_path());
        let root = temp.as_path().join("library");
        let source = root.join("Source");
        let destination = root.join("Destination");
        std::fs::create_dir_all(&source).expect("source directory");
        std::fs::create_dir_all(&destination).expect("destination directory");
        write_cbz_pages(&source.join("01.cbz"), 1);
        write_cbz_pages(&destination.join("02.cbz"), 2);
        let source_comic = comic_id_from_path(&norm(&source.join("01.cbz")));
        let target_comic = comic_id_from_path(&norm(&destination.join("02.cbz")));
        let source_series = series_id_from_folder_path(&norm(&source));
        let target_series = series_id_from_folder_path(&norm(&destination));

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            sync_once(&root).await;
            update_series_item_sort_order(&source_series, &source_comic, 9.5)
                .await
                .expect("lock the only source member");
            update_series_item_sort_order(&target_series, &target_comic, 2.5)
                .await
                .expect("lock existing target member");
            update_series_user_meta(
                &target_series,
                UpdateSeriesUserMetaDto {
                    name: Some("Existing destination".to_string()),
                    serialization_status: Some("ended".to_string()),
                    total_count: Some(7),
                    clear_total_count: false,
                },
            )
            .await
            .expect("target metadata");

            let moved_path = destination.join("01.cbz");
            std::fs::rename(source.join("01.cbz"), &moved_path).expect("move last member");
            let moved_comic = comic_id_from_path(&norm(&moved_path));
            let db = connection().expect("connection");
            let scanned = scan_roots(
                std::slice::from_ref(&root),
                &ScanContext {
                    existing_by_id: HashMap::new(),
                    thumbnail_stats: HashMap::new(),
                },
                &create_sync_handle(),
                true,
                &ResourceFormatCategory::ALL,
            )
            .expect("scan after move");
            let plan = build_scan_replace_plan(&db, scanned, "")
                .await
                .expect("migration plan");
            assert_eq!(plan.migrated_count, 0);
            assert_eq!(plan.migrations.len(), 0);
            assert!(
                plan.series_migrations.is_empty(),
                "occupied target Series is not rekeyed"
            );
            let notifications = hentai_core::revision::notify_count();

            apply_scan_replace_plan(&db, &plan, "")
                .await
                .expect("apply migration");

            let target = find_series_by_id(&target_series)
                .await
                .expect("target lookup")
                .expect("existing target retained");
            assert_eq!(target.items.len(), 2);
            let moved = target
                .items
                .iter()
                .find(|item| item.comic_id == moved_comic)
                .unwrap();
            assert!(!moved.sort_order_locked);
            let kept = target
                .items
                .iter()
                .find(|item| item.comic_id == target_comic)
                .unwrap();
            assert!(kept.sort_order_locked);
            assert_eq!(target.name, "Existing destination");
            assert_eq!(target.serialization_status, "ended");
            assert_eq!(target.total_count, Some(7));
            assert!(
                target.locks.name && target.locks.serialization_status && target.locks.total_count
            );
            assert!(find_series_by_id(&source_series)
                .await
                .expect("source lookup")
                .is_none());
            assert!(find_comic_by_id(&source_comic)
                .await
                .expect("old Comic lookup")
                .is_none());
            assert!(find_comic_by_id(&moved_comic)
                .await
                .expect("moved Comic lookup")
                .is_some());
            assert_eq!(hentai_core::revision::notify_count(), notifications + 1);
        });
    });
}
