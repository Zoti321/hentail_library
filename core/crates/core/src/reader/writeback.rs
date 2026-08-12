//! First-open / refresh physical metadata writeback (page_count etc.).

use crate::comic::find_comic_by_id;
use crate::db::connection;
use crate::error::HentaiError;
use crate::library::resolve_access_for_comic;
use crate::metadata_lock::merge_refresh_scan_with_existing;
use crate::resource::{parse_file_with, parsed_to_comic, ResourceAccess};
use crate::sync::writer::upsert_comics;

/// After a successful reader page-list, reconcile DB `page_count` (and parse merge).
pub async fn writeback_after_open(
    comic_id: &str,
    page_count: i32,
) -> Result<(), HentaiError> {
    if page_count <= 0 {
        return Ok(());
    }
    let existing = match find_comic_by_id(comic_id).await? {
        Some(c) => c,
        None => return Ok(()),
    };
    if existing.page_count == page_count {
        return Ok(());
    }

    let resolved = resolve_access_for_comic(&existing)?;
    writeback_with_access(resolved.as_dyn(), &existing.comic_id, page_count).await
}

pub async fn writeback_with_access(
    access: &dyn ResourceAccess,
    comic_id: &str,
    page_count: i32,
) -> Result<(), HentaiError> {
    let existing = find_comic_by_id(comic_id)
        .await?
        .ok_or_else(|| HentaiError::validation(format!("漫画不存在: {comic_id}")))?;
    if existing.page_count == page_count {
        return Ok(());
    }

    let scanned = match parse_file_with(access, &existing.path)? {
        Some(parsed) => {
            let mut comic = parsed_to_comic(&parsed);
            if comic.page_count <= 0 {
                comic.page_count = page_count;
            }
            comic.library_id = existing.library_id.clone();
            comic
        }
        None => {
            let mut comic = existing.clone();
            comic.page_count = page_count;
            comic
        }
    };
    let merged = merge_refresh_scan_with_existing(&scanned, &existing);
    let db = connection()?;
    upsert_comics(&db, &[merged]).await?;
    tracing::info!(comic_id, page_count, "comic physical metadata writeback");
    Ok(())
}
