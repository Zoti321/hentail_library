mod common;

use hentai_core::resource_metadata::{
    is_enabled, query_media_overview, set_enabled, status_for_comic,
};
use hentai_core::{
    apply_comic_metadata_bulk_patch, connection, create_sync_handle, find_comics_by_ids,
    set_comic_meta_locks, update_comic_user_meta, ComicMetadataBulkPatch, MultiValueOp,
    MultiValuePatch, SetComicMetaLocksDto, UpdateComicUserMetaDto,
};
use sea_orm::{ConnectionTrait, Statement, TransactionTrait};

#[test]
fn opt_in_backfill_and_committed_metadata_intent_share_one_durable_transaction() {
    common::with_local_library(
        "writeback.sqlite",
        &[("one.cbz", 2), ("two.cbz", 1)],
        |library, runtime| {
            runtime.block_on(async {
            let db = connection().unwrap();
            let ids = db.query_all(Statement::from_sql_and_values(sea_orm::DatabaseBackend::Sqlite,
                "SELECT comic_id FROM comics WHERE library_id = ? ORDER BY path", [library.library_id.clone().into()],
            )).await.unwrap().into_iter().map(|row| row.try_get::<String>("", "comic_id").unwrap()).collect::<Vec<_>>();
            assert!(!is_enabled(&library.library_id).await.unwrap());
            assert_eq!(status_for_comic(&ids[0]).await.unwrap().unwrap().state, "disabled");
            update_comic_user_meta(&ids[0], UpdateComicUserMetaDto { title: Some("Before opt-in".into()), ..Default::default() }).await.unwrap();
            set_enabled(&library.library_id, true).await.unwrap();
            let summary = query_media_overview(false).await.unwrap();
            assert_eq!(summary.total, 2);
            assert_eq!(summary.pending, 2);
            assert_eq!(summary.enabled_libraries, 1);
            for id in &ids {
                let status = status_for_comic(id).await.unwrap().unwrap();
                assert_eq!(status.state, "pending");
                assert_eq!(status.revision, 1);
                assert_eq!(status.applied_revision, 0);
            }
            set_enabled(&library.library_id, true).await.unwrap();
            assert_eq!(status_for_comic(&ids[0]).await.unwrap().unwrap().revision, 1);
            set_comic_meta_locks(&ids[0], SetComicMetaLocksDto { title: Some(false), ..Default::default() }).await.unwrap();
            assert_eq!(status_for_comic(&ids[0]).await.unwrap().unwrap().revision, 1);
            update_comic_user_meta(&ids[0], UpdateComicUserMetaDto { title: Some("Before opt-in".into()), ..Default::default() }).await.unwrap();
            assert_eq!(status_for_comic(&ids[0]).await.unwrap().unwrap().revision, 1);
            update_comic_user_meta(&ids[0], UpdateComicUserMetaDto { authors: Some(vec!["A".into()]), ..Default::default() }).await.unwrap();
            let result = apply_comic_metadata_bulk_patch(ids.clone(), ComicMetadataBulkPatch {
                tags: Some(MultiValuePatch { op: MultiValueOp::Replace, values: vec!["T".into()] }), ..Default::default()
            }, &create_sync_handle()).await.unwrap();
            assert_eq!(result.succeeded, 2);
            let status = status_for_comic(&ids[0]).await.unwrap().unwrap();
            assert_eq!(status.revision, 3);
            let row = db.query_one(Statement::from_sql_and_values(sea_orm::DatabaseBackend::Sqlite,
                "SELECT fields, snapshot FROM resource_metadata_jobs WHERE comic_id = ?", [ids[0].clone().into()],
            )).await.unwrap().unwrap();
            let fields: serde_json::Value = serde_json::from_str(&row.try_get::<String>("", "fields").unwrap()).unwrap();
            assert_eq!(fields.as_array().unwrap().len(), 9);
            let snapshot: serde_json::Value = serde_json::from_str(&row.try_get::<String>("", "snapshot").unwrap()).unwrap();
            assert_eq!(snapshot["authors"], serde_json::json!(["A"]));
            assert_eq!(snapshot["tags"], serde_json::json!(["T"]));

            // An outbox failure rolls back the catalog write instead of losing its intent.
            db.execute_unprepared("CREATE TRIGGER fail_writeback_update BEFORE UPDATE ON resource_metadata_jobs BEGIN SELECT RAISE(ABORT, 'outbox blocked'); END").await.unwrap();
            assert!(update_comic_user_meta(&ids[0], UpdateComicUserMetaDto { title: Some("must roll back".into()), ..Default::default() }).await.is_err());
            assert_eq!(find_comics_by_ids(vec![ids[0].clone()]).await.unwrap()[0].title, "Before opt-in");
            db.execute_unprepared("DROP TRIGGER fail_writeback_update").await.unwrap();
            set_enabled(&library.library_id, false).await.unwrap();
            assert_eq!(status_for_comic(&ids[0]).await.unwrap().unwrap().state, "disabled");
            update_comic_user_meta(&ids[0], UpdateComicUserMetaDto { title: Some("While disabled".into()), ..Default::default() }).await.unwrap();
            assert_eq!(status_for_comic(&ids[0]).await.unwrap().unwrap().revision, 3);
            set_enabled(&library.library_id, true).await.unwrap();
            assert_eq!(status_for_comic(&ids[0]).await.unwrap().unwrap().revision, 4);
            let txn = db.begin().await.unwrap();
            txn.rollback().await.unwrap();
        });
        },
    );
}

