#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

mod common;

use std::io::{Cursor, Write};
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};

use hentai_core::resource::{
    FakeResourceAccess, ResourceAccess, ResourceEntry, ResourceStat, ResourceStream,
};
use hentai_core::sync::refresh_comic_metadata_with;
use hentai_core::{connection, find_comic_by_id, init_db_at_path, ComicDto, HentaiError};
use sea_orm::{ConnectionTrait, Statement};

const LOCATION: &str = "https://nas.example/dav/refresh.cbz";

struct ChangeDuringParse {
    access: FakeResourceAccess,
    db_path: PathBuf,
    comic_id: String,
    sql: String,
    fired: AtomicBool,
    source_changes: bool,
}

impl ResourceAccess for ChangeDuringParse {
    fn list(&self, location: &str) -> Result<Vec<ResourceEntry>, HentaiError> {
        self.access.list(location)
    }

    fn stat(&self, location: &str) -> Result<Option<ResourceStat>, HentaiError> {
        let mut stat = self.access.stat(location)?;
        if self.source_changes && self.fired.load(Ordering::SeqCst) {
            stat.as_mut().unwrap().modified_ms += 1;
        }
        Ok(stat)
    }

    fn open_stream(&self, location: &str) -> Result<ResourceStream, HentaiError> {
        if !self.fired.swap(true, Ordering::SeqCst) {
            let db = rusqlite::Connection::open(&self.db_path).unwrap();
            db.execute_batch("PRAGMA foreign_keys = ON").unwrap();
            db.execute(&self.sql, [&self.comic_id]).unwrap();
        }
        self.access.open_stream(location)
    }
}

fn archive_bytes() -> Vec<u8> {
    let mut zip = zip::ZipWriter::new(Cursor::new(Vec::new()));
    let options = zip::write::SimpleFileOptions::default();
    zip.start_file("001.jpg", options).unwrap();
    zip.write_all(b"page").unwrap();
    zip.start_file("ComicInfo.xml", options).unwrap();
    zip.write_all(
        b"<ComicInfo><Title>Scanned title</Title><Summary>Scanned summary</Summary></ComicInfo>",
    )
    .unwrap();
    zip.finish().unwrap().into_inner()
}

fn with_change(
    sql: &str,
    source_changes: bool,
    verify: impl FnOnce(Result<(), HentaiError>, Option<ComicDto>, bool, u64),
) {
    common::with_global_db(|| {
        let root = tempfile::tempdir().unwrap().keep();
        let db_path = common::create_fixture_db(&root);
        let runtime = tokio::runtime::Runtime::new().unwrap();
        let comic_id = hentai_core::comic_id_for_remote_location(LOCATION);
        runtime.block_on(async {
            init_db_at_path(&db_path).await.unwrap();
            let db = connection().unwrap();
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) VALUES (?, ?, 'cbz', 1, 1, 1)",
                [comic_id.clone().into(), LOCATION.into()],
            )).await.unwrap();
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_meta (comic_id, title, content_rating, page_count, description) VALUES (?, 'Original title', 'unknown', 9, 'Original summary')",
                [comic_id.clone().into()],
            )).await.unwrap();
        });
        let mut access = FakeResourceAccess::new();
        access.insert_file(LOCATION, archive_bytes());
        access.set_modified_ms(LOCATION, 1000);
        let change = ChangeDuringParse {
            access,
            db_path,
            comic_id: comic_id.clone(),
            sql: sql.to_string(),
            fired: AtomicBool::new(false),
            source_changes,
        };
        let before = hentai_core::revision::notify_count();
        let result = runtime.block_on(refresh_comic_metadata_with(&change, &comic_id));
        assert!(change.fired.load(Ordering::SeqCst));
        let current = runtime.block_on(find_comic_by_id(&comic_id)).unwrap();
        let trashed = runtime
            .block_on(hentai_core::is_comic_trashed(&comic_id))
            .unwrap();
        verify(
            result,
            current,
            trashed,
            hentai_core::revision::notify_count() - before,
        );
    });
}

#[test]
fn refresh_merges_with_user_locks_committed_during_parse() {
    with_change(
        "UPDATE comic_meta SET title = 'Newest user title', title_locked = 1, description = 'Newest user summary', description_locked = 1 WHERE comic_id = ?",
        false,
        |result, current, _, notifications| {
            result.unwrap();
            let current = current.unwrap();
            assert_eq!(current.title, "Newest user title");
            assert_eq!(current.description.as_deref(), Some("Newest user summary"));
            assert!(current.locks.title && current.locks.description);
            assert_eq!(current.page_count, 1);
            assert_eq!(notifications, 1);
        },
    );
}

#[test]
fn refresh_does_not_restore_a_source_path_changed_during_parse() {
    with_change(
        "UPDATE comics SET path = 'https://nas.example/dav/replacement.cbz', resource_size = 999 WHERE comic_id = ?",
        false,
        |result, current, _, notifications| {
            assert!(result.is_err());
            let current = current.unwrap();
            assert_eq!(current.path, "https://nas.example/dav/replacement.cbz");
            assert_eq!(current.resource_size, 999);
            assert_eq!(current.page_count, 9);
            assert_eq!(notifications, 0);
        },
    );
}

#[test]
fn refresh_does_not_resurrect_a_removed_comic() {
    with_change(
        "DELETE FROM comics WHERE comic_id = ?",
        false,
        |result, current, _, notifications| {
            assert!(result.is_err());
            assert!(current.is_none());
            assert_eq!(notifications, 0);
        },
    );
}

#[test]
fn refresh_does_not_update_a_comic_trashed_during_parse() {
    with_change(
        "UPDATE comics SET deleted_at = 20 WHERE comic_id = ?",
        false,
        |result, current, trashed, notifications| {
            assert!(result.is_err());
            assert!(trashed);
            assert_eq!(current.unwrap().page_count, 9);
            assert_eq!(notifications, 0);
        },
    );
}

#[test]
fn refresh_rejects_a_source_changed_during_parse_without_committing() {
    with_change(
        "UPDATE comics SET last_updated_at = 20 WHERE comic_id = ?",
        true,
        |result, current, _, notifications| {
            assert!(result.is_err());
            let current = current.unwrap();
            assert_eq!(current.page_count, 9);
            assert_eq!(current.title, "Original title");
            assert_eq!(notifications, 0);
        },
    );
}
