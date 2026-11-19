#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

//! ADR-0026: cross-comic bulk writes fail fast while the library write lock is held.

mod common;

use hentai_core::library_write::{begin_library_write_txn, try_acquire_library_write_lock};
use hentai_core::ComicGrouping;
use hentai_core::{
    add_author, add_named_facet_name, clear_all_reading, count_trashed_comics, create_sync_handle,
    delete_authors_by_names, delete_library, delete_named_facet_by_names, fetch_comics_page,
    import_comic_metadata, merge_named_facet_name, reject_author_merge, rename_author,
    rename_author_identity, rename_named_facet_name, set_comic_meta_locks, sync_library,
    update_comic_user_meta, ComicFilterDto, ComicSortOptionDto, HentaiError, HentaiErrorCode,
    JunctionNamedFacet, LibraryDto, PageRequestDto, SetComicMetaLocksDto, SyncScanMode,
    UpdateComicUserMetaDto,
};
use sea_orm::{ConnectionTrait, DatabaseBackend, Statement};

const BUSY_MESSAGE: &str = "库写入操作进行中";

/// One synced Local library holding `solo.cbz`; [test] gets the runtime for its awaits.
fn with_solo_library(test: impl FnOnce(LibraryDto, &tokio::runtime::Runtime)) {
    common::with_local_library("library_write.sqlite", &[("solo.cbz", 1)], test);
}

fn sync(library: &LibraryDto, runtime: &tokio::runtime::Runtime) {
    runtime.block_on(async {
        sync_library(
            create_sync_handle(),
            SyncScanMode::Full,
            false,
            Some(library.library_id.as_str()),
            vec![],
            |_| {},
        )
        .await
        .expect("re-sync");
    });
}

/// Asserts the call was refused by the library write seam, not by business logic.
fn assert_busy(result: Result<impl std::fmt::Debug, HentaiError>) {
    let err = match result {
        Ok(value) => panic!("expected busy error, got {value:?}"),
        Err(err) => err,
    };
    assert_eq!(err.code, HentaiErrorCode::Validation, "{}", err.message);
    assert!(
        err.message.contains(BUSY_MESSAGE),
        "expected {BUSY_MESSAGE:?}, got {:?}",
        err.message
    );
}

#[test]
fn cross_comic_writes_fail_fast_while_library_write_lock_held() {
    use JunctionNamedFacet::Tag;

    with_solo_library(|library, runtime| {
        runtime.block_on(async {
            let _guard = try_acquire_library_write_lock().expect("hold lock");

            // Library sync is the flagship holder; the rest are the bulk writes
            // newly brought under the lock by ADR-0026.
            assert_busy(
                sync_library(
                    create_sync_handle(),
                    SyncScanMode::Full,
                    false,
                    Some(library.library_id.as_str()),
                    vec![],
                    |_| {},
                )
                .await,
            );
            // Import must refuse before parsing the payload.
            assert_busy(import_comic_metadata(b"not-a-backup").await);
            assert_busy(rename_author("old", "new").await);
            let notifications = hentai_core::revision::notify_count();
            assert_busy(rename_author_identity(i64::MAX, "new").await);
            assert_eq!(hentai_core::revision::notify_count(), notifications);
            assert_busy(delete_authors_by_names(vec!["old".to_string()]).await);
            assert_busy(rename_named_facet_name(Tag, "old", "new").await);
            assert_busy(delete_named_facet_by_names(Tag, vec!["old".to_string()]).await);
            assert_busy(merge_named_facet_name(Tag, "old", "new").await);
            assert_busy(reject_author_merge().await);
            assert_busy(clear_all_reading().await);
        });

        // Lock is released: the same writes now reach their real logic.
        runtime.block_on(async {
            rename_named_facet_name(Tag, "old", "new")
                .await
                .expect("tag rename");
            add_named_facet_name(Tag, "new").await.expect("add tag");
            clear_all_reading().await.expect("clear reading");
        });
        sync(&library, runtime);
    });
}

#[test]
fn author_entry_points_do_not_double_acquire_the_lock() {
    use JunctionNamedFacet::Tag;

    with_solo_library(|_library, runtime| {
        runtime.block_on(async {
            let author = add_author("Some Author").await.expect("add author");
            add_named_facet_name(Tag, "Some Tag")
                .await
                .expect("add tag");

            // Author entry points own their write lock: they must not error busy
            // and must release the guard for the next writer.
            rename_author("Some Author", "Renamed Author")
                .await
                .expect("author rename");
            rename_author_identity(author.id, "Identity Renamed Author")
                .await
                .expect("identity rename does not double acquire");
            delete_authors_by_names(vec!["Identity Renamed Author".to_string()])
                .await
                .expect("author delete");

            rename_named_facet_name(Tag, "Some Tag", "Renamed Tag")
                .await
                .expect("tag facet rename");
            delete_named_facet_by_names(Tag, vec!["Renamed Tag".to_string()])
                .await
                .expect("tag facet delete");
        });
    });
}

