mod common;

use hentai_core::{
    create_local_library, export_comic_metadata, find_comic_by_id, import_comic_metadata,
    init_db_at_path, peek_metadata_backup_manifest, preview_import_comic_metadata,
    set_current_library_id, ExportComicMetadataOptions, MatchTier, UpdateComicUserMetaDto,
};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;

async fn seed_round_trip_fixture(db: &impl ConnectionTrait, library_id: &str) {
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM comic_tags; DELETE FROM comic_authors; DELETE FROM comic_parodies; \
         DELETE FROM comic_characters; DELETE FROM comic_meta; DELETE FROM comics; \
         DELETE FROM tags; DELETE FROM authors; DELETE FROM parodies; DELETE FROM characters"
            .to_string(),
    ))
    .await
    .expect("clear");

    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at, library_id) \
         VALUES ('c1', 'E:/lib/series/a.cbz', 'cbz', 1, 1, 1, ?)",
        [sea_orm::Value::String(Some(Box::new(library_id.to_string())))],
    ))
    .await
    .expect("seed comic");

    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comic_meta (comic_id, title, title_sort_key, content_rating, page_count, \
         title_locked, description_locked, published_at_locked, content_rating_locked, \
         authors_locked, tags_locked, languages, languages_locked, parodies_locked, characters_locked) \
         VALUES ('c1', '旧标题', '旧标题', 'unknown', 10, 0, 0, 0, 0, 0, 0, '[]', 0, 0, 0)"
            .to_string(),
    ))
    .await
    .expect("seed meta");
}

#[test]
fn export_import_round_trip_restores_user_metadata_and_locks() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("roundtrip.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let lib = create_local_library("E:/lib", None)
                .await
                .expect("library");
            set_current_library_id(Some(&lib.library_id))
                .await
                .expect("current");
            let db = hentai_core::connection().expect("connection");
            seed_round_trip_fixture(&db, &lib.library_id).await;

            hentai_core::update_comic_user_meta(
                "c1",
                UpdateComicUserMetaDto {
                    title: Some("恢复标题".to_string()),
                    tags: Some(vec!["标签A".to_string()]),
                    languages: Some(vec!["Chinese".to_string()]),
                    authors: Some(vec!["作者A".to_string()]),
                    ..Default::default()
                },
            )
            .await
            .expect("seed user meta");

            let bytes = export_comic_metadata(ExportComicMetadataOptions {
                library_id: None,
                include_orphan_facets: false,
            })
            .await
            .expect("export");

            let manifest = peek_metadata_backup_manifest(&bytes).expect("peek");
            assert_eq!(manifest.comic_count, 1);

            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "UPDATE comic_meta SET title = '旧标题', languages = '[]'; \
                 DELETE FROM comic_tags; DELETE FROM comic_authors"
                    .to_string(),
            ))
            .await
            .expect("reset");

            let result = import_comic_metadata(&bytes).await.expect("import");
            assert_eq!(result.applied, 1);
            assert_eq!(result.skipped_not_found, 0);
            assert_eq!(result.skipped_ambiguous, 0);

            let comic = find_comic_by_id("c1").await.expect("find").expect("exists");
            assert_eq!(comic.title, "恢复标题");
            assert_eq!(comic.tags, vec!["标签A".to_string()]);
            assert_eq!(comic.authors, vec!["作者A".to_string()]);
            assert_eq!(comic.languages, vec!["Chinese".to_string()]);
            assert!(comic.locks.title);
            assert!(comic.locks.tags);
            assert!(comic.locks.authors);
            assert!(comic.locks.languages);
            assert!(comic.locks.description);
            assert!(comic.locks.published_at);
            assert!(comic.locks.content_rating);
            assert!(comic.locks.parodies);
            assert!(comic.locks.characters);
        });
    });
}

