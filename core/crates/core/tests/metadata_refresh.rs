use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::sync::parser::{parse_file, parsed_to_comic};
use hentai_core::sync::plan::build_scan_replace_plan;
use hentai_core::sync::scanner::ScanItem;
use hentai_core::sync::writer::apply_scan_replace_plan;
use hentai_core::{
    comic_id_from_path, connection, find_comic_by_id, find_series_by_id, init_db_at_path,
    refresh_comic_metadata, refresh_series_metadata, series_id_from_folder_path,
    try_acquire_library_write_lock, HentaiErrorCode,
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
    let plan = build_scan_replace_plan(db, items).await.expect("plan");
    apply_scan_replace_plan(db, &plan).await.expect("upsert");
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
            let result = refresh_series_metadata(&series_id, |p| progress.push(p))
                .await
                .expect("refresh series");

            assert_eq!(result.succeeded, 2);
            assert_eq!(result.failed, 0);
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

            let result = refresh_series_metadata(&series_id, |_| {})
                .await
                .expect("refresh series");

            assert_eq!(result.succeeded, 1);
            assert_eq!(result.failed, 1);
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
            let err = refresh_series_metadata("missing", |_| {})
                .await
                .expect_err("busy");
            assert_eq!(err.code, HentaiErrorCode::Validation);
        });
    });
}
