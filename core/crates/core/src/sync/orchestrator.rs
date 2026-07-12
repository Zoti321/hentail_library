use std::path::PathBuf;

use crate::db::connection;
use crate::error::HentaiError;
use crate::reader::clear_reader_sessions;

use super::dto::{
    LibrarySyncCountsDto, SyncLibraryPhaseDto, SyncLibraryProgressDto, SyncLibraryRouteDto,
};
use super::handle::SyncHandle;
use super::parser::normalize_roots;
use super::plan::{
    build_scan_replace_plan, count_all_comic_ids, load_existing_comics_map, load_saved_paths,
    load_thumbnail_stats,
};
use super::scanner::{ScanContext, scan_roots};
use super::writer::{apply_scan_replace_plan, clear_all_comics};
use crate::thumbnail::enqueue_thumbnails_low;

fn return_if_cancelled(handle: &SyncHandle, phase: &str) -> bool {
    if handle.is_cancelled() {
        tracing::debug!(phase, "sync cancelled");
        true
    } else {
        false
    }
}

fn log_sync_phase(phase: SyncLibraryPhaseDto, route: SyncLibraryRouteDto) {
    tracing::info!(?phase, ?route, "sync phase");
}

#[tracing::instrument(skip(emit, handle), err)]
pub async fn sync_library(
    handle: SyncHandle,
    emit: impl FnMut(SyncLibraryProgressDto),
) -> Result<(), HentaiError> {
    let db = connection()?;
    let roots = load_saved_paths(&db).await?;
    let effective = normalize_roots(&roots);
    if effective.is_empty() {
        return sync_no_roots(&db, &handle, emit).await;
    }
    sync_with_roots(&db, &handle, &effective, emit).await
}

#[tracing::instrument(skip(emit, handle), err)]
async fn sync_no_roots(
    db: &sea_orm::DatabaseConnection,
    handle: &SyncHandle,
    mut emit: impl FnMut(SyncLibraryProgressDto),
) -> Result<(), HentaiError> {
    if return_if_cancelled(handle, "no_roots_start") {
        return Ok(());
    }
    let count = count_all_comic_ids(db).await?;
    if count == 0 {
        log_sync_phase(SyncLibraryPhaseDto::Done, SyncLibraryRouteDto::NoRootsNoop);
        emit(progress(
            SyncLibraryPhaseDto::Done,
            SyncLibraryRouteDto::NoRootsNoop,
            None,
            0,
            LibrarySyncCountsDto::default(),
            None,
            None,
            None,
            None,
            None,
            None,
        ));
        return Ok(());
    }
    log_sync_phase(
        SyncLibraryPhaseDto::ClearingLibrary,
        SyncLibraryRouteDto::NoRootsCleared,
    );
    emit(progress(
        SyncLibraryPhaseDto::ClearingLibrary,
        SyncLibraryRouteDto::NoRootsCleared,
        None,
        0,
        LibrarySyncCountsDto::default(),
        None,
        None,
        None,
        None,
        None,
        None,
    ));
    if return_if_cancelled(handle, "clearing_library") {
        return Ok(());
    }
    log_sync_phase(SyncLibraryPhaseDto::WritingDb, SyncLibraryRouteDto::NoRootsCleared);
    emit(progress(
        SyncLibraryPhaseDto::WritingDb,
        SyncLibraryRouteDto::NoRootsCleared,
        None,
        0,
        LibrarySyncCountsDto::default(),
        None,
        None,
        None,
        None,
        None,
        None,
    ));
    let removed = clear_all_comics(db).await?;
    clear_reader_sessions();
    log_sync_phase(SyncLibraryPhaseDto::Done, SyncLibraryRouteDto::NoRootsCleared);
    tracing::info!(removed, "sync complete");
    emit(progress(
        SyncLibraryPhaseDto::Done,
        SyncLibraryRouteDto::NoRootsCleared,
        None,
        0,
        LibrarySyncCountsDto::default(),
        Some(removed),
        Some(0),
        Some(0),
        None,
        None,
        None,
    ));
    Ok(())
}

