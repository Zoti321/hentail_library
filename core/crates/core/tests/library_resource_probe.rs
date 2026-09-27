mod common;

use std::collections::HashMap;
use std::fs::File;
use std::io::Write;

use hentai_core::probe::{load_snapshot_map, probe_library, rebuild_snapshot_from_scan_items};
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

    let mut added = 0;
    let mut changed = 0;
    let mut removed = 0;
    let mut seen = HashMap::new();
    for item in &enumerated {
        seen.insert(item.location_key.clone(), (item.modified_ms, item.size));
        match snapshot.get(&item.location_key) {
            None => added += 1,
            Some((modified_ms, size, _)) if *modified_ms != item.modified_ms || *size != item.size => {
                changed += 1
            }
            Some(_) => {}
        }
    }
    for key in snapshot.keys() {
        if !seen.contains_key(key) {
            removed += 1;
        }
    }
    assert_eq!(added, 1);
    assert!(changed >= 1, "expected at least one changed resource");
    assert_eq!(removed, 0);
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
