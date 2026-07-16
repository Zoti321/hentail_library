use crate::comic::ComicDto;
use crate::util::decode_basic_html_entities;

fn merge_optional_text(existing: &Option<String>, scanned: &Option<String>) -> Option<String> {
    if existing.is_some() {
        existing.clone()
    } else {
        scanned.clone()
    }
}

fn merge_optional_ms(existing: Option<i64>, scanned: Option<i64>) -> Option<i64> {
    if existing.is_some() {
        existing
    } else {
        scanned
    }
}

/// 保留漫画扫描合并：更新物理字段，并按规则合并元数据。
pub fn merge_kept_scan_with_existing(scanned: &ComicDto, existing: &ComicDto) -> ComicDto {
    let source_changed =
        existing.path != scanned.path || existing.resource_type != scanned.resource_type;
    let page_count = if source_changed {
        scanned.page_count
    } else {
        existing.page_count
    };
    ComicDto {
        comic_id: existing.comic_id.clone(),
        path: scanned.path.clone(),
        resource_type: scanned.resource_type.clone(),
        resource_size: scanned.resource_size,
        created_at: existing.created_at,
        last_updated_at: existing.last_updated_at,
        // 保留用户/既有标题，但幂等清洗 HTML 实体（存量脏标题靠 sync 修好）。
        title: decode_basic_html_entities(&existing.title),
        content_rating: existing.content_rating.clone(),
        page_count,
        description: merge_optional_text(&existing.description, &scanned.description),
        published_at: merge_optional_ms(existing.published_at, scanned.published_at),
        authors: existing.authors.clone(),
        tags: existing.tags.clone(),
    }
}
