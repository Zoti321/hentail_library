mod common;

use std::collections::HashMap;
use std::fs::File;
use std::io::Write;

use hentai_core::probe::{
    diff_enumerated, load_snapshot_map, probe_library, rebuild_snapshot_from_scan_items,
};
use hentai_core::resource::FakeResourceAccess;
use hentai_core::sync::format_group::FormatGroup;
use hentai_core::sync::handle::create_sync_handle;
use hentai_core::sync::scanner::{enumerate_resources_with, ScanItem};
use hentai_core::{
    comic::ComicDto, connection, create_local_library, init_db_at_path, record_library_sync_success,
};
use tempfile::TempDir;
use zip::write::SimpleFileOptions;
use zip::ZipWriter;

#[test]
fn probe_diff_counts_added_changed_removed_with_fake_access() {
    let mut fake = FakeResourceAccess::new();
    fake.insert_dir("/lib");
    fake.insert_file("/lib/a.cbz", b"fake-cbz");
    fake.insert_file("/lib/b.cbz", b"fake-cbz-2");
    fake.set_modified_ms("/lib/a.cbz", 200);
    fake.insert_file("/lib/new.cbz", b"new");

    let handle = create_sync_handle();
    let enumerated = enumerate_resources_with(
        &fake,
        &["/lib".to_string()],
        &[],
        &handle,
        &[FormatGroup::Archive],
        hentai_core::normalize_path_for_key,
    )
    .expect("enumerate");

    let mut snapshot = HashMap::new();
    snapshot.insert(
        hentai_core::normalize_path_for_key("/lib/a.cbz"),
        (100_i64, 10_i64, "cbz".to_string()),
    );
    snapshot.insert(
        hentai_core::normalize_path_for_key("/lib/b.cbz"),
        (100_i64, 10_i64, "cbz".to_string()),
    );

    let diff = diff_enumerated(&snapshot, &enumerated);
    assert_eq!(diff.added, 1);
    assert!(diff.changed >= 1, "expected at least one changed resource");
    assert_eq!(diff.removed, 0);
}

#[test]
fn probe_diff_counts_removed_when_snapshot_entry_missing_from_enumeration() {
    let mut fake = FakeResourceAccess::new();
    fake.insert_dir("/lib");
    fake.insert_file("/lib/a.cbz", b"fake-cbz");

    let handle = create_sync_handle();
    let enumerated = enumerate_resources_with(
        &fake,
        &["/lib".to_string()],
        &[],
        &handle,
        &[FormatGroup::Archive],
        hentai_core::normalize_path_for_key,
    )
    .expect("enumerate");

    let mut snapshot = HashMap::new();
    snapshot.insert(
        hentai_core::normalize_path_for_key("/lib/a.cbz"),
        (100_i64, 10_i64, "cbz".to_string()),
    );
    snapshot.insert(
        hentai_core::normalize_path_for_key("/lib/removed.cbz"),
        (100_i64, 10_i64, "cbz".to_string()),
    );

    let diff = diff_enumerated(&snapshot, &enumerated);
    assert_eq!(diff.removed, 1);
    assert_eq!(diff.added, 0);
}

#[test]
fn enumerate_respects_enabled_format_groups() {
    let mut fake = FakeResourceAccess::new();
    fake.insert_dir("/lib");
    fake.insert_file("/lib/a.cbz", b"archive");
    fake.insert_file("/lib/doc.pdf", b"pdf");

    let handle = create_sync_handle();
    let enumerated = enumerate_resources_with(
        &fake,
        &["/lib".to_string()],
        &[],
        &handle,
        &[FormatGroup::Archive],
        hentai_core::normalize_path_for_key,
    )
    .expect("enumerate");

    let keys: Vec<String> = enumerated.iter().map(|e| e.location_key.clone()).collect();
    assert!(keys
        .iter()
        .any(|k| k.ends_with("a.cbz") || k.contains("a.cbz")));
    assert!(!keys.iter().any(|k| k.contains("doc.pdf")));
}

#[test]
fn enumerate_excludes_nested_library_root() {
    let mut fake = FakeResourceAccess::new();
    fake.insert_dir("/parent");
    fake.insert_dir("/parent/nested");
    fake.insert_file("/parent/root.cbz", b"root");
    fake.insert_file("/parent/nested/inner.cbz", b"inner");

    let handle = create_sync_handle();
    let enumerated = enumerate_resources_with(
        &fake,
        &["/parent".to_string()],
        &["/parent/nested".to_string()],
        &handle,
        &[FormatGroup::Archive],
        hentai_core::normalize_path_for_key,
    )
    .expect("enumerate");

    let keys: Vec<String> = enumerated.iter().map(|e| e.location_key.clone()).collect();
    assert!(keys.iter().any(|k| k.contains("root.cbz")));
    assert!(!keys.iter().any(|k| k.contains("inner.cbz")));
}

