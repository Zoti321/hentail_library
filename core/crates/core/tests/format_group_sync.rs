use std::collections::HashMap;
use std::fs::File;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::sync::format_group::FormatGroup;
use hentai_core::sync::handle::create_sync_handle;
use hentai_core::sync::plan::build_scan_replace_plan;
use hentai_core::sync::scanner::{ScanContext, scan_roots};
use hentai_core::sync::writer::apply_scan_replace_plan;
use hentai_core::{connection, find_comic_by_id, init_db_at_path};
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
fn disabling_archive_format_group_removes_existing_archive_comic_on_resync() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let root = temp.path().join("library");
        std::fs::create_dir(&root).expect("mkdir root");

        let folder = root.join("image_comic");
        std::fs::create_dir(&folder).expect("mkdir comic");
        std::fs::write(folder.join("01.jpg"), b"fake-jpeg").expect("jpg");

        let cbz_path = root.join("archive.cbz");
        write_cbz(&cbz_path);

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
                &[root.clone()],
                &empty_ctx,
                &handle,
                true,
                &FormatGroup::ALL,
            )
            .expect("first scan");
            assert_eq!(first_scan.len(), 2);
            let plan = build_scan_replace_plan(&db, first_scan)
                .await
                .expect("first plan");
            apply_scan_replace_plan(&db, &plan)
                .await
                .expect("first apply");

            let archive_id = hentai_core::comic_id_from_path(&cbz_path.to_string_lossy());
            let folder_id = hentai_core::comic_id_from_path(&folder.to_string_lossy());
            assert!(
                find_comic_by_id(&archive_id)
                    .await
                    .expect("find archive")
                    .is_some()
            );
            assert!(
                find_comic_by_id(&folder_id)
                    .await
                    .expect("find folder")
                    .is_some()
            );

            let second_scan = scan_roots(
                &[root.clone()],
                &empty_ctx,
                &handle,
                true,
                &[FormatGroup::Folder],
            )
            .expect("second scan");
            assert_eq!(second_scan.len(), 1);
            assert_eq!(second_scan[0].resource_type, "dir");

            let plan = build_scan_replace_plan(&db, second_scan)
                .await
                .expect("second plan");
            assert!(plan.removed_ids.contains(&archive_id));
            apply_scan_replace_plan(&db, &plan)
                .await
                .expect("second apply");

            assert!(
                find_comic_by_id(&archive_id)
                    .await
                    .expect("find archive after")
                    .is_none()
            );
            assert!(
                find_comic_by_id(&folder_id)
                    .await
                    .expect("find folder after")
                    .is_some()
            );
        });
    });
}