#[test]
fn failed_entry_points_do_not_leak_the_lock() {
    use JunctionNamedFacet::Tag;

    with_solo_library(|_library, runtime| {
        runtime.block_on(async {
            // Normal business errors (not the busy one) must release the guard.
            let err = rename_author("missing", "new")
                .await
                .expect_err("missing author");
            assert!(!err.message.contains(BUSY_MESSAGE), "{}", err.message);
            let err = import_comic_metadata(b"not-a-backup")
                .await
                .expect_err("invalid backup");
            assert!(!err.message.contains(BUSY_MESSAGE), "{}", err.message);
            let err = reject_author_merge()
                .await
                .expect_err("author merge unsupported");
            assert!(!err.message.contains(BUSY_MESSAGE), "{}", err.message);
            assert_eq!(err.message, "作者暂不支持合并");
            let err = merge_named_facet_name(Tag, "same", "same")
                .await
                .expect_err("merge source equals target");
            assert!(!err.message.contains(BUSY_MESSAGE), "{}", err.message);
            let err = merge_named_facet_name(Tag, "missing", "target")
                .await
                .expect_err("missing merge source");
            assert!(!err.message.contains(BUSY_MESSAGE), "{}", err.message);

            let guard = try_acquire_library_write_lock().expect("lock released after errors");
            drop(guard);
            clear_all_reading().await.expect("write after failures");
        });
    });
}

/// Rule 4 of ADR-0026: single-Comic user writes never take the library write lock,
/// so editing must stay available while a cross-Comic bulk write is running.
#[test]
fn single_comic_user_writes_stay_available_while_the_lock_is_held() {
    with_solo_library(|library, runtime| {
        runtime.block_on(async {
            let comic_id = fetch_comics_page(
                PageRequestDto {
                    page: 1,
                    page_size: 100,
                },
                ComicFilterDto {
                    library_id: Some(library.library_id.clone()),
                    ..Default::default()
                },
                ComicGrouping::None,
                ComicSortOptionDto::default(),
            )
            .await
            .expect("catalog")
            .items
            .into_iter()
            .map(|comic| comic.comic_id)
            .next()
            .expect("one comic");

            let _guard = try_acquire_library_write_lock().expect("hold lock");
            update_comic_user_meta(
                &comic_id,
                UpdateComicUserMetaDto {
                    title: Some("Edited during bulk write".to_string()),
                    ..Default::default()
                },
            )
            .await
            .expect("single-comic meta write is not blocked by the seam");
            set_comic_meta_locks(
                &comic_id,
                SetComicMetaLocksDto {
                    title: Some(true),
                    ..Default::default()
                },
            )
            .await
            .expect("single-comic lock edit is not blocked by the seam");
        });
    });
}

#[test]
fn library_write_txn_rolls_back_commits_and_releases_the_lock() {
    with_solo_library(|_library, runtime| {
        runtime.block_on(async {
            assert_eq!(count_trashed_comics().await.expect("count").total, 0);

            // Explicit rollback keeps the uncommitted statement out of the library.
            let write = begin_library_write_txn().await.expect("begin txn");
            assert_eq!(trash_first_comic(write.txn()).await, 1);
            write.rollback().await.expect("rollback");
            assert_eq!(count_trashed_comics().await.expect("count").total, 0);

            // Dropping the session without committing rolls back too (sea-orm reclaims
            // the connection) and always releases the lock.
            {
                let write = begin_library_write_txn().await.expect("begin txn");
                assert_eq!(trash_first_comic(write.txn()).await, 1);
            }
            assert_eq!(count_trashed_comics().await.expect("count").total, 0);
            clear_all_reading().await.expect("lock released after drop");

            // Committing persists the same statement.
            let write = begin_library_write_txn().await.expect("begin txn");
            assert_eq!(trash_first_comic(write.txn()).await, 1);
            write.commit().await.expect("commit");
            assert_eq!(count_trashed_comics().await.expect("count").total, 1);

            clear_all_reading()
                .await
                .expect("lock released after commit");
        });
    });
}