#[tracing::instrument(skip(emit, roots, handle), err, fields(root_count = roots.len()))]
async fn sync_with_roots(
    db: &sea_orm::DatabaseConnection,
    handle: &SyncHandle,
    roots: &[PathBuf],
    mut emit: impl FnMut(SyncLibraryProgressDto),
) -> Result<(), HentaiError> {
    let existing_by_id = load_existing_comics_map(db).await?;
    let thumbnail_stats = load_thumbnail_stats(db).await?;
    let ctx = ScanContext {
        existing_by_id,
        thumbnail_stats,
    };
    let mut counts = LibrarySyncCountsDto::default();
    let mut accepted_total = 0i32;

    log_sync_phase(SyncLibraryPhaseDto::Scanning, SyncLibraryRouteDto::WithRoots);
    emit(progress(
        SyncLibraryPhaseDto::Scanning,
        SyncLibraryRouteDto::WithRoots,
        None,
        accepted_total,
        counts.clone(),
        None,
        None,
        None,
        None,
        None,
        None,
    ));

    let scan_items = scan_roots(roots, &ctx, handle)?;
    if return_if_cancelled(handle, "scanning") {
        return Ok(());
    }
    for item in &scan_items {
        counts.bump(&item.resource_type);
        accepted_total += 1;
        emit(progress(
            SyncLibraryPhaseDto::Scanning,
            SyncLibraryRouteDto::WithRoots,
            Some(item.path.clone()),
            accepted_total,
            counts.clone(),
            None,
            None,
            None,
            None,
            None,
            None,
        ));
    }
    if return_if_cancelled(handle, "scanning_progress") {
        return Ok(());
    }

    log_sync_phase(SyncLibraryPhaseDto::WritingDb, SyncLibraryRouteDto::WithRoots);
    emit(progress(
        SyncLibraryPhaseDto::WritingDb,
        SyncLibraryRouteDto::WithRoots,
        None,
        accepted_total,
        counts.clone(),
        None,
        None,
        None,
        None,
        None,
        None,
    ));

    let plan = build_scan_replace_plan(db, scan_items).await?;
    if return_if_cancelled(handle, "writing_db") {
        return Ok(());
    }
    apply_scan_replace_plan(db, &plan).await?;
    clear_reader_sessions();

    let thumbnail_targets = plan.thumbnail_generation_targets.clone();
    let thumb_total = thumbnail_targets.len() as i32;
    if !thumbnail_targets.is_empty() {
        let comic_ids: Vec<String> = thumbnail_targets
            .iter()
            .map(|c| c.comic_id.clone())
            .collect();
        enqueue_thumbnails_low(comic_ids).await?;
    }

    log_sync_phase(SyncLibraryPhaseDto::Done, SyncLibraryRouteDto::WithRoots);
    tracing::info!(
        accepted_total,
        removed = plan.removed_ids.len(),
        added = plan.added_count,
        kept = plan.kept_count,
        thumbnail_total = thumb_total,
        "sync complete"
    );
    emit(progress(
        SyncLibraryPhaseDto::Done,
        SyncLibraryRouteDto::WithRoots,
        None,
        accepted_total,
        counts,
        Some(plan.removed_ids.len() as i32),
        Some(plan.added_count),
        Some(plan.kept_count),
        if thumb_total > 0 {
            Some(thumb_total)
        } else {
            None
        },
        Some(0),
        Some(0),
    ));
    Ok(())
}

#[allow(clippy::too_many_arguments)]
fn progress(
    phase: SyncLibraryPhaseDto,
    route: SyncLibraryRouteDto,
    current_path: Option<String>,
    accepted_total: i32,
    counts: LibrarySyncCountsDto,
    removed_count: Option<i32>,
    added_count: Option<i32>,
    kept_count: Option<i32>,
    thumbnail_total: Option<i32>,
    thumbnail_done: Option<i32>,
    thumbnail_failed_count: Option<i32>,
) -> SyncLibraryProgressDto {
    SyncLibraryProgressDto {
        phase,
        route,
        current_path,
        accepted_total,
        counts,
        removed_count,
        added_count,
        kept_count,
        thumbnail_total,
        thumbnail_done,
        thumbnail_failed_count,
        error_message: None,
    }
}
