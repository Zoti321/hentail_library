mod common;

use hentai_core::{
    create_local_library, export_comic_metadata, init_db_at_path, set_current_library_id,
    ExportComicMetadataOptions, MetadataBackupPayload, SCHEMA_VERSION,
};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;

async fn seed_export_fixture(db: &impl ConnectionTrait, library_id: &str) {
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
        "INSERT INTO comic_meta (comic_id, title, title_sort_key, content_rating, page_count, description, \
         published_at, title_locked, description_locked, published_at_locked, content_rating_locked, \
         authors_locked, tags_locked, languages, languages_locked, parodies_locked, characters_locked) \
         VALUES ('c1', '导出标题', '导出标题', 'safe', 42, '概要', 1_700_000_000_000, \
         1, 0, 0, 1, 0, 1, '[\"Chinese\"]', 1, 0, 0)"
            .to_string(),
    ))
    .await
    .expect("seed meta");

    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO tags (name) VALUES ('冒险'), ('孤立标签'); \
         INSERT INTO authors (name) VALUES ('作者A'); \
         INSERT INTO parodies (name) VALUES ('原神'); \
         INSERT INTO characters (name) VALUES ('角色A'); \
         INSERT INTO comic_tags (comic_id, tag_name) VALUES ('c1', '冒险'); \
         INSERT INTO comic_authors (comic_id, author_name) VALUES ('c1', '作者A'); \
         INSERT INTO comic_parodies (comic_id, parody_name) VALUES ('c1', '原神'); \
         INSERT INTO comic_characters (comic_id, character_name) VALUES ('c1', '角色A')"
            .to_string(),
    ))
    .await
    .expect("seed facets");
}

#[test]
fn export_comic_metadata_emits_schema_v1_json() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("export.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let lib = create_local_library("E:/lib", None).await.expect("library");
            set_current_library_id(Some(&lib.library_id))
                .await
                .expect("current");
            let db = hentai_core::connection().expect("connection");
            seed_export_fixture(&db, &lib.library_id).await;

            let bytes = export_comic_metadata(ExportComicMetadataOptions {
                library_id: None,
                include_orphan_facets: true,
            })
            .await
            .expect("export");

            let payload: MetadataBackupPayload =
                serde_json::from_slice(&bytes).expect("parse json");
            assert_eq!(payload.schema_version, SCHEMA_VERSION);
            assert!(payload.options.include_orphan_facets);
            assert_eq!(payload.comics.len(), 1);

            let comic = &payload.comics[0];
            assert_eq!(comic.comic_id, "c1");
            assert_eq!(comic.path, "E:/lib/series/a.cbz");
            assert_eq!(comic.library_id, lib.library_id);
            assert_eq!(comic.relative_path.as_deref(), Some("series/a.cbz"));
            assert_eq!(comic.meta.title, "导出标题");
            assert_eq!(comic.meta.description.as_deref(), Some("概要"));
            assert_eq!(comic.meta.content_rating, "safe");
            assert_eq!(comic.meta.languages, vec!["Chinese".to_string()]);
            assert!(comic.meta.locks.title);
            assert!(comic.meta.locks.content_rating);
            assert!(comic.meta.locks.tags);
            assert!(comic.meta.locks.languages);
            assert_eq!(comic.tags, vec!["冒险".to_string()]);
            assert_eq!(comic.authors, vec!["作者A".to_string()]);
            assert_eq!(comic.parodies, vec!["原神".to_string()]);
            assert_eq!(comic.characters, vec!["角色A".to_string()]);
            assert_eq!(payload.orphan_facets.tags, vec!["孤立标签".to_string()]);

            let json = String::from_utf8(bytes).expect("utf8");
            assert!(!json.contains("page_count"));
            assert!(!json.contains("thumbnail"));
        });
    });
}

#[test]
fn export_comic_metadata_respects_library_filter() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("export_filter.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let lib_a = create_local_library("E:/lib-a", None)
                .await
                .expect("library a");
            let lib_b = create_local_library("E:/lib-b", None)
                .await
                .expect("library b");
            let db = hentai_core::connection().expect("connection");
            seed_export_fixture(&db, &lib_a.library_id).await;
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at, library_id) \
                 VALUES ('c2', 'E:/lib-b/other.cbz', 'cbz', 1, 1, 1, ?)",
                [sea_orm::Value::String(Some(Box::new(
                    lib_b.library_id.clone(),
                )))],
            ))
            .await
            .expect("seed second comic");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_meta (comic_id, title, title_sort_key, content_rating, page_count) \
                 VALUES ('c2', 'B库', 'B库', 'unknown', 1)"
                    .to_string(),
            ))
            .await
            .expect("seed second meta");

            let bytes = export_comic_metadata(ExportComicMetadataOptions {
                library_id: Some(lib_a.library_id.clone()),
                include_orphan_facets: false,
            })
            .await
            .expect("export");
            let payload: MetadataBackupPayload =
                serde_json::from_slice(&bytes).expect("parse json");
            assert_eq!(payload.comics.len(), 1);
            assert_eq!(payload.comics[0].comic_id, "c1");
            assert_eq!(payload.options.library_id.as_deref(), Some(lib_a.library_id.as_str()));
        });
    });
}
