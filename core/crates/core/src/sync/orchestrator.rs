use std::path::PathBuf;

use crate::db::connection;
use crate::error::HentaiError;
use crate::library::{
    find_library_by_id, get_current_library_id, list_libraries, LibraryDto,
};
use crate::reader::clear_reader_sessions;
use crate::resource::normalize_roots;

use super::dto::{
    LibrarySyncCountsDto, SyncLibraryPhaseDto, SyncLibraryProgressDto, SyncLibraryRouteDto,
    SyncScanMode,
};
use super::handle::SyncHandle;
use super::library_lock::try_acquire_library_write_lock;
use super::plan::{
    build_scan_replace_plan, load_existing_comics_map, load_thumbnail_stats,
};
use super::scanner::{ScanContext, scan_roots_excluding};
use super::writer::apply_scan_replace_plan;
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
    scan_mode: SyncScanMode,
    sync_all: bool,
    mut emit: impl FnMut(SyncLibraryProgressDto),
) -> Result<(), HentaiError> {
    let _guard = try_acquire_library_write_lock()?;
    let db = connection()?;

    let targets: Vec<LibraryDto> = if sync_all {
        list_libraries().await?
    } else {
        match get_current_library_id().await? {
            Some(id) => match find_library_by_id(&id).await? {
                Some(lib) => vec![lib],
                None => Vec::new(),
            },
            None => Vec::new(),
        }
    };

    if targets.is_empty() {
        return sync_noop(&mut emit).await;
    }

    let mut last_progress: Option<SyncLibraryProgressDto> = None;
    for library in targets {
        if return_if_cancelled(&handle, "library_loop") {
            return Ok(());
        }
        if let Some(progress) =
            sync_one_library(&db, &handle, &library, scan_mode, &mut emit).await?
        {
            last_progress = Some(progress);
        }
    }
    // Emit a single Done for the whole run so Flutter stream consumers do not
    // stop after the first library when sync_all is true.
    if let Some(mut done) = last_progress {
        done.phase = SyncLibraryPhaseDto::Done;
        log_sync_phase(SyncLibraryPhaseDto::Done, done.route);
        emit(done);
    } else {
        sync_noop(&mut emit).await?;
    }
    Ok(())
}

async fn sync_noop(
    emit: &mut impl FnMut(SyncLibraryProgressDto),
) -> Result<(), HentaiError> {
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
        None,
    ));
    Ok(())
}

#[tracing::instrument(
    skip(emit, handle, db, library),
    err,
    fields(library_id = %library.library_id, root = %library.root_path)
)]
async fn sync_one_library(
    db: &sea_orm::DatabaseConnection,
    handle: &SyncHandle,
    library: &LibraryDto,
    scan_mode: SyncScanMode,
    emit: &mut impl FnMut(SyncLibraryProgressDto),
) -> Result<Option<SyncLibraryProgressDto>, HentaiError> {
    let roots = normalize_roots(&[library.root_path.clone()]);
    if roots.is_empty() {
        return Ok(None);
    }
    let exclude_roots: Vec<String> = list_libraries()
        .await?
        .into_iter()
        .filter(|lib| lib.library_id != library.library_id)
        .map(|lib| lib.root_path)
        .collect();
    sync_with_roots(
        db,
        handle,
        &library.library_id,
        &roots,
        &exclude_roots,
        scan_mode,
        &library.enabled_format_groups,
        emit,
    )
    .await
}

#[tracing::instrument(skip(emit, roots, handle), err, fields(root_count = roots.len()))]
async fn sync_with_roots(
    db: &sea_orm::DatabaseConnection,
    handle: &SyncHandle,
    library_id: &str,
    roots: &[PathBuf],
    exclude_roots: &[String],
    scan_mode: SyncScanMode,
    enabled_format_groups: &[crate::sync::format_group::FormatGroup],
    emit: &mut impl FnMut(SyncLibraryProgressDto),
) -> Result<Option<SyncLibraryProgressDto>, HentaiError> {
    let force_full_parse = scan_mode == SyncScanMode::Full;
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
        None,
    ));

    let mut scan_items = scan_roots_excluding(
        roots,
        exclude_roots,
        &ctx,
        handle,
        force_full_parse,
        enabled_format_groups,
    )?;
    for item in &mut scan_items {
        item.comic.library_id = library_id.to_string();
    }
    if return_if_cancelled(handle, "scanning") {
        return Ok(None);
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
            None,
        ));
    }
    if return_if_cancelled(handle, "scanning_progress") {
        return Ok(None);
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
        None,
    ));

    let plan = build_scan_replace_plan(db, scan_items, library_id).await?;
    if return_if_cancelled(handle, "writing_db") {
        return Ok(None);
    }
    apply_scan_replace_plan(db, &plan, library_id).await?;
    // Sole locality for sync-driven session invalidation (do not also clear from Flutter).
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

    tracing::info!(
        accepted_total,
        removed = plan.removed_ids.len(),
        added = plan.added_count,
        kept = plan.kept_count,
        migrated = plan.migrated_count,
        thumbnail_total = thumb_total,
        "library sync write complete"
    );
    Ok(Some(progress(
        SyncLibraryPhaseDto::WritingDb,
        SyncLibraryRouteDto::WithRoots,
        None,
        accepted_total,
        counts,
        Some(plan.removed_ids.len() as i32),
        Some(plan.added_count),
        Some(plan.kept_count),
        if plan.migrated_count > 0 {
            Some(plan.migrated_count)
        } else {
            None
        },
        if thumb_total > 0 {
            Some(thumb_total)
        } else {
            None
        },
        Some(0),
        Some(0),
    )))
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
    migrated_count: Option<i32>,
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
        migrated_count,
        thumbnail_total,
        thumbnail_done,
        thumbnail_failed_count,
        error_message: None,
    }
}
