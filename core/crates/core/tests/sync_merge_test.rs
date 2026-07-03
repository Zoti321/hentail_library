use hentai_core::comic::ComicDto;
use hentai_core::sync::merge::merge_kept_scan_with_existing;

fn comic(
    id: &str,
    path: &str,
    resource_type: &str,
    title: &str,
    page_count: Option<i32>,
) -> ComicDto {
    ComicDto {
        comic_id: id.to_string(),
        path: path.to_string(),
        resource_type: resource_type.to_string(),
        title: title.to_string(),
        content_rating: "safe".to_string(),
        page_count,
        authors: vec!["作者".to_string()],
        tags: vec!["标签".to_string()],
    }
}

#[test]
fn merge_kept_preserves_user_metadata_when_source_unchanged() {
    let scanned = comic("id1", "/a/b", "zip", "扫描标题", Some(10));
    let existing = comic("id1", "/a/b", "zip", "用户标题", Some(5));
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.title, "用户标题");
    assert_eq!(merged.page_count, Some(5));
    assert_eq!(merged.authors, vec!["作者".to_string()]);
}

#[test]
fn merge_kept_updates_page_count_when_path_changes() {
    let scanned = comic("id1", "/a/c", "zip", "扫描标题", Some(10));
    let existing = comic("id1", "/a/b", "zip", "用户标题", Some(5));
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.path, "/a/c");
    assert_eq!(merged.page_count, Some(10));
}

#[test]
fn merge_kept_backfills_null_page_count() {
    let scanned = comic("id1", "/a/b", "zip", "扫描标题", Some(10));
    let existing = comic("id1", "/a/b", "zip", "用户标题", None);
    let merged = merge_kept_scan_with_existing(&scanned, &existing);
    assert_eq!(merged.page_count, Some(10));
}