#[test]
fn import_skips_when_no_match_and_does_not_create_comic() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("skip.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let lib = create_local_library("E:/lib", None)
                .await
                .expect("library");
            set_current_library_id(Some(&lib.library_id))
                .await
                .expect("current");
            let db = hentai_core::connection().expect("connection");
            seed_round_trip_fixture(&db, &lib.library_id).await;

            let bytes = export_comic_metadata(ExportComicMetadataOptions::default())
                .await
                .expect("export");

            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "DELETE FROM comic_meta WHERE comic_id = 'c1'; \
                 DELETE FROM comics WHERE comic_id = 'c1'; \
                 INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at, library_id) \
                 VALUES ('other', 'E:/lib/moved/b.cbz', 'cbz', 1, 1, 1, ?); \
                 INSERT INTO comic_meta (comic_id, title, title_sort_key, content_rating, page_count) \
                 VALUES ('other', '其它', '其它', 'unknown', 1)",
                [sea_orm::Value::String(Some(Box::new(lib.library_id.clone())))],
            ))
            .await
            .expect("replace comic without path migration");

            let result = import_comic_metadata(&bytes).await.expect("import");
            assert_eq!(result.applied, 0);
            assert_eq!(result.skipped_not_found, 1);

            let count = db
                .query_one(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT COUNT(*) FROM comics".to_string(),
                ))
                .await
                .expect("count")
                .expect("row")
                .try_get_by_index::<i64>(0)
                .expect("value");
            assert_eq!(count, 1);
        });
    });
}

#[test]
fn preview_import_does_not_write_db_including_orphan_facets() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("preview.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let lib = create_local_library("E:/lib", None)
                .await
                .expect("library");
            set_current_library_id(Some(&lib.library_id))
                .await
                .expect("current");
            let db = hentai_core::connection().expect("connection");
            seed_round_trip_fixture(&db, &lib.library_id).await;

            hentai_core::update_comic_user_meta(
                "c1",
                UpdateComicUserMetaDto {
                    title: Some("预览前标题".to_string()),
                    tags: Some(vec!["预览标签".to_string()]),
                    ..Default::default()
                },
            )
            .await
            .expect("seed user meta");

            let bytes = export_comic_metadata(ExportComicMetadataOptions {
                library_id: None,
                include_orphan_facets: true,
            })
            .await
            .expect("export");

            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "UPDATE comic_meta SET title = '旧标题'; DELETE FROM comic_tags"
                    .to_string(),
            ))
            .await
            .expect("reset meta");

            let tag_count_before = db
                .query_one(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT COUNT(*) FROM tags".to_string(),
                ))
                .await
                .expect("tags")
                .expect("row")
                .try_get_by_index::<i64>(0)
                .expect("value");

            let preview = preview_import_comic_metadata(&bytes)
                .await
                .expect("preview");
            assert_eq!(preview.would_apply, 1);
            assert_eq!(preview.skipped_not_found, 0);
            assert_eq!(preview.skipped_ambiguous, 0);
            assert!(preview.would_upsert_orphan_facet_count > 0);
            assert_eq!(preview.samples_would_apply.len(), 1);
            assert!(preview.samples_would_apply[0].match_tier.is_none());

            let comic = find_comic_by_id("c1").await.expect("find").expect("exists");
            assert_eq!(comic.title, "旧标题");
            assert!(comic.tags.is_empty());

            let tag_count_after = db
                .query_one(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT COUNT(*) FROM tags".to_string(),
                ))
                .await
                .expect("tags after")
                .expect("row")
                .try_get_by_index::<i64>(0)
                .expect("value");
            assert_eq!(tag_count_before, tag_count_after);
        });
    });
}

