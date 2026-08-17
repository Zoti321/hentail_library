use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::resource::{parse_file, parsed_to_comic};
use hentai_core::sync::plan::build_scan_replace_plan;
use hentai_core::sync::scanner::ScanItem;
use hentai_core::sync::writer::apply_scan_replace_plan;
use hentai_core::{
    cancel_sync, comic_id_from_path, connection, create_local_library, create_remote_library,
    create_sync_handle, find_comic_by_id, find_series_by_id, init_db_at_path,
    refresh_comic_metadata, refresh_library_metadata, refresh_series_metadata,
    series_id_from_folder_path, try_acquire_library_write_lock, HentaiErrorCode,
};
use sea_orm::{ConnectionTrait, Database, DatabaseConnection, Statement};
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
    let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    fs::read_to_string(manifest_dir.join("../../tests/fixtures/drift_v2.sql"))
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

fn create_cbz_with_title(path: &Path, title: &str) {
    let file = File::create(path).expect("create cbz");
    let mut zip = ZipWriter::new(file);
    let options = SimpleFileOptions::default();
    let comic_info = format!(
        r#"<?xml version="1.0"?>
<ComicInfo>
  <Title>{title}</Title>
</ComicInfo>"#
    );
    zip.start_file("ComicInfo.xml", options).expect("comicinfo");
    zip.write_all(comic_info.as_bytes()).expect("write comicinfo");
    zip.start_file("01.jpg", options).expect("page");
    zip.write_all(b"fake-jpeg").expect("write page");
    zip.finish().expect("finish");
}

async fn upsert_paths(db: &DatabaseConnection, paths: &[&Path]) {
    let mut items = Vec::new();
    for path in paths {
        let parsed = parse_file(path).expect("parse").expect("resource");
        let comic = parsed_to_comic(&parsed);
        items.push(ScanItem {
            path: parsed.path.clone(),
            resource_type: parsed.resource_type.clone(),
            comic,
        });
    }
    let plan = build_scan_replace_plan(db, items, "").await.expect("plan");
    apply_scan_replace_plan(db, &plan, "").await.expect("upsert");
}

async fn upsert_path(db: &DatabaseConnection, path: &Path) {
    upsert_paths(db, &[path]).await;
}

#[test]
fn refresh_comic_metadata_overwrites_unlocked_title_from_disk() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");

            let cbz = temp.path().join("book.cbz");
            create_cbz_with_title(&cbz, "FromDisk");
            upsert_path(&db, &cbz).await;

            let comic_id = comic_id_from_path(&cbz.to_string_lossy());
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "UPDATE comic_meta SET title='OldTitle', title_locked=0 WHERE comic_id='{comic_id}'"
                ),
            ))
            .await
            .expect("set old title");

            refresh_comic_metadata(&comic_id)
                .await
                .expect("refresh");

            let comic = find_comic_by_id(&comic_id)
                .await
                .expect("find")
                .expect("exists");
            assert_eq!(comic.title, "FromDisk");
        });
    });
}

#[test]
fn refresh_comic_metadata_preserves_locked_title() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");

            let cbz = temp.path().join("book.cbz");
            create_cbz_with_title(&cbz, "FromDisk");
            upsert_path(&db, &cbz).await;

            let comic_id = comic_id_from_path(&cbz.to_string_lossy());
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "UPDATE comic_meta SET title='LockedTitle', title_locked=1 WHERE comic_id='{comic_id}'"
                ),
            ))
            .await
            .expect("lock title");

            refresh_comic_metadata(&comic_id)
                .await
                .expect("refresh");

            let comic = find_comic_by_id(&comic_id)
                .await
                .expect("find")
                .expect("exists");
            assert_eq!(comic.title, "LockedTitle");
            assert!(comic.locks.title);
        });
    });
}

