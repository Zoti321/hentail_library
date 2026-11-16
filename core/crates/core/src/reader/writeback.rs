//! First-open / refresh physical metadata writeback (page_count etc.).

use sea_orm::{DatabaseConnection, TransactionTrait};

use crate::comic::repository::find_visible_comic_by_id_in;
use crate::comic::{upsert_comics, ComicDto};
use crate::db::{connection, map_db_err};
use crate::error::HentaiError;
use crate::library::resolve_access_for_comic;
use crate::metadata_lock::merge_refresh_scan_with_existing;
use crate::resource::{parse_file_with, parsed_to_comic, ResourceAccess, ResourceKind};

use super::backend::normalize_reader_location_for_session;
use super::manager::ReaderSessionRead;

/// Reconcile physical metadata for the source used by a successful reader page-list.
pub async fn writeback_after_open(
    read: &ReaderSessionRead,
    page_count: i32,
) -> Result<(), HentaiError> {
    if page_count <= 0 {
        return Ok(());
    }
    let db = connection()?;
    let Some(existing) = find_visible_comic_by_id_in(&db, &read.comic_id).await? else {
        return Ok(());
    };
    if existing.page_count == page_count || !matches_source(read, &existing) {
        return Ok(());
    }
    let resolved = resolve_access_for_comic(&existing)?;
    reconcile(&db, resolved.as_dyn(), read, existing, page_count).await
}

pub async fn writeback_with_access(
    access: &dyn ResourceAccess,
    read: &ReaderSessionRead,
    page_count: i32,
) -> Result<(), HentaiError> {
    if page_count <= 0 {
        return Ok(());
    }
    let db = connection()?;
    let Some(existing) = find_visible_comic_by_id_in(&db, &read.comic_id).await? else {
        return Ok(());
    };
    reconcile(&db, access, read, existing, page_count).await
}

fn matches_source(read: &ReaderSessionRead, comic: &ComicDto) -> bool {
    normalize_reader_location_for_session(&comic.path) == read.path
        && comic.resource_type == read.resource_type
}

async fn reconcile(
    db: &DatabaseConnection,
    access: &dyn ResourceAccess,
    read: &ReaderSessionRead,
    existing: ComicDto,
    page_count: i32,
) -> Result<(), HentaiError> {
    if existing.page_count == page_count || !matches_source(read, &existing) {
        return Ok(());
    }
    if access.stat(&read.path)?.as_ref() != Some(&read.source_stat) {
        return Ok(());
    }
    // Resource IO precedes the transaction. Only the source identity is retained;
    // user metadata and locks must be read again when committing the aggregate.
    let parsed = match read.source_stat.kind {
        // Directory page counts belong to the opened session's list snapshot.
        ResourceKind::Dir => None,
        ResourceKind::File => parse_file_with(access, &read.path)?,
    };
    if access.stat(&read.path)?.as_ref() != Some(&read.source_stat) {
        return Ok(());
    }
    let txn = db.begin().await.map_err(map_db_err)?;
    let Some(current) = find_visible_comic_by_id_in(&txn, &read.comic_id).await? else {
        return Ok(());
    };
    if !matches_source(read, &current)
        || current.library_id != existing.library_id
        || current.resource_size != existing.resource_size
        || current.page_count == page_count
    {
        return Ok(());
    }
    let merged = match parsed {
        Some(parsed) => {
            let mut scanned = parsed_to_comic(&parsed);
            if scanned.page_count <= 0 {
                scanned.page_count = page_count;
            }
            scanned.path = current.path.clone();
            scanned.library_id = current.library_id.clone();
            merge_refresh_scan_with_existing(&scanned, &current)
        }
        None => {
            let mut comic = current;
            comic.page_count = page_count;
            comic
        }
    };
    let skipped = upsert_comics(&txn, &[merged]).await?;
    if !skipped.is_empty() {
        return Ok(());
    }
    txn.commit().await.map_err(map_db_err)?;
    crate::revision::notify_committed();
    tracing::info!(
        comic_id = read.comic_id,
        page_count,
        "comic physical metadata writeback"
    );
    Ok(())
}