#[test]
fn probe_leaves_snapshot_unchanged_when_disk_changes_without_rebuild() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let root = temp.path().join("library");
        std::fs::create_dir_all(&root).expect("mkdir");
        let cbz = root.join("a.cbz");
        write_minimal_cbz(&cbz);

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(temp.path().join("snapshot.sqlite"))
                .await
                .expect("init db");
            let library = create_local_library(&root.to_string_lossy(), None)
                .await
                .expect("create library");
            let db = connection().expect("db");
            let path = cbz.to_string_lossy().to_string();
            let scan_items = vec![scan_item(&path, "cbz", 100, 10, &library.library_id)];
            rebuild_snapshot_from_scan_items(&db, &library.library_id, &library, &scan_items)
                .await
                .expect("rebuild");

            let before = load_snapshot_map(&db, &library.library_id)
                .await
                .expect("snapshot before");
            assert_eq!(before.len(), 1);

            std::fs::write(&cbz, b"changed-content").expect("touch file");
            let result = probe_library(&library.library_id, None)
                .await
                .expect("probe");
            assert!(result.changed_count >= 1);

            let after = load_snapshot_map(&db, &library.library_id)
                .await
                .expect("snapshot after");
            assert_eq!(after, before);
        });
    });
}

#[test]
fn probe_baseline_missing_when_no_snapshot_rows() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let root = temp.path().join("library");
        std::fs::create_dir_all(&root).expect("mkdir");
        write_minimal_cbz(&root.join("a.cbz"));

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(temp.path().join("baseline.sqlite"))
                .await
                .expect("init db");
            let library = create_local_library(&root.to_string_lossy(), None)
                .await
                .expect("create library");
            let result = probe_library(&library.library_id, None)
                .await
                .expect("probe");
            assert!(result.baseline_missing);
            assert!(result.added_count > 0);
        });
    });
}

#[test]
fn sync_success_rebuilds_snapshot_and_clears_pending_diff() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let root = temp.path().join("library");
        std::fs::create_dir_all(&root).expect("mkdir");
        write_minimal_cbz(&root.join("a.cbz"));

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(temp.path().join("sync.sqlite"))
                .await
                .expect("init db");
            let library = create_local_library(&root.to_string_lossy(), None)
                .await
                .expect("create library");
            let db = connection().expect("db");
            let path = root.join("a.cbz").to_string_lossy().to_string();
            let scan_items = vec![scan_item(&path, "cbz", 100, 10, &library.library_id)];
            rebuild_snapshot_from_scan_items(&db, &library.library_id, &library, &scan_items)
                .await
                .expect("rebuild");
            record_library_sync_success(&library.library_id)
                .await
                .expect("record success");

            let snapshot = load_snapshot_map(&db, &library.library_id)
                .await
                .expect("snapshot");
            assert_eq!(snapshot.len(), 1);

            let result = probe_library(&library.library_id, None)
                .await
                .expect("probe");
            assert!(!result.baseline_missing);
            assert_eq!(result.added_count, 0);
            assert_eq!(result.changed_count, 0);
        });
    });
}

fn write_minimal_cbz(path: &std::path::Path) {
    let file = File::create(path).expect("create");
    let mut zip = ZipWriter::new(file);
    zip.start_file("01.jpg", SimpleFileOptions::default())
        .expect("start");
    zip.write_all(b"fake-jpeg").expect("write");
    zip.finish().expect("finish");
}

fn scan_item(
    path: &str,
    resource_type: &str,
    modified: i64,
    size: i64,
    library_id: &str,
) -> ScanItem {
    ScanItem {
        path: path.to_string(),
        resource_type: resource_type.to_string(),
        comic: ComicDto {
            comic_id: hentai_core::comic_id_from_path(path),
            path: path.to_string(),
            resource_type: resource_type.to_string(),
            resource_size: size,
            created_at: modified,
            last_updated_at: modified,
            title: path.to_string(),
            content_rating: "unknown".to_string(),
            page_count: 1,
            description: None,
            published_at: None,
            last_read_time_ms: None,
            authors: vec![],
            tags: vec![],
            languages: vec![],
            parodies: vec![],
            characters: vec![],
            locks: Default::default(),
            library_id: library_id.to_string(),
        },
    }
}