#[test]
fn refresh_comic_metadata_fails_when_file_missing_without_changing_db() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");

            let cbz = temp.path().join("book.cbz");
            create_cbz_with_title(&cbz, "FromDisk");
            upsert_path(&db, &cbz).await;

            let comic_id = comic_id_from_path(&cbz.to_string_lossy());
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "UPDATE comic_meta SET title='OldTitle', title_locked=0 WHERE comic_id='{comic_id}'"
                ),
            ))
            .await
            .expect("set old title");
            fs::remove_file(&cbz).expect("remove file");

            let err = refresh_comic_metadata(&comic_id)
                .await
                .expect_err("missing file");
            assert_eq!(err.code, HentaiErrorCode::ReaderNotFound);

            let comic = find_comic_by_id(&comic_id)
                .await
                .expect("find")
                .expect("exists");
            assert_eq!(comic.title, "OldTitle");
        });
    });
}

#[test]
fn refresh_comic_metadata_rejects_when_library_write_lock_held() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");

            let cbz = temp.path().join("book.cbz");
            create_cbz_with_title(&cbz, "FromDisk");
            upsert_path(&db, &cbz).await;
            let comic_id = comic_id_from_path(&cbz.to_string_lossy());

            let _guard = try_acquire_library_write_lock().expect("hold lock");
            let err = refresh_comic_metadata(&comic_id)
                .await
                .expect_err("busy");
            assert_eq!(err.code, HentaiErrorCode::Validation);
        });
    });
}

#[test]
fn refresh_series_metadata_refreshes_members_and_unlocked_name() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");

            let folder = temp.path().join("FolderSeries");
            fs::create_dir_all(&folder).expect("mkdir");
            let a = folder.join("a.cbz");
            let b = folder.join("b.cbz");
            create_cbz_with_title(&a, "DiskA");
            create_cbz_with_title(&b, "DiskB");
            upsert_paths(&db, &[&a, &b]).await;

            let series_id = series_id_from_folder_path(&folder.to_string_lossy());
            let id_a = comic_id_from_path(&a.to_string_lossy());
            let id_b = comic_id_from_path(&b.to_string_lossy());
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "UPDATE comic_meta SET title='OldA', title_locked=0 WHERE comic_id='{id_a}'"
                ),
            ))
            .await
            .expect("seed a");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "UPDATE comic_meta SET title='OldB', title_locked=0 WHERE comic_id='{id_b}'"
                ),
            ))
            .await
            .expect("seed b");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "UPDATE series SET name='CustomName', name_locked=0 WHERE series_id='{series_id}'"
                ),
            ))
            .await
            .expect("seed series name");

            let mut progress = Vec::new();
            let handle = create_sync_handle();
            let result = refresh_series_metadata(&series_id, &handle, |p| progress.push(p))
                .await
                .expect("refresh series");

            assert_eq!(result.succeeded, 2);
            assert_eq!(result.failed, 0);
            assert!(!result.cancelled);
            assert!(progress.iter().any(|p| p.total == 2 && p.current == 2));
            assert_eq!(
                find_comic_by_id(&id_a).await.expect("a").expect("exists").title,
                "DiskA"
            );
            assert_eq!(
                find_comic_by_id(&id_b).await.expect("b").expect("exists").title,
                "DiskB"
            );
            let series = find_series_by_id(&series_id)
                .await
                .expect("series")
                .expect("exists");
            assert_eq!(series.name, "FolderSeries");
        });
    });
}

