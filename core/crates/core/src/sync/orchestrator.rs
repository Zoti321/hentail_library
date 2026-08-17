use std::collections::HashMap;

use crate::db::connection;
use crate::error::HentaiError;
use crate::library::{
    find_library_by_id, get_current_library_id, list_libraries, LibraryDto,
};
use crate::reader::clear_reader_sessions;
use crate::resource::{normalize_roots, WebDavResourceAccess};

use super::dto::{
    LibrarySyncCountsDto, SyncLibraryPhaseDto, SyncLibraryProgressDto, SyncLibraryRouteDto,
    SyncScanMode,
};
use super::handle::SyncHandle;
use super::library_lock::try_acquire_library_write_lock;
use super::plan::{
    build_scan_replace_plan, load_existing_comics_map, load_thumbnail_stats,
};
use super::remote::{scan_remote_lightweight, RemoteScanOutcome};
use super::scanner::{scan_roots_excluding, ScanContext, ScanItem};
use super::writer::apply_scan_replace_plan;
use crate::thumbnail::enqueue_thumbnails_low;
use crate::library::{set_remote_library_credentials, RemoteLibraryCredential};

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

#[tracing::instrument(skip(emit, handle, credentials), err)]
pub async fn sync_library(
    handle: SyncHandle,
    scan_mode: SyncScanMode,
    sync_all: bool,
    target_library_id: Option<&str>,
    credentials: Vec<RemoteLibraryCredential>,
    mut emit: impl FnMut(SyncLibraryProgressDto),
) -> Result<(), HentaiError> {
    let _guard = try_acquire_library_write_lock()?;
    let db = connection()?;
    set_remote_library_credentials(credentials.clone());
    let cred_map: HashMap<String, String> = credentials
        .into_iter()
        .map(|c| (c.library_id, c.password))
        .collect();

    let targets: Vec<LibraryDto> = if let Some(id) = target_library_id.map(str::trim).filter(|s| !s.is_empty()) {
        match find_library_by_id(id).await? {
            Some(lib) => vec![lib],
            None => Vec::new(),
        }
    } else if sync_all {
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
    let mut remote_warnings: Vec<String> = Vec::new();
    for library in targets {
        if return_if_cancelled(&handle, "library_loop") {
            return Ok(());
        }
        match sync_one_library(
            &db,
            &handle,
            &library,
            scan_mode,
            cred_map.get(&library.library_id).map(String::as_str),
            &mut emit,
        )
        .await?
        {
            SyncOneOutcome::Progress(progress) => {
                last_progress = Some(progress);
            }
            SyncOneOutcome::Skipped { warning } => {
                remote_warnings.push(warning);
            }
            SyncOneOutcome::None => {}
        }
    }
    // Emit a single Done for the whole run so Flutter stream consumers do not
    // stop after the first library when sync_all is true.
    let warning = if remote_warnings.is_empty() {
        None
    } else {
        Some(remote_warnings.join("\n"))
    };
    if let Some(mut done) = last_progress {
        done.phase = SyncLibraryPhaseDto::Done;
        if done.error_message.is_none() {
            done.error_message = warning;
        }
        log_sync_phase(SyncLibraryPhaseDto::Done, done.route);
        emit(done);
    } else if let Some(message) = warning {
        // All targets skipped (e.g. unreachable remotes) — still Done with feedback.
        log_sync_phase(SyncLibraryPhaseDto::Done, SyncLibraryRouteDto::WithRoots);
        emit(progress(
            SyncLibraryPhaseDto::Done,
            SyncLibraryRouteDto::WithRoots,
            None,
            0,
            LibrarySyncCountsDto::default(),
            Some(0),
            Some(0),
            Some(0),
            None,
            None,
            None,
            None,
            Some(message),
        ));
    } else {
        sync_noop(&mut emit).await?;
    }
    Ok(())
}

enum SyncOneOutcome {
    Progress(SyncLibraryProgressDto),
    Skipped { warning: String },
    None,
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
        None,
    ));
    Ok(())
}

#[tracing::instrument(
    skip(emit, handle, db, library, password),
    err,
    fields(library_id = %library.library_id, root = %library.root_path, kind = %library.kind)
)]
async fn sync_one_library(
    db: &sea_orm::DatabaseConnection,
    handle: &SyncHandle,
    library: &LibraryDto,
    scan_mode: SyncScanMode,
    password: Option<&str>,
    emit: &mut impl FnMut(SyncLibraryProgressDto),
) -> Result<SyncOneOutcome, HentaiError> {
    if library.kind == "remote" {
        return sync_remote_library(db, handle, library, password, emit).await;
    }

    let roots = normalize_roots(std::slice::from_ref(&library.root_path));
    if roots.is_empty() {
        return Ok(SyncOneOutcome::None);
    }
    let exclude_roots: Vec<String> = list_libraries()
        .await?
        .into_iter()
        .filter(|lib| lib.library_id != library.library_id)
        .map(|lib| lib.root_path)
        .collect();
    let force_full_parse = scan_mode == SyncScanMode::Full;
    let existing_by_id = load_existing_comics_map(db).await?;
    let thumbnail_stats = load_thumbnail_stats(db).await?;
    let ctx = ScanContext {
        existing_by_id,
        thumbnail_stats,
    };
    emit_scanning(emit);
    let mut scan_items = scan_roots_excluding(
        &roots,
        &exclude_roots,
        &ctx,
        handle,
        force_full_parse,
        &library.enabled_format_groups,
    )?;
    for item in &mut scan_items {
        item.comic.library_id = library.library_id.clone();
    }
    Ok(map_finish_outcome(
        finish_scan_write(
            db,
            handle,
            &library.library_id,
            scan_items,
            /*enqueue_thumbs=*/ true,
            emit,
        )
        .await?,
    ))
}

