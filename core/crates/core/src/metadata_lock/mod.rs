//! Metadata write policy (ADR-0007 / ADR-0006).
//!
//! Deep module: Library sync, Metadata refresh, and user-meta writes share one interface for
//! merge + auto-lock, plus the field table that says which Metadata fields exist and how their
//! names are normalized. Persistence stays in comic/series write paths.
//!
//! - [`ComicMetaField`] / [`SeriesMetaField`]: the single field list, with value column (or
//!   attached junction table via [`ComicMetaStorage`]), lock column, scan-source flag and — for
//!   Comic — the `ComicMetaLocks` serde key.
//! - [`ComicAutoLocks`] / [`SeriesAutoLocks`]: which locks a user-meta write turns on.
//! - [`normalize_names`] / [`normalize_match_tokens`] / [`normalize_tag_expression_tokens`]:
//!   name rules.
//! - `merge_*`: scan / refresh merge, and [`merge_multi_value`] for list-valued patches.

mod auto_lock;
mod comic;
mod field;
mod multi_value;
mod normalize;
mod series;

pub use auto_lock::{series_auto_locks, ComicAutoLocks, SeriesAutoLocks};
pub use comic::{merge_kept_scan_with_existing, merge_refresh_scan_with_existing};
pub use field::{ComicMetaField, ComicMetaStorage, SeriesMetaField};
pub use multi_value::{merge_multi_value, MultiValueOp, MultiValuePatch};
pub use normalize::{normalize_match_tokens, normalize_names, normalize_tag_expression_tokens};
pub use series::{merge_series_name, resolve_member_sort_order, series_name_needs_write};
