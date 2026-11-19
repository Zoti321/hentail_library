#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

mod common;

use std::io::{Cursor, Write};
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};

use hentai_core::resource::{
    FakeResourceAccess, ResourceAccess, ResourceEntry, ResourceStat, ResourceStream,
};
use hentai_core::{
    connection, find_comic_by_id, init_db_at_path, open_reader_with, writeback_with_access,
    ComicDto,
};
use sea_orm::{ConnectionTrait, Statement};

const LOCATION: &str = "https://nas.example/dav/writeback.cbz";

struct CatalogChangeOnRead {
    access: FakeResourceAccess,
    db_path: PathBuf,
    comic_id: String,
    sql: String,
    fired: AtomicBool,
    change_on_stat: bool,
    source_changes: bool,
}

impl CatalogChangeOnRead {
    fn change_catalog(&self) {
        if !self.fired.swap(true, Ordering::SeqCst) {
            let db = rusqlite::Connection::open(&self.db_path).unwrap();
            db.execute_batch("PRAGMA foreign_keys = ON").unwrap();
            db.execute(&self.sql, [&self.comic_id]).unwrap();
        }
    }
}

impl ResourceAccess for CatalogChangeOnRead {
    fn local_path(&self, location: &str) -> Option<PathBuf> {
        self.access.local_path(location)
    }

    fn list(&self, location: &str) -> Result<Vec<ResourceEntry>, hentai_core::HentaiError> {
        self.access.list(location)
    }

    fn stat(&self, location: &str) -> Result<Option<ResourceStat>, hentai_core::HentaiError> {
        if self.change_on_stat {
            self.change_catalog();
        }
        let mut stat = self.access.stat(location)?;
        if self.source_changes && self.fired.load(Ordering::SeqCst) {
            stat.as_mut().unwrap().modified_ms += 1;
        }
        Ok(stat)
    }

    fn open_stream(&self, location: &str) -> Result<ResourceStream, hentai_core::HentaiError> {
        self.change_catalog();
        self.access.open_stream(location)
    }
}

fn source_archive() -> Vec<u8> {
    let mut bytes = Vec::new();
    {
        let mut zip = zip::ZipWriter::new(Cursor::new(&mut bytes));
        for page in 0..3 {
            zip.start_file(
                format!("{page:03}.jpg"),
                zip::write::SimpleFileOptions::default(),
            )
            .unwrap();
            zip.write_all(b"page").unwrap();
        }
        zip.start_file("ComicInfo.xml", zip::write::SimpleFileOptions::default())
            .unwrap();
        zip.write_all(b"<ComicInfo><Title>Scanned title</Title><Summary>Scanned summary</Summary></ComicInfo>").unwrap();
        zip.finish().unwrap();
    }
    bytes
}

fn with_catalog_change(sql: &str, verify: impl FnOnce(Option<ComicDto>, bool, u64)) {
    with_change(LOCATION, sql, false, false, verify);
}

fn with_change(
    location: &str,
    sql: &str,
    change_on_stat: bool,
    source_changes: bool,
    verify: impl FnOnce(Option<ComicDto>, bool, u64),
) {
    common::with_global_db(|| {
        let root = tempfile::tempdir().unwrap().keep();
        let db_path = common::create_fixture_db(&root);
        let runtime = tokio::runtime::Runtime::new().unwrap();
        let comic_id = hentai_core::comic_id_for_remote_location(location);
        runtime.block_on(async {
            init_db_at_path(&db_path).await.unwrap();
            let db = connection().unwrap();
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) VALUES (?, ?, 'cbz', 1, 1, 1)",
                [comic_id.clone().into(), location.into()],
            )).await.unwrap();
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_meta (comic_id, title, content_rating, page_count, description) VALUES (?, 'Original title', 'unknown', 1, 'Original summary')",
                [comic_id.clone().into()],
            )).await.unwrap();
        });
        let mut access = FakeResourceAccess::new();
        access.insert_file(location, source_archive());
        access.set_modified_ms(location, 1000);
        open_reader_with(&access, &comic_id, location, "cbz").unwrap();
        let read = hentai_core::ReaderSessionRead::capture(&comic_id).unwrap();
        let change = CatalogChangeOnRead {
            access,
            db_path,
            comic_id: comic_id.clone(),
            sql: sql.to_string(),
            fired: AtomicBool::new(false),
            change_on_stat,
            source_changes,
        };
        let before = hentai_core::revision::notify_count();
        runtime
            .block_on(writeback_with_access(&change, &read, 3))
            .unwrap();
        assert!(change.fired.load(Ordering::SeqCst));
        let current = runtime.block_on(find_comic_by_id(&comic_id)).unwrap();
        let trashed = runtime
            .block_on(hentai_core::is_comic_trashed(&comic_id))
            .unwrap();
        let notifications = hentai_core::revision::notify_count() - before;
        verify(current, trashed, notifications);
        hentai_core::close_reader(&comic_id);
    });
}

#[test]
fn writeback_does_not_restore_a_source_path_changed_during_parse() {
    with_catalog_change(
        "UPDATE comics SET path = 'https://nas.example/dav/replacement.cbz', resource_size = 999, last_updated_at = 20 WHERE comic_id = ?",
        |current, _, notifications| {
            let current = current.unwrap();
            assert_eq!(current.path, "https://nas.example/dav/replacement.cbz");
            assert_eq!(current.resource_size, 999);
            assert_eq!(current.page_count, 1);
            assert_eq!(current.last_updated_at, 20);
            assert_eq!(notifications, 0);
        },
    );
}

