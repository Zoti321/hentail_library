use hentai_core::comic::{ComicDto, ComicMetaLocks};
use hentai_core::metadata_lock::{
    comic_auto_locks, merge_kept_scan_with_existing, merge_series_name,
    resolve_member_sort_order, series_auto_locks, series_name_needs_write,
};

fn comic(
    id: &str,
    path: &str,
    resource_type: &str,
    title: &str,
    page_count: i32,
) -> ComicDto {
    ComicDto {
        comic_id: id.to_string(),
        path: path.to_string(),
        resource_type: resource_type.to_string(),
        resource_size: 1024,
        created_at: 1,
        last_updated_at: 1,
        title: title.to_string(),
        content_rating: "safe".to_string(),
        page_count,
        description: None,
        published_at: None,
        last_read_time_ms: None,
        authors: vec!["作者".to_string()],
        tags: vec!["标签".to_string()],
        locks: ComicMetaLocks::default(),
        library_id: String::new(),
    }
}

#[test]
fn merge_unlocked_title_takes_scanned_value() {
    let scanned = comic("id1", "/a/b", "zip", "扫描标题", 10);
    let existing = comic("id1", "/a/b", "zip", "用户标题", 5);
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.title, "扫描标题");
    assert!(!merged.locks.title);
}

#[test]
fn merge_locked_title_preserves_existing() {
    let scanned = comic("id1", "/a/b", "zip", "扫描标题", 10);
    let mut existing = comic("id1", "/a/b", "zip", "用户标题", 5);
    existing.locks.title = true;
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.title, "用户标题");
    assert!(merged.locks.title);
}

#[test]
fn merge_kept_decodes_html_entities_in_locked_title() {
    let scanned = comic("id1", "/a/b", "zip", "扫描标题", 10);
    let mut existing = comic(
        "id1",
        "/a/b",
        "zip",
        "Fate╱Stay Night Heaven&#039;s Feel - 卷04",
        5,
    );
    existing.locks.title = true;
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.title, "Fate╱Stay Night Heaven's Feel - 卷04");
}

#[test]
fn merge_kept_updates_page_count_when_path_changes() {
    let scanned = comic("id1", "/a/c", "zip", "扫描标题", 10);
    let existing = comic("id1", "/a/b", "zip", "用户标题", 5);
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.path, "/a/c");
    assert_eq!(merged.page_count, 10);
}

#[test]
fn merge_kept_preserves_existing_page_count_when_source_unchanged() {
    let scanned = comic("id1", "/a/b", "zip", "扫描标题", 10);
    let existing = comic("id1", "/a/b", "zip", "用户标题", 5);
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.page_count, 5);
}

#[test]
fn merge_unlocked_description_takes_scanned_when_present() {
    let mut scanned = comic("id1", "/a/b", "zip", "扫描标题", 5);
    scanned.description = Some("扫描概要".to_string());
    let mut existing = comic("id1", "/a/b", "zip", "用户标题", 5);
    existing.description = Some("用户概要".to_string());
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.description.as_deref(), Some("扫描概要"));
}

#[test]
fn merge_locked_description_preserves_existing() {
    let mut scanned = comic("id1", "/a/b", "zip", "扫描标题", 5);
    scanned.description = Some("扫描概要".to_string());
    let mut existing = comic("id1", "/a/b", "zip", "用户标题", 5);
    existing.description = Some("用户概要".to_string());
    existing.locks.description = true;
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.description.as_deref(), Some("用户概要"));
}

#[test]
fn merge_unlocked_description_keeps_existing_when_scan_empty() {
    let mut scanned = comic("id1", "/a/b", "zip", "扫描标题", 5);
    scanned.description = None;
    let mut existing = comic("id1", "/a/b", "zip", "用户标题", 5);
    existing.description = Some("用户概要".to_string());
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.description.as_deref(), Some("用户概要"));
}

#[test]
fn merge_unlocked_backfills_null_description_from_scan() {
    let mut scanned = comic("id1", "/a/b", "zip", "扫描标题", 5);
    scanned.description = Some("扫描概要".to_string());
    let existing = comic("id1", "/a/b", "zip", "用户标题", 5);
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.description.as_deref(), Some("扫描概要"));
}

#[test]
fn merge_unlocked_authors_keep_existing_when_scan_empty() {
    let mut scanned = comic("id1", "/a/b", "zip", "扫描标题", 5);
    scanned.authors = vec![];
    let existing = comic("id1", "/a/b", "zip", "用户标题", 5);
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.authors, vec!["作者".to_string()]);
}

#[test]
fn merge_unlocked_authors_replace_when_scan_non_empty() {
    let mut scanned = comic("id1", "/a/b", "zip", "扫描标题", 5);
    scanned.authors = vec!["扫描作者".to_string()];
    let existing = comic("id1", "/a/b", "zip", "用户标题", 5);
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.authors, vec!["扫描作者".to_string()]);
}

#[test]
fn merge_unlocked_tags_keep_existing_when_scan_empty() {
    let mut scanned = comic("id1", "/a/b", "zip", "扫描标题", 5);
    scanned.tags = vec![];
    let existing = comic("id1", "/a/b", "zip", "用户标题", 5);
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.tags, vec!["标签".to_string()]);
}

#[test]
fn merge_unlocked_content_rating_ignores_unknown_scan() {
    let mut scanned = comic("id1", "/a/b", "zip", "扫描标题", 5);
    scanned.content_rating = "unknown".to_string();
    let mut existing = comic("id1", "/a/b", "zip", "用户标题", 5);
    existing.content_rating = "r18".to_string();
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.content_rating, "r18");
}

#[test]
fn merge_kept_always_overwrites_resource_size_from_scan() {
    let mut scanned = comic("id1", "/a/b", "zip", "扫描标题", 5);
    scanned.resource_size = 4096;
    let mut existing = comic("id1", "/a/b", "zip", "用户标题", 5);
    existing.resource_size = 0;
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.resource_size, 4096);
}

#[test]
fn series_name_unlocked_takes_folder_name() {
    assert_eq!(
        merge_series_name(false, "旧名", "文件夹名"),
        "文件夹名"
    );
    assert!(series_name_needs_write(false, "旧名", "文件夹名"));
}

#[test]
fn series_name_locked_preserves_existing() {
    assert_eq!(
        merge_series_name(true, "用户名", "文件夹名"),
        "用户名"
    );
    assert!(!series_name_needs_write(true, "用户名", "文件夹名"));
}

#[test]
fn series_name_unlocked_empty_folder_keeps_existing() {
    assert_eq!(merge_series_name(false, "旧名", "  "), "旧名");
    assert!(!series_name_needs_write(false, "旧名", "  "));
}

#[test]
fn series_name_needs_write_false_when_unchanged() {
    assert!(!series_name_needs_write(false, "同名", "同名"));
}

#[test]
fn member_sort_order_locked_keeps_value() {
    assert_eq!(
        resolve_member_sort_order(Some(3.5), 1.0),
        (3.5, true)
    );
}

#[test]
fn member_sort_order_unlocked_uses_natural_index() {
    assert_eq!(resolve_member_sort_order(None, 2.0), (2.0, false));
}

#[test]
fn comic_auto_locks_only_written_fields() {
    let locks = comic_auto_locks(true, false, false, true, false, false);
    assert!(locks.title);
    assert!(!locks.description);
    assert!(locks.content_rating);
    assert!(locks.any());
}

#[test]
fn series_auto_locks_includes_clear_total_count() {
    let locks = series_auto_locks(false, false, true);
    assert!(locks.total_count);
    assert!(!locks.name);
}
