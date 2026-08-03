//! Metadata field lock policy (ADR-0007 / ADR-0006).
//!
//! Deep module: Library sync, Metadata refresh, and user-meta writes share one
//! interface for merge + auto-lock. Persistence stays in comic/series write paths.

mod auto_lock;
mod comic;
mod series;

pub use auto_lock::{comic_auto_locks, series_auto_locks, ComicAutoLocks, SeriesAutoLocks};
pub use comic::merge_kept_scan_with_existing;
pub use series::{
    merge_series_name, resolve_member_sort_order, series_name_needs_write,
};
