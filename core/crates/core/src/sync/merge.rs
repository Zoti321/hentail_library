use crate::comic::{ComicDto, ComicMetaLocks};
use crate::util::decode_basic_html_entities;

fn scanned_text_present(value: &str) -> bool {
    !value.trim().is_empty()
}

fn scanned_optional_text_present(value: &Option<String>) -> bool {
    value
        .as_ref()
        .map(|s| scanned_text_present(s))
        .unwrap_or(false)
}

fn merge_title(locked: bool, existing: &str, scanned: &str) -> String {
    let raw = if locked || !scanned_text_present(scanned) {
        existing
    } else {
        scanned
    };
    decode_basic_html_entities(raw)
}

fn merge_optional_text(
    locked: bool,
    existing: &Option<String>,
    scanned: &Option<String>,
) -> Option<String> {
    if locked || !scanned_optional_text_present(scanned) {
        existing.clone()
    } else {
        scanned.clone()
    }
}

fn merge_optional_ms(locked: bool, existing: Option<i64>, scanned: Option<i64>) -> Option<i64> {
    if locked || scanned.is_none() {
        existing
    } else {
        scanned
    }
}

fn merge_content_rating(locked: bool, existing: &str, scanned: &str) -> String {
    // Scan currently emits `unknown` with no stronger signal; never clobber on that alone.
    if locked || scanned.trim().is_empty() || scanned == "unknown" {
        existing.to_string()
    } else {
        scanned.to_string()
    }
}

fn merge_list(locked: bool, existing: &[String], scanned: &[String]) -> Vec<String> {
    if locked || scanned.is_empty() {
        existing.to_vec()
    } else {
        scanned.to_vec()
    }
}

/// 保留漫画扫描合并：更新物理字段，并按字段锁合并元数据。
///
/// - 已锁定：保留库内值
/// - 未锁定且扫描有值：用扫描结果覆盖
/// - 未锁定且扫描空/缺：保留库内值（不清除）
pub fn merge_kept_scan_with_existing(scanned: &ComicDto, existing: &ComicDto) -> ComicDto {
    let source_changed =
        existing.path != scanned.path || existing.resource_type != scanned.resource_type;
    let page_count = if source_changed {
        scanned.page_count
    } else {
        existing.page_count
    };
    let locks = existing.locks.clone();
    ComicDto {
        comic_id: existing.comic_id.clone(),
        path: scanned.path.clone(),
        resource_type: scanned.resource_type.clone(),
        resource_size: scanned.resource_size,
        created_at: existing.created_at,
        last_updated_at: existing.last_updated_at,
        title: merge_title(locks.title, &existing.title, &scanned.title),
        content_rating: merge_content_rating(
            locks.content_rating,
            &existing.content_rating,
            &scanned.content_rating,
        ),
        page_count,
        description: merge_optional_text(
            locks.description,
            &existing.description,
            &scanned.description,
        ),
        published_at: merge_optional_ms(
            locks.published_at,
            existing.published_at,
            scanned.published_at,
        ),
        last_read_time_ms: existing.last_read_time_ms.or(scanned.last_read_time_ms),
        authors: merge_list(locks.authors, &existing.authors, &scanned.authors),
        tags: merge_list(locks.tags, &existing.tags, &scanned.tags),
        locks: ComicMetaLocks {
            title: locks.title,
            description: locks.description,
            published_at: locks.published_at,
            content_rating: locks.content_rating,
            authors: locks.authors,
            tags: locks.tags,
        },
    }
}
