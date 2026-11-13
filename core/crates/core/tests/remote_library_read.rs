use hentai_core::ReaderSessionRead;
mod common;

use std::io::{Cursor, Write};

use hentai_core::resource::{FakeResourceAccess, ResourceAccess};
use hentai_core::sync::refresh_comic_metadata_with;
use hentai_core::thumbnail::generate_thumbnail_jpeg_with;
use hentai_core::{
    close_reader, connection, create_remote_library, find_comic_by_id, init_db_at_path,
    load_page_bytes, load_page_list, open_reader_with, writeback_with_access, HentaiErrorCode,
};
use image::{ImageBuffer, Rgb};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;
use zip::write::SimpleFileOptions;
use zip::ZipWriter;

fn solid_jpeg_bytes(r: u8, g: u8, b: u8) -> Vec<u8> {
    let img: ImageBuffer<Rgb<u8>, Vec<u8>> = ImageBuffer::from_pixel(24, 24, Rgb([r, g, b]));
    let mut buf = Cursor::new(Vec::new());
    img.write_to(&mut buf, image::ImageFormat::Jpeg)
        .expect("jpeg");
    buf.into_inner()
}

fn make_cbz_bytes(pages: &[&[u8]]) -> Vec<u8> {
    make_cbz_with_metadata(pages, None)
}

fn make_cbz_with_metadata(pages: &[&[u8]], comic_info: Option<&str>) -> Vec<u8> {
    let mut bytes = Vec::new();
    {
        let mut zip = ZipWriter::new(Cursor::new(&mut bytes));
        let options = SimpleFileOptions::default();
        for (i, page) in pages.iter().enumerate() {
            zip.start_file(format!("{:02}.jpg", i + 1), options)
                .expect("start");
            zip.write_all(page).expect("write");
        }
        if let Some(xml) = comic_info {
            zip.start_file("ComicInfo.xml", options)
                .expect("comic info");
            zip.write_all(xml.as_bytes()).expect("metadata");
        }
        zip.finish().expect("finish");
    }
    bytes
}

#[test]
fn writeback_rolls_back_the_complete_comic_write_set_on_junction_failure() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("temp").keep();
        let db_path = common::create_fixture_db(temp.as_path());
        let runtime = tokio::runtime::Runtime::new().expect("rt");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let location = "https://nas.example/dav/atomic.cbz";
            let comic_id = hentai_core::comic_id_for_remote_location(location);
            let db = connection().expect("db");
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) VALUES (?, ?, 'cbz', 1, 1, 1)",
                [comic_id.clone().into(), location.into()],
            )).await.expect("seed comic");
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) VALUES (?, 'Old title', 'safe', 1)",
                [comic_id.clone().into()],
            )).await.expect("seed metadata");
            hentai_core::update_comic_user_meta(&comic_id, hentai_core::UpdateComicUserMetaDto {
                description: Some("Old description".into()),
                published_at: Some(0),
                authors: Some(vec!["Old author".into()]),
                tags: Some(vec!["Old tag".into()]),
                languages: Some(vec!["Japanese".into()]),
                parodies: Some(vec!["Old parody".into()]),
                characters: Some(vec!["Old character".into()]),
                ..Default::default()
            }).await.expect("seed all facets");
            hentai_core::set_comic_meta_locks(&comic_id, hentai_core::SetComicMetaLocksDto {
                description: Some(false),
                published_at: Some(false),
                authors: Some(false),
                ..Default::default()
            }).await.expect("unlock scanned fields");
            let before = find_comic_by_id(&comic_id).await.expect("find").expect("comic");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "CREATE TRIGGER fail_writeback_character BEFORE INSERT ON comic_characters BEGIN SELECT RAISE(ABORT, 'writeback character blocked'); END".to_string(),
            )).await.expect("inject final facet failure");
            let jpeg = solid_jpeg_bytes(1, 2, 3);
            let cbz = make_cbz_with_metadata(
                &[jpeg.as_slice(), jpeg.as_slice(), jpeg.as_slice()],
                Some("<ComicInfo><Title>New title</Title><Writer>New author</Writer><Summary>New description</Summary><Year>2026</Year><Month>1</Month><Day>2</Day></ComicInfo>"),
            );
            let mut fake = FakeResourceAccess::new();
            fake.insert_file(location, cbz);
            open_reader_with(&fake, &comic_id, location, "cbz").unwrap();
            let read = ReaderSessionRead::capture(&comic_id).unwrap();
            let notifications = hentai_core::revision::notify_count();

            let error = writeback_with_access(&fake, &read, 3).await.expect_err("final facet insert fails");

            assert!(error.message.contains("writeback character blocked"), "{error:?}");
            let after = find_comic_by_id(&comic_id).await.expect("find after rollback").expect("comic retained");
            assert_eq!(after.page_count, before.page_count);
            assert_eq!(after.title, before.title);
            assert_eq!(after.description, before.description);
            assert_eq!(after.published_at, before.published_at);
            assert_eq!(after.resource_size, before.resource_size);
            assert_eq!(after.last_updated_at, before.last_updated_at);
            assert_eq!(after.authors, before.authors);
            assert_eq!(after.tags, before.tags);
            assert_eq!(after.languages, before.languages);
            assert_eq!(after.parodies, before.parodies);
            assert_eq!(after.characters, before.characters);
            assert_eq!(after.locks, before.locks);
            assert_eq!(hentai_core::revision::notify_count(), notifications);
            assert!(!hentai_core::list_all_authors().await.expect("authors").iter().any(|author| author.name == "New author"));
            close_reader(&comic_id);
        });
    });
}

