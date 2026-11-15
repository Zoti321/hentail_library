mod common;

use hentai_core::{
    apply_comic_metadata_bulk_patch, comic_id_from_path, connection, create_local_library,
    create_sync_handle, export_comic_metadata, find_comic_by_id, import_comic_metadata,
    init_db_at_path, sync_library, update_comic_user_meta, ComicMetadataBulkPatch,
    ExportComicMetadataOptions, MultiValueOp, MultiValuePatch, SyncScanMode,
    UpdateComicUserMetaDto,
};
use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::MigratorTrait;

fn with_comic(test: impl FnOnce(String, &tokio::runtime::Runtime)) {
    common::with_global_db(|| {
        let temp = tempfile::TempDir::new().expect("tempdir").keep();
        let root = temp.join("library");
        let resource = root.join("book.cbz");
        common::write_cbz(&resource, 2);
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&temp.join("language.sqlite"))
                .await
                .expect("database");
            let library = create_local_library(&root.to_string_lossy(), None)
                .await
                .expect("library");
            sync_library(
                create_sync_handle(),
                SyncScanMode::Full,
                false,
                Some(&library.library_id),
                vec![],
                |_| {},
            )
            .await
            .expect("sync");
        });
        test(comic_id_from_path(&resource.to_string_lossy()), &runtime);
    });
}

#[test]
fn language_migration_keeps_first_value_and_locks_and_is_repeatable() {
    with_comic(|id, runtime| {
        runtime.block_on(async {
            let db = connection().expect("connection");
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "UPDATE comic_meta SET languages = ?, languages_locked = 1 WHERE comic_id = ?",
                [
                    r#"["Unrecognized language","Japanese"]"#.into(),
                    id.clone().into(),
                ],
            ))
            .await
            .expect("legacy values");
            for _ in 0..2 {
                hentai_core::migration::Migrator::migrations()
                    .into_iter()
                    .find(|migration| migration.name().ends_with("single_comic_language"))
                    .expect("language migration")
                    .up(&sea_orm_migration::SchemaManager::new(&db))
                    .await
                    .expect("migrate language");
                let comic = find_comic_by_id(&id).await.unwrap().unwrap();
                assert_eq!(comic.languages, ["Unrecognized language"]);
                assert!(comic.locks.languages);
                assert_eq!(comic.page_count, 2);
                let row = db
                    .query_one(Statement::from_sql_and_values(
                        sea_orm::DatabaseBackend::Sqlite,
                        "SELECT languages FROM comic_meta WHERE comic_id = ?",
                        [id.clone().into()],
                    ))
                    .await
                    .unwrap()
                    .unwrap();
                assert_eq!(
                    row.try_get::<String>("", "languages").unwrap(),
                    r#"["Unrecognized language"]"#
                );
            }
        });
    });
}

#[test]
fn user_and_bulk_language_writes_replace_clear_and_reject_multi_selection() {
    with_comic(|id, runtime| {
        runtime.block_on(async {
            update_comic_user_meta(
                &id,
                UpdateComicUserMetaDto {
                    languages: Some(vec!["Japanese".into()]),
                    ..Default::default()
                },
            )
            .await
            .unwrap();
            assert!(update_comic_user_meta(
                &id,
                UpdateComicUserMetaDto {
                    title: Some("must not commit".into()),
                    languages: Some(vec!["Chinese".into(), "English".into()]),
                    ..Default::default()
                },
            )
            .await
            .is_err());
            for (op, values) in [
                (MultiValueOp::Add, vec!["English".into()]),
                (MultiValueOp::Remove, vec![]),
                (
                    MultiValueOp::Replace,
                    vec!["Chinese".into(), "English".into()],
                ),
            ] {
                assert!(apply_comic_metadata_bulk_patch(
                    vec![id.clone()],
                    ComicMetadataBulkPatch {
                        languages: Some(MultiValuePatch { op, values }),
                        ..Default::default()
                    },
                    &create_sync_handle(),
                )
                .await
                .is_err());
            }
            let comic = find_comic_by_id(&id).await.unwrap().unwrap();
            assert_eq!(comic.languages, ["Japanese"]);
            assert_ne!(comic.title, "must not commit");
            for values in [vec!["English".to_owned()], vec![]] {
                let result = apply_comic_metadata_bulk_patch(
                    vec![id.clone()],
                    ComicMetadataBulkPatch {
                        languages: Some(MultiValuePatch {
                            op: MultiValueOp::Replace,
                            values: values.clone(),
                        }),
                        ..Default::default()
                    },
                    &create_sync_handle(),
                )
                .await
                .unwrap();
                assert_eq!(result.succeeded, 1);
                let comic = find_comic_by_id(&id).await.unwrap().unwrap();
                assert_eq!(comic.languages, values);
                assert!(comic.locks.languages);
            }
        });
    });
}

#[test]
fn legacy_backup_language_lists_import_first_value_and_export_singleton() {
    with_comic(|id, runtime| {
        runtime.block_on(async {
            let bytes = export_comic_metadata(ExportComicMetadataOptions::default())
                .await
                .unwrap();
            let mut payload: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
            payload["comics"][0]["meta"]["languages"] =
                serde_json::json!(["Unrecognized language", "Japanese"]);
            let result = import_comic_metadata(&serde_json::to_vec(&payload).unwrap())
                .await
                .unwrap();
            assert_eq!(result.applied, 1);
            let comic = find_comic_by_id(&id).await.unwrap().unwrap();
            assert_eq!(comic.languages, ["Unrecognized language"]);
            assert!(comic.locks.languages);
            let exported = export_comic_metadata(ExportComicMetadataOptions::default())
                .await
                .unwrap();
            let payload: serde_json::Value = serde_json::from_slice(&exported).unwrap();
            assert_eq!(
                payload["comics"][0]["meta"]["languages"],
                serde_json::json!(["Unrecognized language"])
            );
        });
    });
}
