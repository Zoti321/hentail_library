mod common;

use std::fs;
use std::path::Path;

use hentai_core::comic::ComicDto;
use hentai_core::thumbnail::hd::ThumbnailCoverMeta;
use hentai_core::thumbnail::{find_thumbnail_cover_meta, thumbnail_needs_generation};
use hentai_core::{
    connection, find_series_thumbnail_by_series_id, find_thumbnail_by_comic_id, init_db_at_path,
    resolve_series_cover, set_comic_thumbnail_from_page, set_series_thumbnail_from_page,
    SeriesCoverSource,
};
use image::{ImageBuffer, Rgb};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;

fn write_solid_jpeg(path: &Path, r: u8, g: u8, b: u8) {
    let img: ImageBuffer<Rgb<u8>, Vec<u8>> = ImageBuffer::from_pixel(32, 32, Rgb([r, g, b]));
    img.save(path).expect("write jpeg");
}

fn seed_comic(comic_id: &str, path: &str, resource_type: &str) {
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        let db = connection().expect("connection");
        db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
                 VALUES ('{comic_id}', '{path}', '{resource_type}', 1, 1, 1)"
            ),
        ))
        .await
        .expect("seed comic");
        db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
                 VALUES ('{comic_id}', 'Cover Comic', 'unknown', 2)"
            ),
        ))
        .await
        .expect("seed meta");
    });
}

#[test]
fn set_comic_thumbnail_from_page_marks_user_set_cover() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("cover.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime
            .block_on(init_db_at_path(&db_path))
            .expect("init db");

        let comic_dir = temp.path().join("comic");
        fs::create_dir_all(&comic_dir).expect("mkdir");
        write_solid_jpeg(&comic_dir.join("001.jpg"), 255, 0, 0);
        write_solid_jpeg(&comic_dir.join("002.jpg"), 0, 0, 255);

        let comic_id = "cover-comic-1";
        let path = comic_dir.to_string_lossy().replace('\\', "/");
        seed_comic(comic_id, &path, "dir");

        runtime
            .block_on(set_comic_thumbnail_from_page(
                comic_id, &path, "dir", 1, // 0-based: second page (blue)
            ))
            .expect("set cover");

        let thumb = runtime
            .block_on(find_thumbnail_by_comic_id(comic_id))
            .expect("find")
            .expect("thumbnail exists");
        assert!(!thumb.thumbnail.is_empty());
        assert!(thumb.is_user_set);
    });
}

#[test]
fn legacy_thumbnail_has_no_cover_page_until_user_sets_cover() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let legacy_id = "86408880d30b0de95ca959feb60a3b72dcb1889b";
        {
            let conn = rusqlite::Connection::open(&db_path).expect("open fixture");
            conn.execute(
                "INSERT INTO comic_thumbnails (comic_id, thumbnail, updated_at) VALUES (?1, X'01', 1)",
                [legacy_id],
            )
            .expect("seed legacy thumbnail");
        }
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime
            .block_on(init_db_at_path(&db_path))
            .expect("init db");

        let legacy = runtime
            .block_on(find_thumbnail_cover_meta(legacy_id))
            .expect("meta")
            .expect("legacy row survives migration");
        assert_eq!(
            legacy,
            ThumbnailCoverMeta {
                is_user_set: false,
                source_page_index: None,
            }
        );

        let comic_dir = temp.path().join("comic");
        fs::create_dir_all(&comic_dir).expect("mkdir");
        write_solid_jpeg(&comic_dir.join("001.jpg"), 255, 0, 0);
        write_solid_jpeg(&comic_dir.join("002.jpg"), 0, 0, 255);
        let comic_id = "cover-comic-page";
        let path = comic_dir.to_string_lossy().replace('\\', "/");
        seed_comic(comic_id, &path, "dir");

        runtime
            .block_on(set_comic_thumbnail_from_page(comic_id, &path, "dir", 1))
            .expect("set cover");

        let meta = runtime
            .block_on(find_thumbnail_cover_meta(comic_id))
            .expect("meta")
            .expect("row");
        assert_eq!(
            meta,
            ThumbnailCoverMeta {
                is_user_set: true,
                source_page_index: Some(1),
            }
        );
    });
}