#[test]
fn refresh_series_metadata_preserves_locked_name_and_continues_after_member_failure() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");

            let folder = temp.path().join("LockedNameSeries");
            fs::create_dir_all(&folder).expect("mkdir");
            let a = folder.join("a.cbz");
            let b = folder.join("b.cbz");
            create_cbz_with_title(&a, "DiskA");
            create_cbz_with_title(&b, "DiskB");
            upsert_paths(&db, &[&a, &b]).await;

            let series_id = series_id_from_folder_path(&folder.to_string_lossy());
            let id_a = comic_id_from_path(&a.to_string_lossy());
            let id_b = comic_id_from_path(&b.to_string_lossy());
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "UPDATE comic_meta SET title='OldA', title_locked=0 WHERE comic_id='{id_a}'"
                ),
            ))
            .await
            .expect("seed a");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "UPDATE comic_meta SET title='OldB', title_locked=0 WHERE comic_id='{id_b}'"
                ),
            ))
            .await
            .expect("seed b");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "UPDATE series SET name='KeepMe', name_locked=1 WHERE series_id='{series_id}'"
                ),
            ))
            .await
            .expect("seed series name");
            fs::remove_file(&a).expect("remove a");

            let handle = create_sync_handle();
            let result = refresh_series_metadata(&series_id, &handle, |_| {})
                .await
                .expect("refresh series");

            assert_eq!(result.succeeded, 1);
            assert_eq!(result.failed, 1);
            assert!(!result.cancelled);
            assert_eq!(
                find_comic_by_id(&id_a).await.expect("a").expect("exists").title,
                "OldA"
            );
            assert_eq!(
                find_comic_by_id(&id_b).await.expect("b").expect("exists").title,
                "DiskB"
            );
            let series = find_series_by_id(&series_id)
                .await
                .expect("series")
                .expect("exists");
            assert_eq!(series.name, "KeepMe");
            assert!(series.locks.name);
        });
    });
}

#[test]
fn refresh_series_metadata_rejects_when_library_write_lock_held() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let _guard = try_acquire_library_write_lock().expect("hold lock");
            let handle = create_sync_handle();
            let err = refresh_series_metadata("missing", &handle, |_| {})
                .await
                .expect_err("busy");
            assert_eq!(err.code, HentaiErrorCode::Validation);
        });
    });
}

#[test]
fn refresh_library_metadata_refreshes_comics_and_unlocked_series_name() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let root = temp.path().join("lib_root");
        fs::create_dir_all(&root).expect("mkdir root");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            let library = create_local_library(root.to_string_lossy().as_ref(), Some("Lib"))
                .await
                .expect("create library");
            let library_id = library.library_id.clone();

            let folder = root.join("FolderSeries");
            fs::create_dir_all(&folder).expect("mkdir");
            let a = folder.join("a.cbz");
            let b = folder.join("b.cbz");
            create_cbz_with_title(&a, "DiskA");
            create_cbz_with_title(&b, "DiskB");
            upsert_paths(&db, &[&a, &b]).await;

            let series_id = series_id_from_folder_path(&folder.to_string_lossy());
            let id_a = comic_id_from_path(&a.to_string_lossy());
            let id_b = comic_id_from_path(&b.to_string_lossy());
            for id in [&id_a, &id_b] {
                db.execute(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    format!("UPDATE comics SET library_id='{library_id}' WHERE comic_id='{id}'"),
                ))
                .await
                .expect("assign comic library");
            }
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "UPDATE series SET library_id='{library_id}', name='CustomName', name_locked=0 WHERE series_id='{series_id}'"
                ),
            ))
            .await
            .expect("assign series");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "UPDATE comic_meta SET title='OldA', title_locked=0 WHERE comic_id='{id_a}'"
                ),
            ))
            .await
            .expect("seed a");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "UPDATE comic_meta SET title='OldB', title_locked=0 WHERE comic_id='{id_b}'"
                ),
            ))
            .await
            .expect("seed b");

            let handle = create_sync_handle();
            let result = refresh_library_metadata(&library_id, &handle, |_| {})
                .await
                .expect("refresh library");

            assert_eq!(result.succeeded, 2);
            assert_eq!(result.failed, 0);
            assert!(!result.cancelled);
            assert!(!result.skipped);
            assert_eq!(
                find_comic_by_id(&id_a).await.expect("a").expect("exists").title,
                "DiskA"
            );
            assert_eq!(
                find_series_by_id(&series_id)
                    .await
                    .expect("series")
                    .expect("exists")
                    .name,
                "FolderSeries"
            );
        });
    });
}

