#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

mod common;

use std::path::Path;

use hentai_core::resource::{parse_directory, parsed_to_comic};
use hentai_core::sync::plan::build_scan_replace_plan;
use hentai_core::sync::scanner::ScanItem;
use hentai_core::sync::writer::apply_scan_replace_plan;
use hentai_core::{
    connection, create_local_library, create_sync_handle, find_comic_by_id, init_db_at_path,
    refresh_comic_metadata, refresh_library_metadata, refresh_series_metadata,
    series_id_from_folder_path, set_comic_meta_locks, update_comic_user_meta, HentaiErrorCode,
    SetComicMetaLocksDto, UpdateComicUserMetaDto,
};
use sea_orm::{ConnectionTrait, DatabaseConnection, Statement};

fn with_db(test: impl FnOnce(&tokio::runtime::Runtime, &Path, DatabaseConnection)) {
    common::with_global_db(|| {
        let root = tempfile::tempdir().unwrap().keep();
        let db_path = common::create_fixture_db(&root);
        let runtime = tokio::runtime::Runtime::new().unwrap();
        runtime.block_on(init_db_at_path(&db_path)).unwrap();
        test(&runtime, &root, connection().unwrap());
    });
}

fn image_directory(path: &Path) {
    std::fs::create_dir(path).unwrap();
    std::fs::write(path.join("001.jpg"), b"page-one").unwrap();
    std::fs::write(path.join("002.png"), b"page-two").unwrap();
}

async fn register(db: &DatabaseConnection, directories: &[&Path], library_id: &str) -> Vec<String> {
    let mut items = Vec::new();
    let mut ids = Vec::new();
    for directory in directories {
        let mut comic = parsed_to_comic(&parse_directory(directory).unwrap().unwrap());
        comic.library_id = library_id.to_string();
        ids.push(comic.comic_id.clone());
        items.push(ScanItem::from_resource(comic));
    }
    let plan = build_scan_replace_plan(db, items, library_id)
        .await
        .unwrap();
    apply_scan_replace_plan(db, &plan, library_id)
        .await
        .unwrap();
    ids
}

fn refresh_directory_metadata(locked_title: bool) {
    for name in ["Images", "Images.cbz", "Images.pdf"] {
        with_db(|runtime, root, db| {
            runtime.block_on(async {
                let directory = root.join(name);
                image_directory(&directory);
                let id = register(&db, &[&directory], "").await.remove(0);
                update_comic_user_meta(
                    &id,
                    UpdateComicUserMetaDto {
                        title: Some("User title".into()),
                        description: Some("User summary".into()),
                        authors: Some(vec!["User author".into()]),
                        languages: Some(vec!["ja".into()]),
                        ..Default::default()
                    },
                )
                .await
                .unwrap();
                if !locked_title {
                    set_comic_meta_locks(
                        &id,
                        SetComicMetaLocksDto {
                            title: Some(false),
                            ..Default::default()
                        },
                    )
                    .await
                    .unwrap();
                }
                std::fs::write(directory.join("003.webp"), b"page-three").unwrap();
                let notifications = hentai_core::revision::notify_count();
                refresh_comic_metadata(&id).await.unwrap();
                let current = find_comic_by_id(&id).await.unwrap().unwrap();
                assert_eq!(current.path, directory.to_string_lossy());
                assert_eq!(current.resource_type, "dir");
                assert_eq!(current.page_count, 3);
                assert_eq!(current.resource_size, 26);
                assert_eq!(
                    current.title,
                    if locked_title { "User title" } else { name }
                );
                assert_eq!(current.locks.title, locked_title);
                assert_eq!(current.description.as_deref(), Some("User summary"));
                assert_eq!(current.author_names(), ["User author"]);
                assert_eq!(current.languages, ["ja"]);
                assert!(
                    current.locks.description && current.locks.authors && current.locks.languages
                );
                assert_eq!(hentai_core::revision::notify_count(), notifications + 1);
            });
        });
    }
}

#[test]
fn directory_refresh_recomputes_physical_metadata_and_unlocked_title() {
    refresh_directory_metadata(false);
}

#[test]
fn directory_refresh_preserves_locked_title_and_user_metadata() {
    refresh_directory_metadata(true);
}

#[test]
fn directory_refresh_rejects_a_folder_that_no_longer_qualifies_without_writing() {
    for nested in [false, true] {
        with_db(|runtime, root, db| {
            runtime.block_on(async {
                let directory = root.join("Images");
                image_directory(&directory);
                let id = register(&db, &[&directory], "").await.remove(0);
                let before = find_comic_by_id(&id).await.unwrap().unwrap();
                if nested {
                    std::fs::create_dir(directory.join("nested")).unwrap();
                } else {
                    std::fs::write(directory.join("notes.txt"), b"notes").unwrap();
                }
                let notifications = hentai_core::revision::notify_count();
                let error = refresh_comic_metadata(&id).await.unwrap_err();
                assert_eq!(error.code, HentaiErrorCode::ReaderInvalidContent);
                let after = find_comic_by_id(&id).await.unwrap().unwrap();
                assert_eq!(after.page_count, before.page_count);
                assert_eq!(after.resource_size, before.resource_size);
                assert_eq!(after.title, before.title);
                assert_eq!(after.last_updated_at, before.last_updated_at);
                assert_eq!(hentai_core::revision::notify_count(), notifications);
            });
        });
    }
}

#[test]
fn series_and_library_refresh_include_image_directory_resources() {
    with_db(|runtime, root, db| {
        runtime.block_on(async {
        let library = create_local_library(&root.to_string_lossy(), None).await.unwrap();
        let series_folder = root.join("FolderSeries");
        std::fs::create_dir(&series_folder).unwrap();
        let first = series_folder.join("First");
        let second = series_folder.join("Second.cbz");
        image_directory(&first);
        image_directory(&second);
        let ids = register(&db, &[&first, &second], &library.library_id).await;
        let series_id = series_id_from_folder_path(&series_folder.to_string_lossy());
        for id in &ids {
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "UPDATE comic_meta SET title = 'Old title', title_locked = 0, page_count = 9 WHERE comic_id = ?",
                [id.clone().into()],
            )).await.unwrap();
        }
        let mut progress = Vec::new();
        let result = refresh_series_metadata(&series_id, &create_sync_handle(), |p| progress.push(p)).await.unwrap();
        assert_eq!((result.succeeded, result.failed), (2, 0));
        assert!(progress.iter().all(|p| p.total == 2));
        progress.clear();
        let result = refresh_library_metadata(&library.library_id, &create_sync_handle(), |p| progress.push(p)).await.unwrap();
        assert_eq!((result.succeeded, result.failed), (2, 0));
        assert!(progress.iter().all(|p| p.total == 2));
        for (id, name) in ids.iter().zip(["First", "Second.cbz"]) {
            let current = find_comic_by_id(id).await.unwrap().unwrap();
            assert_eq!(current.title, name);
            assert_eq!(current.resource_type, "dir");
            assert_eq!(current.page_count, 2);
        }
    });
    });
}