#[test]
fn sync_does_not_regenerate_user_set_comic_thumbnail_after_source_change() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("cover.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime
            .block_on(init_db_at_path(&db_path))
            .expect("init db");

        let comic_dir = temp.path().join("comic");
        fs::create_dir_all(&comic_dir).expect("mkdir");
        write_solid_jpeg(&comic_dir.join("001.jpg"), 255, 0, 0);
        write_solid_jpeg(&comic_dir.join("002.jpg"), 0, 0, 255);

        let comic_id = "cover-comic-user-set";
        let path = comic_dir.to_string_lossy().replace('\\', "/");
        seed_comic(comic_id, &path, "dir");

        runtime
            .block_on(set_comic_thumbnail_from_page(comic_id, &path, "dir", 1))
            .expect("set cover");

        // Source file change would normally trigger regeneration.
        write_solid_jpeg(&comic_dir.join("001.jpg"), 0, 255, 0);
        write_solid_jpeg(&comic_dir.join("003.jpg"), 255, 255, 0);

        let comic = ComicDto {
            comic_id: comic_id.to_string(),
            path: path.clone(),
            resource_type: "dir".to_string(),
            resource_size: 1,
            created_at: 1,
            last_updated_at: 1,
            title: "Cover Comic".to_string(),
            content_rating: "unknown".to_string(),
            page_count: 2,
            description: None,
            published_at: None,
            last_read_time_ms: None,
            authors: vec![],
            tags: vec![],
            languages: vec![],
            parodies: vec![],
            characters: vec![],
            locks: hentai_core::ComicMetaLocks::default(),
            library_id: String::new(),
        };

        let needs = runtime
            .block_on(async {
                let db = connection().expect("connection");
                thumbnail_needs_generation(&db, &comic).await
            })
            .expect("check");
        assert!(
            !needs,
            "user-set comic thumbnail must not be regenerated by sync/queue"
        );
    });
}

fn seed_series(series_id: &str, folder_path: &str, name: &str) {
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        let db = connection().expect("connection");
        db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "INSERT INTO series (series_id, folder_path, name, serialization_status) \
                 VALUES ('{series_id}', '{folder_path}', '{name}', 'unknown')"
            ),
        ))
        .await
        .expect("seed series");
    });
}

fn seed_series_item(series_id: &str, comic_id: &str, sort_order: i32) {
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        let db = connection().expect("connection");
        db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "INSERT INTO series_items (series_id, comic_id, sort_order) \
                 VALUES ('{series_id}', '{comic_id}', {sort_order})"
            ),
        ))
        .await
        .expect("seed series item");
    });
}

#[test]
fn series_custom_thumbnail_is_preferred_over_fallback() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("cover.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime
            .block_on(init_db_at_path(&db_path))
            .expect("init db");

        let comic_dir = temp.path().join("series_comic");
        fs::create_dir_all(&comic_dir).expect("mkdir");
        write_solid_jpeg(&comic_dir.join("001.jpg"), 255, 0, 0);
        write_solid_jpeg(&comic_dir.join("002.jpg"), 0, 0, 255);

        let comic_id = "series-cover-comic";
        let series_id = "series-cover-1";
        let path = comic_dir.to_string_lossy().replace('\\', "/");
        seed_comic(comic_id, &path, "dir");
        seed_series(series_id, &path, "Series Cover");
        seed_series_item(series_id, comic_id, 1);

        runtime
            .block_on(set_series_thumbnail_from_page(
                series_id, comic_id, &path, "dir", 1,
            ))
            .expect("set series cover");

        let custom = runtime
            .block_on(find_series_thumbnail_by_series_id(series_id))
            .expect("find")
            .expect("custom series thumbnail exists");
        assert!(!custom.thumbnail.is_empty());

        let resolved = runtime
            .block_on(resolve_series_cover(series_id))
            .expect("resolve");
        match resolved {
            SeriesCoverSource::CustomThumbnail { thumbnail } => {
                assert_eq!(thumbnail, custom.thumbnail);
            }
            other => panic!("expected custom thumbnail, got {other:?}"),
        }
    });
}

#[test]
fn series_cover_falls_back_to_latest_sort_order_comic() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("cover.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime
            .block_on(init_db_at_path(&db_path))
            .expect("init db");

        let older_dir = temp.path().join("vol1");
        let newer_dir = temp.path().join("vol2");
        fs::create_dir_all(&older_dir).expect("mkdir1");
        fs::create_dir_all(&newer_dir).expect("mkdir2");
        write_solid_jpeg(&older_dir.join("001.jpg"), 255, 0, 0);
        write_solid_jpeg(&newer_dir.join("001.jpg"), 0, 0, 255);

        let older_id = "comic-older";
        let newer_id = "comic-newer";
        let series_id = "series-fallback";
        let older_path = older_dir.to_string_lossy().replace('\\', "/");
        let newer_path = newer_dir.to_string_lossy().replace('\\', "/");
        let folder = temp.path().to_string_lossy().replace('\\', "/");

        seed_comic(older_id, &older_path, "dir");
        seed_comic(newer_id, &newer_path, "dir");
        seed_series(series_id, &folder, "Fallback Series");
        seed_series_item(series_id, older_id, 1);
        seed_series_item(series_id, newer_id, 2);

        let resolved = runtime
            .block_on(resolve_series_cover(series_id))
            .expect("resolve");
        match resolved {
            SeriesCoverSource::FallbackComic { comic_id } => {
                assert_eq!(comic_id, newer_id);
            }
            other => panic!("expected fallback comic, got {other:?}"),
        }
    });
}
