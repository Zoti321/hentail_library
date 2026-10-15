//! Library maintenance: Library sync + Metadata refresh behind one write lock.
//!
//! - [`sync_library`] / [`refresh_comic_metadata`] / [`refresh_series_metadata`] /
//!   [`refresh_library_metadata`] are the public entry points (also exposed via FRB).
//! - [`crate::library_write`] enforces global single-flight across those operations
//!   (and across every other cross-comic bulk write, see ADR-0026).
//! - Reader sessions are cleared inside the sync orchestrator after DB writes;
//!   Flutter must not duplicate that invalidation.

pub mod dto;
pub mod format_group;
pub mod handle;
pub mod orchestrator;
pub mod plan;
pub mod refresh;
pub mod remote;
pub mod scanner;
pub mod series_rebuild;
pub mod thumbnail;
pub mod writer;

pub use crate::library_write::try_acquire_library_write_lock;
pub use dto::{
    LibrarySyncCountsDto, SyncLibraryPhaseDto, SyncLibraryProgressDto, SyncLibraryRouteDto,
    SyncScanMode,
};
pub use format_group::FormatGroup;
pub use handle::{cancel_sync, create_sync_handle, SyncHandle};
pub use orchestrator::sync_library;
pub use refresh::{
    refresh_comic_metadata, refresh_comic_metadata_with, refresh_library_metadata,
    refresh_series_metadata, RefreshLibraryResultDto, RefreshSeriesProgressDto,
    RefreshSeriesResultDto,
};
pub use remote::{comic_id_for_remote_location, scan_remote_lightweight, RemoteScanOutcome};
