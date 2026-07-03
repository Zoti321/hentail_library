use hentai_core::{
    self, SyncHandle as CoreHandle, SyncLibraryPhaseDto as CorePhase,
    SyncLibraryProgressDto as CoreProgress, SyncLibraryRouteDto as CoreRoute,
    cancel_sync as core_cancel_sync, create_sync_handle as core_create_sync_handle,
    sync_library as core_sync_library,
};

use super::init::HentaiErrorDto;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SyncLibraryPhaseDto {
    ClearingLibrary,
    Scanning,
    WritingDb,
    GeneratingThumbnails,
    Done,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SyncLibraryRouteDto {
    NoRootsNoop,
    NoRootsCleared,
    WithRoots,
}

#[derive(Debug, Clone)]
pub struct LibrarySyncCountsDto {
    pub dir: i32,
    pub zip: i32,
    pub cbz: i32,
    pub epub: i32,
    pub cbr: i32,
    pub rar: i32,
    pub cb7: i32,
    pub sevenz: i32,
    pub pdf: i32,
}

#[derive(Debug, Clone)]
pub struct SyncLibraryProgressDto {
    pub phase: SyncLibraryPhaseDto,
    pub route: SyncLibraryRouteDto,
    pub current_path: Option<String>,
    pub accepted_total: i32,
    pub counts: LibrarySyncCountsDto,
    pub removed_count: Option<i32>,
    pub added_count: Option<i32>,
    pub kept_count: Option<i32>,
    pub thumbnail_total: Option<i32>,
    pub thumbnail_done: Option<i32>,
    pub thumbnail_failed_count: Option<i32>,
}

pub struct SyncHandleDto {
    pub(crate) inner: CoreHandle,
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_sync_handle_frb() -> SyncHandleDto {
    SyncHandleDto {
        inner: core_create_sync_handle(),
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn cancel_sync_frb(handle: &SyncHandleDto) {
    core_cancel_sync(&handle.inner);
}

#[flutter_rust_bridge::frb]
pub async fn sync_library_frb(
    handle: SyncHandleDto,
    sink: crate::frb_generated::StreamSink<SyncLibraryProgressDto>,
) -> Result<(), HentaiErrorDto> {
    core_sync_library(handle.inner, |progress| {
        let _ = sink.add(map_progress(progress));
    })
    .await
    .map_err(HentaiErrorDto::from)
}

fn map_progress(p: CoreProgress) -> SyncLibraryProgressDto {
    SyncLibraryProgressDto {
        phase: map_phase(p.phase),
        route: map_route(p.route),
        current_path: p.current_path,
        accepted_total: p.accepted_total,
        counts: LibrarySyncCountsDto {
            dir: p.counts.dir,
            zip: p.counts.zip,
            cbz: p.counts.cbz,
            epub: p.counts.epub,
            cbr: p.counts.cbr,
            rar: p.counts.rar,
            cb7: p.counts.cb7,
            sevenz: p.counts.sevenz,
            pdf: p.counts.pdf,
        },
        removed_count: p.removed_count,
        added_count: p.added_count,
        kept_count: p.kept_count,
        thumbnail_total: p.thumbnail_total,
        thumbnail_done: p.thumbnail_done,
        thumbnail_failed_count: p.thumbnail_failed_count,
    }
}

fn map_phase(p: CorePhase) -> SyncLibraryPhaseDto {
    match p {
        CorePhase::ClearingLibrary => SyncLibraryPhaseDto::ClearingLibrary,
        CorePhase::Scanning => SyncLibraryPhaseDto::Scanning,
        CorePhase::WritingDb => SyncLibraryPhaseDto::WritingDb,
        CorePhase::GeneratingThumbnails => SyncLibraryPhaseDto::GeneratingThumbnails,
        CorePhase::Done => SyncLibraryPhaseDto::Done,
    }
}

fn map_route(r: CoreRoute) -> SyncLibraryRouteDto {
    match r {
        CoreRoute::NoRootsNoop => SyncLibraryRouteDto::NoRootsNoop,
        CoreRoute::NoRootsCleared => SyncLibraryRouteDto::NoRootsCleared,
        CoreRoute::WithRoots => SyncLibraryRouteDto::WithRoots,
    }
}