#[test]
fn local_opt_in_is_library_scoped_and_remote_libraries_are_rejected() {
    common::with_local_library(
        "writeback-scope.sqlite",
        &[("one.cbz", 1)],
        |library, runtime| {
            runtime.block_on(async {
            let db = connection().unwrap();
            db.execute_unprepared("INSERT INTO libraries(library_id, kind, root_path, name, enabled_format_groups, created_at) VALUES ('other', 'local', '/other', 'Other', '[]', 1), ('remote', 'webdav', 'https://example.test/dav', 'Remote', '[]', 1)").await.unwrap();
            set_enabled(&library.library_id, true).await.unwrap();
            assert!(!is_enabled("other").await.unwrap());
            assert!(set_enabled("remote", true).await.is_err());
            assert!(!is_enabled("remote").await.unwrap());
            assert!(set_enabled("missing", true).await.is_err());
        });
        },
    );
}

#[test]
fn media_overview_aggregates_all_states_and_preserves_visibility_and_library_scope() {
    common::with_local_library(
        "media-overview.sqlite",
        &[
            ("0.cbz", 1),
            ("1.cbz", 1),
            ("2.cbz", 1),
            ("3.cbz", 1),
            ("4.cbz", 1),
            ("5.cbz", 1),
            ("6.cbz", 1),
            ("7.cbz", 1),
            ("8.cbz", 1),
        ],
        |library, runtime| {
            runtime.block_on(async {
                let db = connection().unwrap();
                let initial = query_media_overview(false).await.unwrap();
                assert_eq!(initial.total, 9);
                assert_eq!(initial.disabled, 9);
                assert_eq!(initial.pending, 0);
                assert_eq!(initial.completed, 0);
                set_enabled(&library.library_id, true).await.unwrap();
                let ids = db.query_all(Statement::from_string(sea_orm::DatabaseBackend::Sqlite,
                    "SELECT comic_id FROM comics ORDER BY path".to_owned())).await.unwrap()
                    .into_iter().map(|row| row.try_get::<String>("", "comic_id").unwrap()).collect::<Vec<_>>();
                for (id, state) in ids.iter().zip(["pending", "processing", "completed", "failed", "unsupported", "completed", "failed", "completed", "completed"]) {
                    db.execute(Statement::from_sql_and_values(sea_orm::DatabaseBackend::Sqlite,
                        "UPDATE resource_metadata_jobs SET state = ? WHERE comic_id = ?", [state.into(), id.clone().into()])).await.unwrap();
                }
                db.execute_unprepared("INSERT INTO libraries(library_id, kind, root_path, name, enabled_format_groups, created_at) VALUES
                    ('off', 'local', '/off', 'Off', '[]', 1), ('empty', 'local', '/empty', 'Empty', '[]', 1),
                    ('remote', 'webdav', 'https://example.test/dav', 'Remote', '[]', 1)").await.unwrap();
                for (index, sql) in [
                    (5, "UPDATE comic_meta SET content_rating = 'r18' WHERE comic_id = ?"),
                    (6, "UPDATE comics SET deleted_at = 1 WHERE comic_id = ?"),
                    (7, "UPDATE comics SET library_id = 'off' WHERE comic_id = ?"),
                    (8, "UPDATE comics SET library_id = 'remote' WHERE comic_id = ?"),
                ] {
                    db.execute(Statement::from_sql_and_values(sea_orm::DatabaseBackend::Sqlite, sql, [ids[index].clone().into()])).await.unwrap();
                }
                let summary = query_media_overview(false).await.unwrap();
                assert_eq!(summary.total, 6);
                assert_eq!((summary.pending, summary.processing, summary.completed, summary.failed, summary.unsupported, summary.disabled), (1, 1, 1, 1, 1, 1));
                assert_eq!((summary.local_libraries, summary.enabled_libraries), (3, 1));
                let unfiltered = query_media_overview(true).await.unwrap();
                assert_eq!((unfiltered.total, unfiltered.completed), (7, 2));
                set_enabled(&library.library_id, false).await.unwrap();
                let disabled = query_media_overview(false).await.unwrap();
                assert_eq!((disabled.disabled, disabled.completed, disabled.enabled_libraries), (6, 0, 0));
                db.execute_unprepared("UPDATE comics SET deleted_at = 1").await.unwrap();
                let empty = query_media_overview(false).await.unwrap();
                assert_eq!((empty.total, empty.pending, empty.disabled), (0, 0, 0));
                assert_eq!(empty.local_libraries, 3);
            });
        },
    );
}