#[test]
fn refresh_library_metadata_stops_on_cancel_and_keeps_partial_writes() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let root = temp.path().join("lib_cancel");
        fs::create_dir_all(&root).expect("mkdir root");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            let library = create_local_library(root.to_string_lossy().as_ref(), Some("Lib"))
                .await
                .expect("create library");
            let library_id = library.library_id.clone();

            let a = root.join("a.cbz");
            let b = root.join("b.cbz");
            create_cbz_with_title(&a, "DiskA");
            create_cbz_with_title(&b, "DiskB");
            upsert_paths(&db, &[&a, &b]).await;
            let id_a = comic_id_from_path(&a.to_string_lossy());
            let id_b = comic_id_from_path(&b.to_string_lossy());
            for id in [&id_a, &id_b] {
                db.execute(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    format!("UPDATE comics SET library_id='{library_id}' WHERE comic_id='{id}'"),
                ))
                .await
                .expect("assign");
                db.execute(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    format!(
                        "UPDATE comic_meta SET title='Old', title_locked=0 WHERE comic_id='{id}'"
                    ),
                ))
                .await
                .expect("seed");
            }

            let handle = create_sync_handle();
            let cancel_handle = handle.clone();
            let result = refresh_library_metadata(&library_id, &handle, |_| {
                cancel_sync(&cancel_handle);
            })
            .await
            .expect("refresh library");

            assert!(result.cancelled);
            assert_eq!(result.succeeded + result.failed, 1);
            let titles = [
                find_comic_by_id(&id_a).await.expect("a").expect("exists").title,
                find_comic_by_id(&id_b).await.expect("b").expect("exists").title,
            ];
            assert!(
                titles.iter().filter(|t| t.as_str() == "Old").count() == 1,
                "exactly one comic should remain unrefreshed, got {titles:?}"
            );
        });
    });
}

#[test]
fn refresh_library_metadata_scopes_to_target_library_only() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let root_a = temp.path().join("lib_a");
        let root_b = temp.path().join("lib_b");
        fs::create_dir_all(&root_a).expect("mkdir a");
        fs::create_dir_all(&root_b).expect("mkdir b");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            let lib_a = create_local_library(root_a.to_string_lossy().as_ref(), Some("A"))
                .await
                .expect("lib a");
            let lib_b = create_local_library(root_b.to_string_lossy().as_ref(), Some("B"))
                .await
                .expect("lib b");

            let path_a = root_a.join("a.cbz");
            let path_b = root_b.join("b.cbz");
            create_cbz_with_title(&path_a, "DiskA");
            create_cbz_with_title(&path_b, "DiskB");
            upsert_paths(&db, &[&path_a, &path_b]).await;
            let id_a = comic_id_from_path(&path_a.to_string_lossy());
            let id_b = comic_id_from_path(&path_b.to_string_lossy());
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "UPDATE comics SET library_id='{}' WHERE comic_id='{id_a}'",
                    lib_a.library_id
                ),
            ))
            .await
            .expect("assign a");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "UPDATE comics SET library_id='{}' WHERE comic_id='{id_b}'",
                    lib_b.library_id
                ),
            ))
            .await
            .expect("assign b");
            for (id, title) in [(&id_a, "OldA"), (&id_b, "OldB")] {
                db.execute(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    format!(
                        "UPDATE comic_meta SET title='{title}', title_locked=0 WHERE comic_id='{id}'"
                    ),
                ))
                .await
                .expect("seed");
            }

            let handle = create_sync_handle();
            let result = refresh_library_metadata(&lib_a.library_id, &handle, |_| {})
                .await
                .expect("refresh a");
            assert_eq!(result.succeeded, 1);
            assert_eq!(
                find_comic_by_id(&id_a).await.expect("a").expect("exists").title,
                "DiskA"
            );
            assert_eq!(
                find_comic_by_id(&id_b).await.expect("b").expect("exists").title,
                "OldB"
            );
        });
    });
}

