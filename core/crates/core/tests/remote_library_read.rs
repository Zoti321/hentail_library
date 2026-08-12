use std::io::{Cursor, Write};
use std::path::PathBuf;
use std::sync::Mutex;

use hentai_core::resource::{FakeResourceAccess, ResourceAccess};
use hentai_core::sync::refresh_comic_metadata_with;
use hentai_core::thumbnail::generate_thumbnail_jpeg_with;
use hentai_core::{
    close_reader, connection, create_remote_library, find_comic_by_id, init_db_at_path,
    load_page_bytes, load_page_list, open_reader_with, writeback_with_access, HentaiErrorCode,
};
use image::{ImageBuffer, Rgb};
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

fn create_fixture_db(dir: &std::path::Path) -> PathBuf {
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

fn solid_jpeg_bytes(r: u8, g: u8, b: u8) -> Vec<u8> {
    let img: ImageBuffer<Rgb<u8>, Vec<u8>> = ImageBuffer::from_pixel(24, 24, Rgb([r, g, b]));
    let mut buf = Cursor::new(Vec::new());
    img.write_to(&mut buf, image::ImageFormat::Jpeg)
        .expect("jpeg");
    buf.into_inner()
}

fn make_cbz_bytes(pages: &[&[u8]]) -> Vec<u8> {
    let mut bytes = Vec::new();
    {
        let mut zip = ZipWriter::new(Cursor::new(&mut bytes));
        let options = SimpleFileOptions::default();
        for (i, page) in pages.iter().enumerate() {
            zip.start_file(format!("{:02}.jpg", i + 1), options)
                .expect("start");
            zip.write_all(page).expect("write");
        }
        zip.finish().expect("finish");
    }
    bytes
}

#[test]
fn fake_remote_cbz_open_lists_and_reads_pages() {
    let jpeg = solid_jpeg_bytes(10, 20, 30);
    let cbz = make_cbz_bytes(&[jpeg.as_slice(), jpeg.as_slice()]);
    let location = "https://nas.example/dav/book.cbz";
    let mut fake = FakeResourceAccess::new();
    fake.insert_file(location, cbz);

    open_reader_with(&fake, "c1", location, "cbz").expect("open");
    let list = load_page_list("c1", location, "cbz").expect("list");
    assert_eq!(list.page_count, 2);
    let page0 = load_page_bytes("c1", location, "cbz", 0).expect("page0");
    assert!(!page0.is_empty());
    close_reader("c1");
}

#[test]
fn fake_unreachable_open_fails_clearly() {
    let mut fake = FakeResourceAccess::new();
    fake.insert_file("https://nas.example/dav/book.cbz", b"x");
    fake.set_unreachable("认证失败: 401 Unauthorized");
    let err = open_reader_with(&fake, "c-unreach", "https://nas.example/dav/book.cbz", "cbz")
        .expect_err("must fail");
    assert!(
        err.is_remote_access_failure()
            || err.code == HentaiErrorCode::ReaderNotFound
            || err.message.contains("401")
            || err.message.contains("认证")
            || err.message.contains("不可达")
    );
}

#[test]
fn writeback_updates_page_count_and_keeps_locked_title() {
    with_global_db(|| {
        let temp = TempDir::new().expect("temp");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("rt");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib = create_remote_library("https://nas.example/dav", "u", false)
                .await
                .expect("remote lib");

            let jpeg = solid_jpeg_bytes(1, 2, 3);
            let cbz = make_cbz_bytes(&[jpeg.as_slice(), jpeg.as_slice(), jpeg.as_slice()]);
            let location = "https://nas.example/dav/locked.cbz";
            let mut fake = FakeResourceAccess::new();
            fake.insert_file(location, cbz);

            let comic_id = hentai_core::comic_id_for_remote_location(location);
            let db = connection().expect("db");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at, library_id) \
                     VALUES ('{comic_id}', '{location}', 'cbz', 1, 1, 1, '{}')",
                    lib.library_id
                ),
            ))
            .await
            .expect("seed comic");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "INSERT INTO comic_meta (comic_id, title, content_rating, page_count, title_locked) \
                     VALUES ('{comic_id}', 'User Title', 'unknown', 1, 1)"
                ),
            ))
            .await
            .expect("seed meta");

            writeback_with_access(&fake, &comic_id, 3)
                .await
                .expect("writeback");
            let comic = find_comic_by_id(&comic_id).await.expect("find").expect("exists");
            assert_eq!(comic.page_count, 3);
            assert_eq!(comic.title, "User Title");
        });
    });
}

#[test]
fn fake_thumbnail_generates_from_remote_cbz() {
    let jpeg = solid_jpeg_bytes(200, 10, 10);
    let cbz = make_cbz_bytes(&[jpeg.as_slice()]);
    let location = "https://nas.example/dav/cover.cbz";
    let mut fake = FakeResourceAccess::new();
    fake.insert_file(location, cbz);

    let out = generate_thumbnail_jpeg_with(&fake, location, "cbz")
        .expect("thumb")
        .expect("some jpeg");
    assert!(out.len() > 32);
    assert_eq!(&out[0..2], &[0xFF, 0xD8]);
}

#[test]
fn refresh_with_fake_updates_page_count() {
    with_global_db(|| {
        let temp = TempDir::new().expect("temp");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("rt");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib = create_remote_library("https://nas.example/dav", "u", false)
                .await
                .expect("remote lib");

            let jpeg = solid_jpeg_bytes(9, 9, 9);
            let cbz = make_cbz_bytes(&[jpeg.as_slice(), jpeg.as_slice()]);
            let location = "https://nas.example/dav/refresh.cbz";
            let mut fake = FakeResourceAccess::new();
            fake.insert_file(location, cbz);

            let comic_id = hentai_core::comic_id_for_remote_location(location);
            let db = connection().expect("db");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at, library_id) \
                     VALUES ('{comic_id}', '{location}', 'cbz', 1, 1, 1, '{}')",
                    lib.library_id
                ),
            ))
            .await
            .expect("seed");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
                     VALUES ('{comic_id}', 'Refresh', 'unknown', 1)"
                ),
            ))
            .await
            .expect("meta");

            refresh_comic_metadata_with(&fake, &comic_id)
                .await
                .expect("refresh");
            let comic = find_comic_by_id(&comic_id).await.expect("find").expect("row");
            assert_eq!(comic.page_count, 2);
        });
    });
}

#[test]
fn fake_resource_access_is_dyn_compatible_for_read() {
    let access: &dyn ResourceAccess = &FakeResourceAccess::new();
    let _ = access;
}