async fn sync_remote_library(
    db: &sea_orm::DatabaseConnection,
    handle: &SyncHandle,
    library: &LibraryDto,
    password: Option<&str>,
    emit: &mut impl FnMut(SyncLibraryProgressDto),
) -> Result<SyncOneOutcome, HentaiError> {
    emit_scanning(emit);
    let Some(password) = password.filter(|p| !p.is_empty()) else {
        let warning = format!(
            "已跳过远程库（缺少凭证）: {}",
            library.root_path
        );
        tracing::warn!(library_id = %library.library_id, "{warning}");
        emit(progress(
            SyncLibraryPhaseDto::Scanning,
            SyncLibraryRouteDto::WithRoots,
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
            Some(warning.clone()),
        ));
        return Ok(SyncOneOutcome::Skipped { warning });
    };

    let access = match WebDavResourceAccess::connect(
        &library.root_path,
        &library.username,
        password,
    ) {
        Ok(access) => access,
        Err(err) if err.is_remote_access_failure() => {
            let warning = emit_remote_skip(emit, &library.root_path, &err.message);
            return Ok(SyncOneOutcome::Skipped { warning });
        }
        Err(err) => return Err(err),
    };

    let existing_by_id = load_existing_comics_map(db).await?;
    let thumbnail_stats = load_thumbnail_stats(db).await?;
    let ctx = ScanContext {
        existing_by_id,
        thumbnail_stats,
    };
    let outcome = scan_remote_lightweight(
        &access,
        &library.root_path,
        &ctx,
        handle,
        &library.enabled_format_groups,
    )?;
    let mut scan_items = match outcome {
        RemoteScanOutcome::Unreachable { message } => {
            let warning = emit_remote_skip(emit, &library.root_path, &message);
            return Ok(SyncOneOutcome::Skipped { warning });
        }
        RemoteScanOutcome::Cancelled => return Ok(SyncOneOutcome::None),
        RemoteScanOutcome::Scanned(items) => items,
    };
    for item in &mut scan_items {
        item.comic.library_id = library.library_id.clone();
    }
    // ADR-0008: no thumbnail generation during remote sync.
    Ok(map_finish_outcome(
        finish_scan_write(
            db,
            handle,
            &library.library_id,
            scan_items,
            /*enqueue_thumbs=*/ false,
            emit,
        )
        .await?,
    ))
}

fn map_finish_outcome(progress: Option<SyncLibraryProgressDto>) -> SyncOneOutcome {
    match progress {
        Some(progress) => SyncOneOutcome::Progress(progress),
        None => SyncOneOutcome::None,
    }
}

fn emit_scanning(emit: &mut impl FnMut(SyncLibraryProgressDto)) {
    log_sync_phase(SyncLibraryPhaseDto::Scanning, SyncLibraryRouteDto::WithRoots);
    emit(progress(
        SyncLibraryPhaseDto::Scanning,
        SyncLibraryRouteDto::WithRoots,
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
        None,
    ));
}

fn emit_remote_skip(
    emit: &mut impl FnMut(SyncLibraryProgressDto),
    root: &str,
    detail: &str,
) -> String {
    let message = format!("已跳过不可达的远程库 {root}: {detail}");
    tracing::warn!("{message}");
    emit(progress(
        SyncLibraryPhaseDto::Scanning,
        SyncLibraryRouteDto::WithRoots,
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
        Some(message.clone()),
    ));
    message
}

async fn finish_scan_write(
    db: &sea_orm::DatabaseConnection,
    handle: &SyncHandle,
    library_id: &str,
    scan_items: Vec<ScanItem>,
    enqueue_thumbs: bool,
    emit: &mut impl FnMut(SyncLibraryProgressDto),
) -> Result<Option<SyncLibraryProgressDto>, HentaiError> {
    if return_if_cancelled(handle, "scanning") {
        return Ok(None);
    }
    let mut counts = LibrarySyncCountsDto::default();
    let mut accepted_total = 0i32;
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
        None,
    ));

    let plan = build_scan_replace_plan(db, scan_items, library_id).await?;
    if return_if_cancelled(handle, "writing_db") {
        return Ok(None);
    }
    apply_scan_replace_plan(db, &plan, library_id).await?;
    clear_reader_sessions();

    let thumb_total = if enqueue_thumbs {
        let thumbnail_targets = plan.thumbnail_generation_targets.clone();
        let thumb_total = thumbnail_targets.len() as i32;
        if !thumbnail_targets.is_empty() {
            let comic_ids: Vec<String> = thumbnail_targets
                .iter()
                .map(|c| c.comic_id.clone())
                .collect();
            enqueue_thumbnails_low(comic_ids).await?;
        }
        thumb_total
    } else {
        0
    };

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
        None,
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
    error_message: Option<String>,
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
        error_message,
    }
}
