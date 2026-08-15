use std::fs::File;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::sync::format_group::FormatGroup;
use hentai_core::sync::handle::create_sync_handle;
use hentai_core::{
    comic_id_from_path, connection, create_local_library, delete_library, fetch_comics_page,
    find_comic_by_id, get_current_library_id, get_reading_by_comic_id, init_db_at_path,
    library_id_from_root, list_libraries, record_reading, set_current_library_id, sync_library,
    update_library_format_groups, ComicFilterDto, PageRequestDto, ReadingHistoryDto, SyncScanMode,
};
use sea_orm::{ConnectionTrait, Database, Statement};
use tempfile::TempDir;
use zip::write::SimpleFileOptions;
use zip::ZipWriter;

static DB_INIT_LOCK: Mutex<()> = Mutex::new(());

fn with_global_db(test: impl FnOnce()) {
    let _guard = DB_INIT_LOCK
        .lock()
        .expect("global db tests must run serially");
    test();
}

fn fixture_sql() -> String {
    std::fs::read_to_string(
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/fixtures/drift_v2.sql"),
    )
    .expect("read drift_v2.sql")
}

fn create_fixture_db(dir: &Path) -> PathBuf {
    let db_path = dir.join("fixture.sqlite");
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        let conn = Database::connect(format!(
            "sqlite://{}?mode=rwc",
            db_path.to_string_lossy().replace('\\', "/")
        ))
        .await
        .expect("connect");
        for stmt in fixture_sql().split(';') {
            let sql = stmt.trim();
            if sql.is_empty() || sql.starts_with("--") {
                continue;
            }
            conn.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                sql.to_string(),
            ))
            .await
            .expect("execute sql");
        }
    });
    db_path
}

fn write_cbz(path: &Path) {
    let file = File::create(path).expect("create");
    let mut zip = ZipWriter::new(file);
    zip.start_file("01.jpg", SimpleFileOptions::default())
        .expect("start");
    zip.write_all(b"fake-jpeg").expect("write");
    zip.finish().expect("finish");
}

fn write_image_comic(dir: &Path) {
    std::fs::create_dir_all(dir).expect("mkdir comic");
    std::fs::write(dir.join("01.jpg"), b"fake-jpeg").expect("jpg");
}

#[test]
fn saved_paths_migrate_to_local_libraries_preserving_comic_ids() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let root_a = temp.path().join("lib_a");
        let root_b = temp.path().join("lib_b");
        std::fs::create_dir_all(&root_a).expect("mkdir a");
        std::fs::create_dir_all(&root_b).expect("mkdir b");
        let comic_a = root_a.join("comic_a");
        let comic_b = root_b.join("comic_b");
        write_image_comic(&comic_a);
        write_image_comic(&comic_b);

        let comic_a_id = comic_id_from_path(&comic_a.to_string_lossy());
        let comic_b_id = comic_id_from_path(&comic_b.to_string_lossy());
        let lib_a_id = library_id_from_root(&root_a.to_string_lossy());
        let lib_b_id = library_id_from_root(&root_b.to_string_lossy());

        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            let conn = Database::connect(format!(
                "sqlite://{}?mode=rwc",
                db_path.to_string_lossy().replace('\\', "/")
            ))
            .await
            .expect("connect");
            for (raw_path, comic_id, path) in [
                (
                    root_a.to_string_lossy().to_string(),
                    comic_a_id.clone(),
                    comic_a.to_string_lossy().to_string(),
                ),
                (
                    root_b.to_string_lossy().to_string(),
                    comic_b_id.clone(),
                    comic_b.to_string_lossy().to_string(),
                ),
            ] {
                conn.execute(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "INSERT OR IGNORE INTO saved_paths (raw_path, security_bookmark) VALUES (?, NULL)",
                    [sea_orm::Value::String(Some(Box::new(raw_path)))],
                ))
                .await
                .expect("insert path");
                // drift_v2 comics schema (pre-migration): title/content_rating/page_count on comics.
                conn.execute(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "INSERT INTO comics (comic_id, path, resource_type, title, content_rating, page_count) \
                     VALUES (?, ?, 'dir', 't', 'unknown', 1)",
                    [
                        sea_orm::Value::String(Some(Box::new(comic_id.clone()))),
                        sea_orm::Value::String(Some(Box::new(path))),
                    ],
                ))
                .await
                .expect("insert comic");
            }

            init_db_at_path(&db_path).await.expect("init_db migrates");

            let libraries = list_libraries().await.expect("list");
            assert_eq!(libraries.len(), 2);
            let ids: Vec<String> = libraries.iter().map(|l| l.library_id.clone()).collect();
            assert!(ids.contains(&lib_a_id));
            assert!(ids.contains(&lib_b_id));

            let a = find_comic_by_id(&comic_a_id)
                .await
                .expect("find a")
                .expect("comic a");
            let b = find_comic_by_id(&comic_b_id)
                .await
                .expect("find b")
                .expect("comic b");
            assert_eq!(a.comic_id, comic_a_id);
            assert_eq!(b.comic_id, comic_b_id);
            assert_eq!(a.library_id, lib_a_id);
            assert_eq!(b.library_id, lib_b_id);

            let current = get_current_library_id().await.expect("current");
            assert!(current.is_some());

            let db = connection().expect("db");
            let leftover = db
                .query_one(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT COUNT(*) FROM saved_paths".to_string(),
                ))
                .await
                .expect("count")
                .expect("row");
            assert_eq!(leftover.try_get_by_index::<i64>(0).unwrap_or(-1), 0);
        });
    });
}