#[test]
fn preview_reports_path_tier_when_comic_id_missing() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("preview_path.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let lib = create_local_library("E:/lib", None)
                .await
                .expect("library");
            set_current_library_id(Some(&lib.library_id))
                .await
                .expect("current");
            let db = hentai_core::connection().expect("connection");
            seed_round_trip_fixture(&db, &lib.library_id).await;

            let bytes = export_comic_metadata(ExportComicMetadataOptions::default())
                .await
                .expect("export");

            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "DELETE FROM comic_meta WHERE comic_id = 'c1'; \
                 DELETE FROM comics WHERE comic_id = 'c1'; \
                 INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at, library_id) \
                 VALUES ('c2', 'E:/lib/series/a.cbz', 'cbz', 1, 1, 1, \
                 (SELECT library_id FROM libraries LIMIT 1)); \
                 INSERT INTO comic_meta (comic_id, title, title_sort_key, content_rating, page_count) \
                 VALUES ('c2', '新身份', '新身份', 'unknown', 10)"
                    .to_string(),
            ))
            .await
            .expect("rekey comic id while keeping path");

            let preview = preview_import_comic_metadata(&bytes)
                .await
                .expect("preview");
            assert_eq!(preview.would_apply, 1);
            assert_eq!(preview.skipped_not_found, 0);
            assert_eq!(preview.samples_would_apply.len(), 1);
            assert_eq!(preview.samples_would_apply[0].matched_comic_id, "c2");
            assert_eq!(
                preview.samples_would_apply[0].match_tier,
                Some(MatchTier::Path)
            );

            let import_result = import_comic_metadata(&bytes).await.expect("import");
            assert_eq!(import_result.applied, preview.would_apply);
        });
    });
}

#[test]
fn preview_reports_ambiguous_candidates() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("preview_ambiguous.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let lib = create_local_library("E:/lib", None)
                .await
                .expect("library");
            set_current_library_id(Some(&lib.library_id))
                .await
                .expect("current");
            let db = hentai_core::connection().expect("connection");

            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "DELETE FROM comic_meta; DELETE FROM comics".to_string(),
            ))
            .await
            .expect("clear");

            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at, library_id) \
                 VALUES ('dup-a', 'E:/lib/dup.cbz', 'cbz', 1, 1, 1, ?), \
                        ('dup-b', 'E:/lib/dup.cbz', 'cbz', 1, 1, 1, ?)",
                [
                    sea_orm::Value::String(Some(Box::new(lib.library_id.clone()))),
                    sea_orm::Value::String(Some(Box::new(lib.library_id.clone()))),
                ],
            ))
            .await
            .expect("seed ambiguous comics");

            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_meta (comic_id, title, title_sort_key, content_rating, page_count) \
                 VALUES ('dup-a', '歧义A', '歧义A', 'unknown', 1), \
                        ('dup-b', '歧义B', '歧义B', 'unknown', 1)"
                    .to_string(),
            ))
            .await
            .expect("seed meta");

            let payload = hentai_core::MetadataBackupPayload {
                schema_version: hentai_core::SCHEMA_VERSION,
                exported_at: "2026-01-01T00:00:00Z".to_string(),
                app_version: "test".to_string(),
                options: hentai_core::ExportOptionsRecord {
                    library_id: None,
                    include_orphan_facets: false,
                },
                orphan_facets: Default::default(),
                comics: vec![hentai_core::ComicExportRecord {
                    comic_id: "backup-id".to_string(),
                    path: "E:/lib/dup.cbz".to_string(),
                    library_id: lib.library_id.clone(),
                    relative_path: Some("dup.cbz".to_string()),
                    meta: hentai_core::ComicMetaExportRecord {
                        title: "歧义样本".to_string(),
                        description: None,
                        published_at: None,
                        content_rating: "unknown".to_string(),
                        languages: vec![],
                        locks: Default::default(),
                    },
                    authors: vec![],
                    tags: vec![],
                    parodies: vec![],
                    characters: vec![],
                }],
            };
            let bytes = serde_json::to_vec(&payload).expect("serialize payload");

            let preview = preview_import_comic_metadata(&bytes)
                .await
                .expect("preview");
            assert_eq!(preview.would_apply, 0);
            assert_eq!(preview.skipped_ambiguous, 1);
            assert_eq!(preview.samples_ambiguous.len(), 1);
            assert_eq!(preview.samples_ambiguous[0].candidate_comic_ids.len(), 2);
        });
    });
}
