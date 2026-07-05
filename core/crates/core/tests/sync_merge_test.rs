use hentai_core::comic::ComicDto;
use hentai_core::sync::merge::merge_kept_scan_with_existing;

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
        authors: vec!["作者".to_string()],
        tags: vec!["标签".to_string()],
    }
}

#[test]
fn merge_kept_preserves_user_metadata_when_source_unchanged() {
    let scanned = comic("id1", "/a/b", "zip", "扫描标题", 10);
    let existing = comic("id1", "/a/b", "zip", "用户标题", 5);
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.title, "用户标题");
    assert_eq!(merged.page_count, 5);
    assert_eq!(merged.authors, vec!["作者".to_string()]);
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
fn merge_kept_preserves_description_when_set() {
    let mut scanned = comic("id1", "/a/b", "zip", "扫描标题", 5);
    scanned.description = Some("扫描概要".to_string());
    let mut existing = comic("id1", "/a/b", "zip", "用户标题", 5);
    existing.description = Some("用户概要".to_string());
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.description.as_deref(), Some("用户概要"));
}

#[test]
fn merge_kept_backfills_null_description_from_scan() {
    let mut scanned = comic("id1", "/a/b", "zip", "扫描标题", 5);
    scanned.description = Some("扫描概要".to_string());
    let existing = comic("id1", "/a/b", "zip", "用户标题", 5);
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.description.as_deref(), Some("扫描概要"));
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