#[test]
fn fake_remote_cbz_open_lists_and_reads_pages() {
    let jpeg = solid_jpeg_bytes(10, 20, 30);
    let cbz = make_cbz_bytes(&[jpeg.as_slice(), jpeg.as_slice()]);
    let location = "https://nas.example/dav/book.cbz";
    let mut fake = FakeResourceAccess::new();
    fake.insert_file(location, cbz);

    open_reader_with(&fake, "c1", location, "cbz").expect("open");
    let list =
        load_page_list(&ReaderSessionRead::capture("c1").expect("capture session")).expect("list");
    assert_eq!(list.page_count, 2);
    let page0 = load_page_bytes(
        &ReaderSessionRead::capture("c1").expect("capture session"),
        0,
    )
    .expect("page0");
    assert!(!page0.is_empty());
    close_reader("c1");
}

#[test]
fn fake_unreachable_open_fails_clearly() {
    let mut fake = FakeResourceAccess::new();
    fake.insert_file("https://nas.example/dav/book.cbz", b"x");
    fake.set_unreachable("认证失败: 401 Unauthorized");
    let err = open_reader_with(
        &fake,
        "c-unreach",
        "https://nas.example/dav/book.cbz",
        "cbz",
    )
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
    common::with_global_db(|| {
        let temp = TempDir::new().expect("temp").keep();
        let db_path = common::create_fixture_db(temp.as_path());
        let runtime = tokio::runtime::Runtime::new().expect("rt");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib = create_remote_library("https://nas.example/dav", "u", false, None)
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

            open_reader_with(&fake, &comic_id, location, "cbz").unwrap();
            let read = ReaderSessionRead::capture(&comic_id).unwrap();
            let notifications = hentai_core::revision::notify_count();
            let _library_write = hentai_core::try_acquire_library_write_lock().expect("library lock");
            writeback_with_access(&fake, &read, 3)
                .await
                .expect("writeback");
            let comic = find_comic_by_id(&comic_id).await.expect("find").expect("exists");
            assert_eq!(comic.page_count, 3);
            assert_eq!(comic.title, "User Title");
            assert_eq!(hentai_core::revision::notify_count(), notifications + 1);

            writeback_with_access(&FakeResourceAccess::new(), &read, 3)
                .await
                .expect("same page count needs no resource access or write");
            assert_eq!(hentai_core::revision::notify_count(), notifications + 1);
            close_reader(&comic_id);
        });
    });
}

#[test]
fn writeback_skipped_without_valid_pages_does_not_notify() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("temp").keep();
        let db_path = common::create_fixture_db(temp.as_path());
        let runtime = tokio::runtime::Runtime::new().expect("rt");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let db = connection().expect("db");
            db.execute_unprepared(
                "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) VALUES ('empty', '/.empty.cbz', 'cbz', 1, 1, 1)",
            ).await.expect("seed comic");
            db.execute_unprepared(
                "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) VALUES ('empty', 'Empty', 'unknown', 1)",
            ).await.expect("seed metadata");
            let mut fake = FakeResourceAccess::new();
            fake.insert_file("/.empty.cbz", make_cbz_bytes(&[b"page"]));
            open_reader_with(&fake, "empty", "/.empty.cbz", "cbz").unwrap();
            let read = ReaderSessionRead::capture("empty").unwrap();
            let notifications = hentai_core::revision::notify_count();

            for page_count in [0, -1] {
                writeback_with_access(&FakeResourceAccess::new(), &read, page_count)
                    .await
                    .expect("invalid page count is skipped");
            }

            let comic = find_comic_by_id("empty").await.expect("find").expect("retained");
            assert_eq!(comic.page_count, 1);
            assert_eq!(comic.last_updated_at, 1);
            assert_eq!(hentai_core::revision::notify_count(), notifications);
            close_reader("empty");
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
    common::with_global_db(|| {
        let temp = TempDir::new().expect("temp").keep();
        let db_path = common::create_fixture_db(temp.as_path());
        let runtime = tokio::runtime::Runtime::new().expect("rt");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib = create_remote_library("https://nas.example/dav", "u", false, None)
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