#[test]
fn writeback_uses_user_locks_committed_during_parse() {
    with_catalog_change(
        "UPDATE comic_meta SET title = 'Newest user title', title_locked = 1, description = 'Newest user summary', description_locked = 1 WHERE comic_id = ?",
        |current, _, notifications| {
            let current = current.unwrap();
            assert_eq!(current.title, "Newest user title");
            assert_eq!(current.description.as_deref(), Some("Newest user summary"));
            assert!(current.locks.title);
            assert!(current.locks.description);
            assert_eq!(current.page_count, 3);
            assert_eq!(notifications, 1);
        },
    );
}

#[test]
fn writeback_does_not_resurrect_a_comic_removed_during_parse() {
    with_catalog_change(
        "DELETE FROM comics WHERE comic_id = ?",
        |current, _, notifications| {
            assert!(current.is_none());
            assert_eq!(notifications, 0);
        },
    );
}

#[test]
fn writeback_does_not_update_a_comic_trashed_during_parse() {
    with_catalog_change(
        "UPDATE comics SET deleted_at = 20 WHERE comic_id = ?",
        |current, trashed, notifications| {
            assert!(trashed);
            assert_eq!(current.unwrap().page_count, 1);
            assert_eq!(notifications, 0);
        },
    );
}

#[test]
fn writeback_does_not_restore_a_source_type_changed_during_parse() {
    with_catalog_change(
        "UPDATE comics SET resource_type = 'epub' WHERE comic_id = ?",
        |current, _, notifications| {
            let current = current.unwrap();
            assert_eq!(current.resource_type, "epub");
            assert_eq!(current.page_count, 1);
            assert_eq!(notifications, 0);
        },
    );
}

#[test]
fn writeback_skips_a_source_changed_during_parse() {
    with_change(
        LOCATION,
        "UPDATE comics SET last_updated_at = 20 WHERE comic_id = ?",
        false,
        true,
        |current, _, notifications| {
            assert_eq!(current.unwrap().page_count, 1);
            assert_eq!(notifications, 0);
        },
    );
}

#[test]
fn writeback_skips_a_source_changed_before_parse() {
    with_change(
        LOCATION,
        "UPDATE comics SET last_updated_at = 20 WHERE comic_id = ?",
        true,
        true,
        |current, _, notifications| {
            assert_eq!(current.unwrap().page_count, 1);
            assert_eq!(notifications, 0);
        },
    );
}

#[test]
fn writeback_without_parsed_metadata_preserves_the_latest_unlocked_fields() {
    with_change("https://nas.example/dav/.hidden.cbz", "UPDATE comic_meta SET title = 'Newest unlocked title', description = 'Newest unlocked summary' WHERE comic_id = ?", true, false, |current, _, notifications| {
        let current = current.unwrap();
        assert_eq!(current.title, "Newest unlocked title");
        assert_eq!(current.description.as_deref(), Some("Newest unlocked summary"));
        assert!(!current.locks.title);
        assert!(!current.locks.description);
        assert_eq!(current.page_count, 3);
        assert_eq!(notifications, 1);
    });
}

#[test]
fn directory_writeback_uses_the_opened_page_count_without_reparsing_archive_suffixes() {
    common::with_global_db(|| {
        let root = tempfile::tempdir().unwrap().keep();
        let db_path = common::create_fixture_db(&root);
        let runtime = tokio::runtime::Runtime::new().unwrap();
        runtime.block_on(async {
            init_db_at_path(&db_path).await.unwrap();
            let location = "/memory/Images.cbz";
            let mut access = FakeResourceAccess::new();
            access.insert_file(format!("{location}/001.jpg"), b"page-one");
            access.insert_file(format!("{location}/002.png"), b"page-two");
            let parsed = hentai_core::resource::parse_directory_with(&access, location).unwrap().unwrap();
            let comic = hentai_core::resource::parsed_to_comic(&parsed);
            let id = comic.comic_id.clone();
            let db = connection().unwrap();
            let plan = hentai_core::sync::plan::build_scan_replace_plan(&db, vec![hentai_core::sync::scanner::ScanItem::from_resource(comic)], "").await.unwrap();
            hentai_core::sync::writer::apply_scan_replace_plan(&db, &plan, "").await.unwrap();
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "UPDATE comic_meta SET page_count = 9, title = 'Latest unlocked title', title_locked = 0 WHERE comic_id = ?",
                [id.clone().into()],
            )).await.unwrap();
            open_reader_with(&access, &id, location, "dir").unwrap();
            let read = hentai_core::ReaderSessionRead::capture(&id).unwrap();
            let list = hentai_core::load_page_list(&read).unwrap();
            assert_eq!(list.page_count, 2);
            access.insert_file(format!("{location}/003.webp"), b"new-page");
            let notifications = hentai_core::revision::notify_count();
            writeback_with_access(&access, &read, list.page_count).await.unwrap();
            let current = find_comic_by_id(&id).await.unwrap().unwrap();
            assert_eq!(current.page_count, 2);
            assert_eq!(current.title, "Latest unlocked title");
            assert_eq!(current.resource_type, "dir");
            assert_eq!(current.resource_size, 16);
            assert!(!current.locks.title);
            assert_eq!(hentai_core::revision::notify_count(), notifications + 1);
            hentai_core::close_reader(&id);
        });
    });
}
