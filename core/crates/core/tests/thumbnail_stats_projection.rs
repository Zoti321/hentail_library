#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

mod common;

use hentai_core::sync::plan::load_thumbnail_stats;
use hentai_core::{connection, init_db_at_path};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;

/// Fingerprint stats must work from projection columns even when rows hold large BLOBs.
#[test]
fn load_thumbnail_stats_reads_fingerprints_without_depending_on_blob_content() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("temp");
        let db_path = temp.path().join("thumb-stats.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            for id in ["c1", "c3"] {
                db.execute(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    format!(
                        "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
                         VALUES ('{id}', '/tmp/{id}.cbz', 'cbz', 1, 1, 1)"
                    ),
                ))
                .await
                .expect("seed comic");
            }
            // Large-ish BLOB so a full-row scan would be expensive; stats must still work.
            let blob_hex = "FF".repeat(64 * 1024);
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "INSERT INTO comic_thumbnails \
                     (comic_id, thumbnail, updated_at, source_modified_ms, source_size, is_user_set) \
                     VALUES ('c1', X'{blob_hex}', 1, 100, 200, 0), \
                            ('c3', X'{blob_hex}', 1, 300, 400, 0)"
                ),
            ))
            .await
            .expect("seed thumbnails");

            let map = load_thumbnail_stats(&db).await.expect("stats");
            assert_eq!(map.len(), 2);
            assert_eq!(map.get("c1"), Some(&(100, 200)));
            assert_eq!(map.get("c3"), Some(&(300, 400)));
        });
    });
}