#[test]
fn refresh_library_metadata_skips_remote_without_credentials() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let library = create_remote_library("https://nas.example/dav", "u", false, None)
                .await
                .expect("remote library");
            let handle = create_sync_handle();
            let result = refresh_library_metadata(&library.library_id, &handle, |_| {})
                .await
                .expect("skip");
            assert!(result.skipped);
            assert_eq!(result.succeeded, 0);
            assert_eq!(result.failed, 0);
            assert!(!result.cancelled);
            let message = result.skip_message.expect("skip message");
            assert!(message.contains("缺少凭证"), "{message}");
        });
    });
}

#[test]
fn refresh_library_metadata_rejects_when_library_write_lock_held() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let _guard = try_acquire_library_write_lock().expect("hold lock");
            let handle = create_sync_handle();
            let err = refresh_library_metadata("missing", &handle, |_| {})
                .await
                .expect_err("busy");
            assert_eq!(err.code, HentaiErrorCode::Validation);
        });
    });
}

#[test]
fn refresh_library_metadata_continues_after_comic_failure() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let root = temp.path().join("lib_partial");
        fs::create_dir_all(&root).expect("mkdir root");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            let library = create_local_library(root.to_string_lossy().as_ref(), Some("Lib"))
                .await
                .expect("create library");
            let library_id = library.library_id.clone();

            let a = root.join("a.cbz");
            let b = root.join("b.cbz");
            create_cbz_with_title(&a, "DiskA");
            create_cbz_with_title(&b, "DiskB");
            upsert_paths(&db, &[&a, &b]).await;
            let id_a = comic_id_from_path(&a.to_string_lossy());
            let id_b = comic_id_from_path(&b.to_string_lossy());
            for id in [&id_a, &id_b] {
                db.execute(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    format!("UPDATE comics SET library_id='{library_id}' WHERE comic_id='{id}'"),
                ))
                .await
                .expect("assign");
                db.execute(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    format!(
                        "UPDATE comic_meta SET title='Old', title_locked=0 WHERE comic_id='{id}'"
                    ),
                ))
                .await
                .expect("seed");
            }
            fs::remove_file(&a).expect("remove a");

            let handle = create_sync_handle();
            let result = refresh_library_metadata(&library_id, &handle, |_| {})
                .await
                .expect("refresh library");
            assert_eq!(result.succeeded, 1);
            assert_eq!(result.failed, 1);
            assert!(!result.cancelled);
            assert_eq!(
                find_comic_by_id(&id_a).await.expect("a").expect("exists").title,
                "Old"
            );
            assert_eq!(
                find_comic_by_id(&id_b).await.expect("b").expect("exists").title,
                "DiskB"
            );
        });
    });
}

#[test]
fn refresh_series_metadata_stops_on_cancel_and_keeps_partial_writes() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");

            let folder = temp.path().join("CancelSeries");
            fs::create_dir_all(&folder).expect("mkdir");
            let a = folder.join("a.cbz");
            let b = folder.join("b.cbz");
            create_cbz_with_title(&a, "DiskA");
            create_cbz_with_title(&b, "DiskB");
            upsert_paths(&db, &[&a, &b]).await;
            let series_id = series_id_from_folder_path(&folder.to_string_lossy());
            let id_a = comic_id_from_path(&a.to_string_lossy());
            let id_b = comic_id_from_path(&b.to_string_lossy());
            for id in [&id_a, &id_b] {
                db.execute(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    format!(
                        "UPDATE comic_meta SET title='Old', title_locked=0 WHERE comic_id='{id}'"
                    ),
                ))
                .await
                .expect("seed");
            }
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "UPDATE series SET name='CustomName', name_locked=0 WHERE series_id='{series_id}'"
                ),
            ))
            .await
            .expect("seed series name");

            let handle = create_sync_handle();
            let cancel_handle = handle.clone();
            let result = refresh_series_metadata(&series_id, &handle, |_| {
                cancel_sync(&cancel_handle);
            })
            .await
            .expect("refresh series");

            assert!(result.cancelled);
            assert_eq!(result.succeeded + result.failed, 1);
            let series = find_series_by_id(&series_id)
                .await
                .expect("series")
                .expect("exists");
            assert_eq!(series.name, "CustomName");
        });
    });
}