#[test]
fn sync_current_library_does_not_remove_other_library_comics() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let root_a = temp.path().join("lib_a");
        let root_b = temp.path().join("lib_b");
        std::fs::create_dir_all(&root_a).expect("mkdir a");
        std::fs::create_dir_all(&root_b).expect("mkdir b");
        let comic_a = root_a.join("only_a");
        let comic_b = root_b.join("only_b");
        write_image_comic(&comic_a);
        write_image_comic(&comic_b);

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib_a = create_local_library(&root_a.to_string_lossy(), None)
                .await
                .expect("create a");
            let lib_b = create_local_library(&root_b.to_string_lossy(), None)
                .await
                .expect("create b");
            set_current_library_id(Some(&lib_a.library_id))
                .await
                .expect("set current a");

            let handle = create_sync_handle();
            // Sync all once to populate both.
            sync_library(handle, SyncScanMode::Full, true, None, vec![], |_| {})
                .await
                .expect("sync all");

            let id_a = comic_id_from_path(&comic_a.to_string_lossy());
            let id_b = comic_id_from_path(&comic_b.to_string_lossy());
            assert!(find_comic_by_id(&id_a).await.unwrap().is_some());
            assert!(find_comic_by_id(&id_b).await.unwrap().is_some());

            // Remove comic_a from disk, sync only current (A).
            std::fs::remove_dir_all(&comic_a).expect("rm a");
            set_current_library_id(Some(&lib_a.library_id))
                .await
                .expect("current a");
            let handle = create_sync_handle();
            sync_library(handle, SyncScanMode::Full, false, None, vec![], |_| {})
                .await
                .expect("sync current");

            assert!(find_comic_by_id(&id_a).await.unwrap().is_none());
            assert!(
                find_comic_by_id(&id_b).await.unwrap().is_some(),
                "library B comic must survive sync of A"
            );
            assert_eq!(lib_b.library_id, library_id_from_root(&root_b.to_string_lossy()));
        });
    });
}

#[test]
fn per_library_format_groups_only_affect_that_library_on_sync() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let root_a = temp.path().join("lib_a");
        let root_b = temp.path().join("lib_b");
        std::fs::create_dir_all(&root_a).expect("mkdir a");
        std::fs::create_dir_all(&root_b).expect("mkdir b");
        write_cbz(&root_a.join("a.cbz"));
        write_cbz(&root_b.join("b.cbz"));
        write_image_comic(&root_a.join("folder_a"));

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib_a = create_local_library(&root_a.to_string_lossy(), None)
                .await
                .expect("create a");
            let _lib_b = create_local_library(&root_b.to_string_lossy(), None)
                .await
                .expect("create b");

            let handle = create_sync_handle();
            sync_library(handle, SyncScanMode::Full, true, None, vec![], |_| {})
                .await
                .expect("sync all");

            let archive_a = comic_id_from_path(&root_a.join("a.cbz").to_string_lossy());
            let archive_b = comic_id_from_path(&root_b.join("b.cbz").to_string_lossy());
            assert!(find_comic_by_id(&archive_a).await.unwrap().is_some());
            assert!(find_comic_by_id(&archive_b).await.unwrap().is_some());

            update_library_format_groups(&lib_a.library_id, vec![FormatGroup::Folder])
                .await
                .expect("formats a");
            set_current_library_id(Some(&lib_a.library_id))
                .await
                .expect("current");
            let handle = create_sync_handle();
            sync_library(handle, SyncScanMode::Full, false, None, vec![], |_| {})
                .await
                .expect("sync a");

            assert!(find_comic_by_id(&archive_a).await.unwrap().is_none());
            assert!(
                find_comic_by_id(&archive_b).await.unwrap().is_some(),
                "B archive must remain when only A disables archive"
            );
        });
    });
}

