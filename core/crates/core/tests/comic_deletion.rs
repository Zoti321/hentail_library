mod common;

use std::path::Path;

use hentai_core::{
    comic_id_from_path, create_local_library, create_remote_library, create_sync_handle,
    delete_comics_by_ids, find_comic_by_id, init_db_at_path, sync_library, SyncScanMode,
};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;
fn write_image_comic(dir: &Path) {
    std::fs::create_dir_all(dir).expect("mkdir comic");
    std::fs::write(dir.join("01.jpg"), b"fake-jpeg").expect("jpg");
}

fn write_cbz(path: &Path) {
    let file = std::fs::File::create(path).expect("create cbz");
    let mut zip = zip::ZipWriter::new(file);
    let options =
        zip::write::SimpleFileOptions::default().compression_method(zip::CompressionMethod::Stored);
    zip.start_file("001.jpg", options).expect("start");
    use std::io::Write as _;
    zip.write_all(b"page").expect("write");
    zip.finish().expect("finish");
}

async fn insert_remote_comic(comic_id: &str, path: &str, library_id: &str) {
    let db = hentai_core::connection().expect("connection");
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at, library_id) \
         VALUES (?, ?, 'cbz', 4, 1, 1, ?)",
        [
            sea_orm::Value::String(Some(Box::new(comic_id.to_string()))),
            sea_orm::Value::String(Some(Box::new(path.to_string()))),
            sea_orm::Value::String(Some(Box::new(library_id.to_string()))),
        ],
    ))
    .await
    .expect("insert comic");
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comic_meta (comic_id, title, title_sort_key, content_rating, page_count, description, published_at, \
         title_locked, description_locked, published_at_locked, content_rating_locked, authors_locked, tags_locked, \
         languages, languages_locked, parodies_locked, characters_locked) \
         VALUES (?, 'Remote Comic', 'remote comic', 'unknown', 1, NULL, NULL, 0, 0, 0, 0, 0, 0, '[]', 0, 0, 0)",
        [sea_orm::Value::String(Some(Box::new(comic_id.to_string())))],
    ))
    .await
    .expect("insert meta");
}

#[test]
fn local_file_deletion_removes_disk_resource_and_db_row() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let root = temp.path().join("lib");
        std::fs::create_dir_all(&root).expect("mkdir");
        let comic_path = root.join("vol1.cbz");
        write_cbz(&comic_path);
        let comic_id = comic_id_from_path(&comic_path.to_string_lossy());

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let library = create_local_library(&root.to_string_lossy(), Some("Lib"))
                .await
                .expect("create lib");
            let handle = create_sync_handle();
            sync_library(
                handle,
                SyncScanMode::Full,
                false,
                Some(library.library_id.as_str()),
                vec![],
                |_| {},
            )
            .await
            .expect("sync");

            delete_comics_by_ids(vec![comic_id.clone()])
                .await
                .expect("delete");

            assert!(
                !comic_path.exists(),
                "local archive resource should be deleted from disk"
            );
            assert!(find_comic_by_id(&comic_id).await.expect("find").is_none());
        });
    });
}

#[test]
fn local_dir_deletion_removes_directory_resource() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let root = temp.path().join("lib");
        std::fs::create_dir_all(&root).expect("mkdir");
        let comic_dir = root.join("folder_comic");
        write_image_comic(&comic_dir);
        let comic_id = comic_id_from_path(&comic_dir.to_string_lossy());

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let library = create_local_library(&root.to_string_lossy(), Some("Lib"))
                .await
                .expect("create lib");
            let handle = create_sync_handle();
            sync_library(
                handle,
                SyncScanMode::Full,
                false,
                Some(library.library_id.as_str()),
                vec![],
                |_| {},
            )
            .await
            .expect("sync");

            delete_comics_by_ids(vec![comic_id.clone()])
                .await
                .expect("delete");

            assert!(
                !comic_dir.exists(),
                "dir resource should be deleted as a whole folder"
            );
            assert!(find_comic_by_id(&comic_id).await.expect("find").is_none());
        });
    });
}

#[test]
fn missing_local_resource_still_allows_library_removal() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let root = temp.path().join("lib");
        std::fs::create_dir_all(&root).expect("mkdir");
        let comic_path = root.join("vol1.cbz");
        write_cbz(&comic_path);
        let comic_id = comic_id_from_path(&comic_path.to_string_lossy());

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let library = create_local_library(&root.to_string_lossy(), Some("Lib"))
                .await
                .expect("create lib");
            let handle = create_sync_handle();
            sync_library(
                handle,
                SyncScanMode::Full,
                false,
                Some(library.library_id.as_str()),
                vec![],
                |_| {},
            )
            .await
            .expect("sync");
            std::fs::remove_file(&comic_path).expect("remove manually");

            delete_comics_by_ids(vec![comic_id.clone()])
                .await
                .expect("delete");

            assert!(find_comic_by_id(&comic_id).await.expect("find").is_none());
        });
    });
}

#[test]
fn rejects_local_resource_outside_library_root() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let root = temp.path().join("lib");
        let outside = temp.path().join("outside.cbz");
        std::fs::create_dir_all(&root).expect("mkdir");
        write_cbz(&outside);
        let comic_id = comic_id_from_path(&outside.to_string_lossy());

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let library = create_local_library(&root.to_string_lossy(), Some("Lib"))
                .await
                .expect("create lib");
            insert_remote_comic(&comic_id, &outside.to_string_lossy(), &library.library_id).await;
            let db = hentai_core::connection().expect("connection");
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "UPDATE libraries SET kind = 'local' WHERE library_id = ?",
                [sea_orm::Value::String(Some(Box::new(
                    library.library_id.clone(),
                )))],
            ))
            .await
            .expect("force local");

            let err = delete_comics_by_ids(vec![comic_id.clone()])
                .await
                .expect_err("outside-root delete should fail");
            assert!(err.message.contains("不在所属 Library root 下"));
            assert!(outside.exists(), "outside file must not be deleted");
            assert!(find_comic_by_id(&comic_id).await.expect("find").is_some());
        });
    });
}

#[test]
fn remote_deletion_only_clears_library_row() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let fake_remote_path = "https://example.com/library/vol1.cbz";
        let comic_id = comic_id_from_path(fake_remote_path);

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let library =
                create_remote_library("https://example.com/library", "user", false, Some("Remote"))
                    .await
                    .expect("create remote");
            insert_remote_comic(&comic_id, fake_remote_path, &library.library_id).await;

            delete_comics_by_ids(vec![comic_id.clone()])
                .await
                .expect("delete remote");

            assert!(find_comic_by_id(&comic_id).await.expect("find").is_none());
        });
    });
}