async fn trash_first_comic<C: ConnectionTrait>(db: &C) -> u64 {
    let result = db
        .execute(Statement::from_string(
            DatabaseBackend::Sqlite,
            "UPDATE comics SET deleted_at = 1".to_string(),
        ))
        .await
        .expect("update comics");
    result.rows_affected()
}

fn with_retained_removal_library(
    test: impl FnOnce(LibraryDto, std::path::PathBuf, &tokio::runtime::Runtime),
) {
    common::with_global_db(|| {
        // Retain resources and database files for manual cleanup.
        let temp = tempfile::tempdir().expect("tempdir").keep();
        let resource = temp.join("library").join("series").join("solo.cbz");
        common::write_cbz(&resource, 1);
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        let library = runtime.block_on(async {
            hentai_core::init_db_at_path(&temp.join("removal.sqlite"))
                .await
                .expect("init database");
            let library = hentai_core::create_local_library(
                &temp.join("library").to_string_lossy(),
                Some("Removal"),
            )
            .await
            .expect("create library");
            sync_library(
                create_sync_handle(),
                SyncScanMode::Full,
                false,
                Some(&library.library_id),
                vec![],
                |_| {},
            )
            .await
            .expect("sync library");
            library
        });
        test(library, resource, &runtime);
    });
}

async fn removal_row_counts() -> Vec<i64> {
    let db = hentai_core::connection().expect("connection");
    let mut counts = Vec::new();
    for table in [
        "libraries",
        "comics",
        "comic_meta",
        "series",
        "series_items",
        "library_resource_snapshots",
    ] {
        let row = db
            .query_one(Statement::from_string(
                db.get_database_backend(),
                format!("SELECT COUNT(*) FROM {table}"),
            ))
            .await
            .expect("row count query")
            .expect("row count");
        counts.push(row.try_get_by_index(0).expect("count"));
    }
    counts
}

#[test]
fn library_removal_refuses_an_active_writer_then_deletes_only_records() {
    with_retained_removal_library(|library, resource, runtime| {
        runtime.block_on(async {
            let before = removal_row_counts().await;
            assert_eq!(before, vec![1, 1, 1, 1, 1, 1]);
            let notifications = hentai_core::revision::notify_count();
            let changes = hentai_core::revision::subscribe();
            let guard = try_acquire_library_write_lock().expect("hold active writer");

            assert_busy(delete_library(&library.library_id).await);

            assert_eq!(removal_row_counts().await, before);
            assert_eq!(hentai_core::revision::notify_count(), notifications);
            assert!(!changes.has_changed().expect("revision remains open"));
            drop(guard);
            delete_library(&library.library_id)
                .await
                .expect("delete after writer completes");
            assert_eq!(removal_row_counts().await, vec![0; 6]);
            assert!(resource.exists(), "Library removal retains Resources");
            assert_eq!(hentai_core::revision::notify_count(), notifications + 1);
            delete_library(&library.library_id)
                .await
                .expect("missing library is a no-op");
            assert_eq!(hentai_core::revision::notify_count(), notifications + 1);
            try_acquire_library_write_lock().expect("no-op releases lock");
        });
    });
}

#[test]
fn library_removal_rolls_back_on_final_delete_failure_and_releases_the_lock() {
    with_retained_removal_library(|library, resource, runtime| {
        runtime.block_on(async {
            let db = hentai_core::connection().expect("connection");
            db.execute_unprepared(
                "CREATE TRIGGER block_library_removal BEFORE DELETE ON libraries \
                 BEGIN SELECT RAISE(ABORT, 'library removal blocked'); END",
            )
            .await
            .expect("inject final deletion failure");
            let before = removal_row_counts().await;
            let notifications = hentai_core::revision::notify_count();

            let error = delete_library(&library.library_id)
                .await
                .expect_err("final delete fails");

            assert!(
                error.message.contains("library removal blocked"),
                "{error:?}"
            );
            assert_eq!(removal_row_counts().await, before);
            assert_eq!(hentai_core::revision::notify_count(), notifications);
            try_acquire_library_write_lock().expect("failed removal releases lock");
            db.execute_unprepared("DROP TRIGGER block_library_removal")
                .await
                .expect("remove injected failure");
            delete_library(&library.library_id)
                .await
                .expect("new removal succeeds");
            assert_eq!(removal_row_counts().await, vec![0; 6]);
            assert!(resource.exists());
            assert_eq!(hentai_core::revision::notify_count(), notifications + 1);
        });
    });
}
