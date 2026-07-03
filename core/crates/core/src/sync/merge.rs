use crate::comic::ComicDto;

/// 保留漫画扫描合并：更新 path/type，并按规则合并 page_count。
pub fn merge_kept_scan_with_existing(scanned: &ComicDto, existing: &ComicDto) -> ComicDto {
    let source_changed =
        existing.path != scanned.path || existing.resource_type != scanned.resource_type;
    let page_count = if source_changed {
        scanned.page_count
    } else if existing.page_count.is_none() {
        scanned.page_count
    } else {
        existing.page_count
    };
    ComicDto {
        comic_id: existing.comic_id.clone(),
        path: scanned.path.clone(),
        resource_type: scanned.resource_type.clone(),
        title: existing.title.clone(),
        content_rating: existing.content_rating.clone(),
        page_count,
        authors: existing.authors.clone(),
        tags: existing.tags.clone(),
    }
}
