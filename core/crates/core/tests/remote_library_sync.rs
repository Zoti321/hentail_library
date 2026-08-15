use std::path::PathBuf;
use std::sync::Mutex;

use hentai_core::resource::{FakeResourceAccess, ResourceAccess};
use hentai_core::sync::format_group::FormatGroup;
use hentai_core::sync::handle::create_sync_handle;
use hentai_core::sync::plan::build_scan_replace_plan;
use hentai_core::sync::scanner::ScanContext;
use hentai_core::sync::remote::{comic_id_for_remote_location, scan_remote_lightweight, RemoteScanOutcome};
use hentai_core::{
    connection, create_remote_library, find_comic_by_id, init_db_at_path,
};
use std::collections::HashMap;
use sea_orm::{ConnectionTrait, Database, Statement};
use tempfile::TempDir;

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

fn create_fixture_db(dir: &std::path::Path) -> PathBuf {
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

fn reachable_tree() -> FakeResourceAccess {
    let mut fake = FakeResourceAccess::new();
    fake.insert_dir("https://nas.example/dav");
    fake.insert_dir("https://nas.example/dav/series");
    fake.insert_file("https://nas.example/dav/a.cbz", b"fake-cbz");
    fake.insert_file("https://nas.example/dav/b.pdf", b"%PDF-fake");
    fake.insert_file("https://nas.example/dav/notes.txt", b"ignore");
    fake.insert_file("https://nas.example/dav/series/c.epub", b"epub");
    // Image folder must not become a remote comic.
    fake.insert_dir("https://nas.example/dav/images");
    fake.insert_file("https://nas.example/dav/images/01.jpg", b"jpeg");
    fake
}

#[test]
fn remote_lightweight_scan_registers_files_by_extension_not_folders() {
    let access = reachable_tree();
    let handle = create_sync_handle();
    let outcome = scan_remote_lightweight(
        &access,
        "https://nas.example/dav",
        &ScanContext {
            existing_by_id: HashMap::new(),
            thumbnail_stats: HashMap::new(),
        },
        &handle,
        &[FormatGroup::Archive, FormatGroup::Pdf, FormatGroup::Epub],
    )
    .expect("scan");

    let RemoteScanOutcome::Scanned(items) = outcome else {
        panic!("expected reachable scan");
    };
    let types: Vec<&str> = items.iter().map(|i| i.resource_type.as_str()).collect();
    assert!(types.contains(&"cbz"));
    assert!(types.contains(&"pdf"));
    assert!(types.contains(&"epub"));
    assert!(!types.contains(&"dir"));
    assert!(!items.iter().any(|i| i.path.ends_with(".txt")));
    assert!(!items.iter().any(|i| i.path.ends_with(".jpg")));
    assert!(items.iter().all(|i| i.comic.page_count == 1));

    let cbz = items.iter().find(|i| i.resource_type == "cbz").unwrap();
    assert_eq!(
        cbz.comic.comic_id,
        comic_id_for_remote_location("https://nas.example/dav/a.cbz")
    );
}

#[test]
fn remote_format_filter_excludes_disabled_groups() {
    let access = reachable_tree();
    let handle = create_sync_handle();
    let outcome = scan_remote_lightweight(
        &access,
        "https://nas.example/dav",
        &ScanContext {
            existing_by_id: HashMap::new(),
            thumbnail_stats: HashMap::new(),
        },
        &handle,
        &[FormatGroup::Pdf],
    )
    .expect("scan");
    let RemoteScanOutcome::Scanned(items) = outcome else {
        panic!("expected scanned");
    };
    assert_eq!(items.len(), 1);
    assert_eq!(items[0].resource_type, "pdf");
}

#[test]
fn remote_unreachable_probe_does_not_surface_as_scanned() {
    let mut fake = FakeResourceAccess::new();
    fake.insert_dir("https://nas.example/dav");
    fake.set_unreachable("认证失败: 401 Unauthorized");
    let handle = create_sync_handle();
    let outcome = scan_remote_lightweight(
        &fake,
        "https://nas.example/dav",
        &ScanContext {
            existing_by_id: HashMap::new(),
            thumbnail_stats: HashMap::new(),
        },
        &handle,
        &FormatGroup::ALL,
    )
    .expect("probe");
    match outcome {
        RemoteScanOutcome::Unreachable { message } => {
            assert!(message.contains("401") || message.contains("认证"));
        }
        RemoteScanOutcome::Scanned(_) => panic!("must not scan when unreachable"),
        RemoteScanOutcome::Cancelled => panic!("must not cancel in this test"),
    }
}

#[test]
fn remote_reachable_plan_adds_and_orphans_without_deleting_on_unreachable() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let lib = create_remote_library("https://nas.example/dav", "u", false, None)
                .await
                .expect("create remote");

            let access = reachable_tree();
            let handle = create_sync_handle();
            let outcome = scan_remote_lightweight(
                &access,
                &lib.root_path,
                &ScanContext {
            existing_by_id: HashMap::new(),
            thumbnail_stats: HashMap::new(),
        },
                &handle,
                &lib.enabled_format_groups,
            )
            .expect("scan");
            let RemoteScanOutcome::Scanned(mut items) = outcome else {
                panic!("reachable");
            };
            for item in &mut items {
                item.comic.library_id = lib.library_id.clone();
            }
            let db = connection().expect("db");
            let plan = build_scan_replace_plan(&db, items, &lib.library_id)
                .await
                .expect("plan");
            hentai_core::sync::writer::apply_scan_replace_plan(&db, &plan, &lib.library_id)
                .await
                .expect("apply");

            let cbz_id = comic_id_for_remote_location("https://nas.example/dav/a.cbz");
            assert!(find_comic_by_id(&cbz_id).await.unwrap().is_some());

            // Orphan: remove a.cbz from tree, sync again → deleted.
            let mut pruned = FakeResourceAccess::new();
            pruned.insert_dir("https://nas.example/dav");
            pruned.insert_file("https://nas.example/dav/b.pdf", b"%PDF-fake");
            let outcome = scan_remote_lightweight(
                &pruned,
                &lib.root_path,
                &ScanContext {
            existing_by_id: HashMap::new(),
            thumbnail_stats: HashMap::new(),
        },
                &handle,
                &lib.enabled_format_groups,
            )
            .expect("scan2");
            let RemoteScanOutcome::Scanned(mut items) = outcome else {
                panic!("reachable2");
            };
            for item in &mut items {
                item.comic.library_id = lib.library_id.clone();
            }
            let plan = build_scan_replace_plan(&db, items, &lib.library_id)
                .await
                .expect("plan2");
            hentai_core::sync::writer::apply_scan_replace_plan(&db, &plan, &lib.library_id)
                .await
                .expect("apply2");
            assert!(find_comic_by_id(&cbz_id).await.unwrap().is_none());

            // Unreachable must not orphan-delete remaining comics.
            let pdf_id = comic_id_for_remote_location("https://nas.example/dav/b.pdf");
            assert!(find_comic_by_id(&pdf_id).await.unwrap().is_some());
            let mut down = FakeResourceAccess::new();
            down.set_unreachable("主机不可达");
            let outcome = scan_remote_lightweight(
                &down,
                &lib.root_path,
                &ScanContext {
            existing_by_id: HashMap::new(),
            thumbnail_stats: HashMap::new(),
        },
                &handle,
                &lib.enabled_format_groups,
            )
            .expect("unreachable");
            assert!(matches!(outcome, RemoteScanOutcome::Unreachable { .. }));
            assert!(find_comic_by_id(&pdf_id).await.unwrap().is_some());
        });
    });
}

#[test]
fn fake_resource_access_is_dyn_compatible() {
    let access: &dyn ResourceAccess = &reachable_tree();
    assert!(access.stat("https://nas.example/dav").unwrap().is_some());
}