#[test]
fn delete_library_clears_only_that_library_comics_and_series() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let root_a = temp.path().join("lib_a");
        let root_b = temp.path().join("lib_b");
        std::fs::create_dir_all(&root_a).expect("mkdir a");
        std::fs::create_dir_all(&root_b).expect("mkdir b");
        write_image_comic(&root_a.join("series_a").join("vol1"));
        write_image_comic(&root_b.join("series_b").join("vol1"));

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib_a = create_local_library(&root_a.to_string_lossy(), None)
                .await
                .expect("create a");
            let lib_b = create_local_library(&root_b.to_string_lossy(), None)
                .await
                .expect("create b");

            let handle = create_sync_handle();
            sync_library(handle, SyncScanMode::Full, true, None, vec![], |_| {})
                .await
                .expect("sync all");

            let id_a = comic_id_from_path(&root_a.join("series_a").join("vol1").to_string_lossy());
            let id_b = comic_id_from_path(&root_b.join("series_b").join("vol1").to_string_lossy());
            record_reading(&ReadingHistoryDto {
                comic_id: id_b.clone(),
                title: "keep".into(),
                last_read_time_ms: 100,
                page_index: Some(0),
            })
            .await
            .expect("history b");

            delete_library(&lib_a.library_id).await.expect("delete a");

            assert!(find_comic_by_id(&id_a).await.unwrap().is_none());
            assert!(find_comic_by_id(&id_b).await.unwrap().is_some());
            assert!(get_reading_by_comic_id(&id_b).await.unwrap().is_some());

            let remaining = list_libraries().await.expect("list");
            assert_eq!(remaining.len(), 1);
            assert_eq!(remaining[0].library_id, lib_b.library_id);
            assert_eq!(
                get_current_library_id().await.unwrap().as_deref(),
                Some(lib_b.library_id.as_str())
            );

            set_current_library_id(Some(&lib_b.library_id))
                .await
                .expect("current b");
            let page = fetch_comics_page(
                PageRequestDto {
                    page: 1,
                    page_size: 50,
                },
                ComicFilterDto::default(),
                Default::default(),
            )
            .await
            .expect("page");
            assert_eq!(page.total_count, 1);
            assert_eq!(page.items[0].comic_id, id_b);
        });
    });
}

#[test]
fn browse_defaults_to_current_library_scope() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let root_a = temp.path().join("lib_a");
        let root_b = temp.path().join("lib_b");
        std::fs::create_dir_all(&root_a).expect("mkdir a");
        std::fs::create_dir_all(&root_b).expect("mkdir b");
        write_image_comic(&root_a.join("a"));
        write_image_comic(&root_b.join("b"));

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib_a = create_local_library(&root_a.to_string_lossy(), None)
                .await
                .expect("a");
            let lib_b = create_local_library(&root_b.to_string_lossy(), None)
                .await
                .expect("b");
            let handle = create_sync_handle();
            sync_library(handle, SyncScanMode::Full, true, None, vec![], |_| {})
                .await
                .expect("sync");

            set_current_library_id(Some(&lib_a.library_id))
                .await
                .expect("current a");
            let page_a = fetch_comics_page(
                PageRequestDto {
                    page: 1,
                    page_size: 50,
                },
                ComicFilterDto::default(),
                Default::default(),
            )
            .await
            .expect("page a");
            assert_eq!(page_a.total_count, 1);
            assert!(page_a.items[0].path.contains("lib_a"));

            set_current_library_id(Some(&lib_b.library_id))
                .await
                .expect("current b");
            let page_b = fetch_comics_page(
                PageRequestDto {
                    page: 1,
                    page_size: 50,
                },
                ComicFilterDto::default(),
                Default::default(),
            )
            .await
            .expect("page b");
            assert_eq!(page_b.total_count, 1);
            assert!(page_b.items[0].path.contains("lib_b"));
        });
    });
}
