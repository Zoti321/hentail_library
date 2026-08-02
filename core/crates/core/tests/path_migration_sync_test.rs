use std::collections::HashMap;
use std::fs::File;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::comic::UpdateComicUserMetaDto;
use hentai_core::sync::format_group::FormatGroup;
use hentai_core::sync::handle::create_sync_handle;
use hentai_core::sync::plan::build_scan_replace_plan;
use hentai_core::sync::scanner::{ScanContext, scan_roots};
use hentai_core::sync::writer::apply_scan_replace_plan;
use hentai_core::{
    comic_id_from_path, connection, find_comic_by_id, get_reading_by_comic_id, init_db_at_path,
    record_reading, update_comic_user_meta, ReadingHistoryDto,
};
use sea_orm::{ConnectionTrait, Database, Statement};
use tempfile::TempDir;
use zip::write::SimpleFileOptions;
use zip::ZipWriter;

static DB_INIT_LOCK: Mutex<()> = Mutex::new(());

fn with_global_db(test: impl FnOnce()) {
    let _guard = DB_INIT_LOCK
        .lock()
        .expect("global db tests must run serially");
    test();
}

fn fixture_sql() -> String {
    std::fs::read_to_string(
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/fixtures/drift_v2.sql"),
    )
    .expect("read drift_v2.sql")
}

fn create_fixture_db(dir: &Path) -> PathBuf {
    let db_path = dir.join("fixture.sqlite");
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        let conn = Database::connect(format!(
            "sqlite://{}?mode=rwc",
            db_path.to_string_lossy().replace('\\', "/")
        ))
        .await
        .expect("connect");
        for stmt in fixture_sql().split(';') {
            let sql = stmt.trim();
            if sql.is_empty() || sql.starts_with("--") {
                continue;
            }
            conn.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                sql.to_string(),
            ))
            .await
            .expect("execute sql");
        }
    });
    db_path
}

fn write_cbz(path: &Path) {
    let file = File::create(path).expect("create");
    let mut zip = ZipWriter::new(file);
    zip.start_file("01.jpg", SimpleFileOptions::default())
        .expect("start");
    zip.write_all(b"fake-jpeg").expect("write");
    zip.finish().expect("finish");
}

#[test]
fn rename_cbz_migrates_user_metadata_and_reading_history() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let root = temp.path().join("library");
        std::fs::create_dir(&root).expect("mkdir root");

        let old_path = root.join("volume.cbz");
        write_cbz(&old_path);
        let old_id = comic_id_from_path(&old_path.to_string_lossy());

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            let handle = create_sync_handle();
            let empty_ctx = ScanContext {
                existing_by_id: HashMap::new(),
                thumbnail_stats: HashMap::new(),
            };

            let first_scan = scan_roots(
                std::slice::from_ref(&root),
                &empty_ctx,
                &handle,
                true,
                &FormatGroup::ALL,
            )
            .expect("first scan");
            let plan = build_scan_replace_plan(&db, first_scan)
                .await
                .expect("first plan");
            apply_scan_replace_plan(&db, &plan)
                .await
                .expect("first apply");

            update_comic_user_meta(
                &old_id,
                UpdateComicUserMetaDto {
                    title: Some("用户标题".to_string()),
                    tags: Some(vec!["标签A".to_string()]),
                    ..Default::default()
                },
            )
            .await
            .expect("update meta");

            record_reading(&ReadingHistoryDto {
                comic_id: old_id.clone(),
                title: "用户标题".to_string(),
                last_read_time_ms: 42,
                page_index: Some(3),
            })
            .await
            .expect("record reading");

            let new_path = root.join("renamed.cbz");
            std::fs::rename(&old_path, &new_path).expect("rename");
            let new_id = comic_id_from_path(&new_path.to_string_lossy());

            let second_scan = scan_roots(
                std::slice::from_ref(&root),
                &empty_ctx,
                &handle,
                true,
                &FormatGroup::ALL,
            )
            .expect("second scan");
            let plan = build_scan_replace_plan(&db, second_scan)
                .await
                .expect("second plan");

            assert_eq!(plan.migrated_count, 1);
            assert!(plan.removed_ids.is_empty());
            assert_eq!(plan.added_count, 0);
            assert_eq!(plan.migrations.len(), 1);
            assert_eq!(plan.migrations[0].from_comic_id, old_id);
            assert_eq!(plan.migrations[0].to_comic.comic_id, new_id);

            apply_scan_replace_plan(&db, &plan)
                .await
                .expect("second apply");

            assert!(
                find_comic_by_id(&old_id)
                    .await
                    .expect("find old")
                    .is_none()
            );
            let migrated = find_comic_by_id(&new_id)
                .await
                .expect("find new")
                .expect("new comic");
            assert_eq!(migrated.path, new_path.to_string_lossy());
            assert_eq!(migrated.title, "用户标题");
            assert_eq!(migrated.tags, vec!["标签A".to_string()]);

            let history = get_reading_by_comic_id(&new_id)
                .await
                .expect("history")
                .expect("reading history");
            assert_eq!(history.page_index, Some(3));
            assert_eq!(history.last_read_time_ms, 42);
        });
    });
}

#[test]
fn ambiguous_same_fingerprint_moves_do_not_migrate() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let root = temp.path().join("library");
        std::fs::create_dir(&root).expect("mkdir root");

        let first_path = root.join("a.cbz");
        let second_path = root.join("b.cbz");
        write_cbz(&first_path);
        write_cbz(&second_path);
        let first_id = comic_id_from_path(&first_path.to_string_lossy());
        let second_id = comic_id_from_path(&second_path.to_string_lossy());

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            let handle = create_sync_handle();
            let empty_ctx = ScanContext {
                existing_by_id: HashMap::new(),
                thumbnail_stats: HashMap::new(),
            };

            let first_scan = scan_roots(
                std::slice::from_ref(&root),
                &empty_ctx,
                &handle,
                true,
                &FormatGroup::ALL,
            )
            .expect("first scan");
            apply_scan_replace_plan(
                &db,
                &build_scan_replace_plan(&db, first_scan)
                    .await
                    .expect("first plan"),
            )
            .await
            .expect("first apply");

            update_comic_user_meta(
                &first_id,
                UpdateComicUserMetaDto {
                    title: Some("保留A".to_string()),
                    ..Default::default()
                },
            )
            .await
            .expect("update first");
            update_comic_user_meta(
                &second_id,
                UpdateComicUserMetaDto {
                    title: Some("保留B".to_string()),
                    ..Default::default()
                },
            )
            .await
            .expect("update second");

            std::fs::rename(&first_path, root.join("moved_a.cbz")).expect("rename a");
            std::fs::rename(&second_path, root.join("moved_b.cbz")).expect("rename b");

            let second_scan = scan_roots(
                std::slice::from_ref(&root),
                &empty_ctx,
                &handle,
                true,
                &FormatGroup::ALL,
            )
            .expect("second scan");
            let plan = build_scan_replace_plan(&db, second_scan)
                .await
                .expect("second plan");

            assert_eq!(plan.migrated_count, 0);
            assert_eq!(plan.removed_ids.len(), 2);
            assert_eq!(plan.added_count, 2);
            apply_scan_replace_plan(&db, &plan)
                .await
                .expect("second apply");

            assert!(
                find_comic_by_id(&first_id)
                    .await
                    .expect("find old first")
                    .is_none()
            );
            assert!(
                find_comic_by_id(&second_id)
                    .await
                    .expect("find old second")
                    .is_none()
            );
        });
    });
}
