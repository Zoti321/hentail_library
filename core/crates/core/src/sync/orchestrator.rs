use std::path::PathBuf;

use crate::db::connection;
use crate::error::HentaiError;

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
use super::thumbnail::generate_thumbnails;
use super::writer::{apply_scan_replace_plan, clear_all_comics};

pub async fn sync_library(
    handle: SyncHandle,
    mut emit: impl FnMut(SyncLibraryProgressDto),
) -> Result<(), HentaiError> {
    let db = connection()?;
    let roots = load_saved_paths(&db).await?;
    let effective = normalize_roots(&roots);
    if effective.is_empty() {
        return sync_no_roots(&db, &handle, emit).await;
    }
    sync_with_roots(&db, &handle, &effective, emit).await
}

async fn sync_no_roots(
    db: &sea_orm::DatabaseConnection,
    handle: &SyncHandle,
    mut emit: impl FnMut(SyncLibraryProgressDto),
) -> Result<(), HentaiError> {
    if handle.is_cancelled() {
        return Ok(());
    }
    let count = count_all_comic_ids(db).await?;
    if count == 0 {
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
    if handle.is_cancelled() {
        return Ok(());
    }
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
    if handle.is_cancelled() {
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
    if handle.is_cancelled() {
        return Ok(());
    }

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
    if handle.is_cancelled() {
        return Ok(());
    }
    apply_scan_replace_plan(db, &plan).await?;

    let thumbnail_targets = plan.thumbnail_generation_targets.clone();
    let mut thumbnail_failed = 0i32;
    if !thumbnail_targets.is_empty() {
        if handle.is_cancelled() {
            return Ok(());
        }
        let thumb_total = thumbnail_targets.len() as i32;
        emit(progress(
            SyncLibraryPhaseDto::GeneratingThumbnails,
            SyncLibraryRouteDto::WithRoots,
            None,
            accepted_total,
            counts.clone(),
            Some(plan.removed_ids.len() as i32),
            Some(plan.added_count),
            Some(plan.kept_count),
            Some(thumb_total),
            Some(0),
            Some(0),
        ));
        let result = generate_thumbnails(db, &thumbnail_targets, handle, |done, total, path| {
            emit(progress(
                SyncLibraryPhaseDto::GeneratingThumbnails,
                SyncLibraryRouteDto::WithRoots,
                path,
                accepted_total,
                counts.clone(),
                Some(plan.removed_ids.len() as i32),
                Some(plan.added_count),
                Some(plan.kept_count),
                Some(total),
                Some(done),
                Some(thumbnail_failed),
            ));
        })
        .await?;
        thumbnail_failed = result.failed_count;
        if handle.is_cancelled() {
            return Ok(());
        }
    }

    emit(progress(
        SyncLibraryPhaseDto::Done,
        SyncLibraryRouteDto::WithRoots,
        None,
        accepted_total,
        counts,
        Some(plan.removed_ids.len() as i32),
        Some(plan.added_count),
        Some(plan.kept_count),
        if thumbnail_targets.is_empty() {
            None
        } else {
            Some(thumbnail_targets.len() as i32)
        },
        if thumbnail_targets.is_empty() {
            None
        } else {
            Some(thumbnail_targets.len() as i32)
        },
        if thumbnail_targets.is_empty() {
            None
        } else {
            Some(thumbnail_failed)
        },
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
    }
}
