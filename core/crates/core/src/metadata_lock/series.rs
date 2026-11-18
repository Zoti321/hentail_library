use super::text::{merge_scanned_text, scanned_text_needs_write};

/// Folder-derived Series name under Metadata field lock ([`merge_scanned_text`]).
pub fn merge_series_name(name_locked: bool, existing_name: &str, folder_name: &str) -> String {
    merge_scanned_text(name_locked, existing_name, folder_name)
}

/// Whether sync / Metadata refresh should write Series.name.
pub fn series_name_needs_write(name_locked: bool, existing_name: &str, folder_name: &str) -> bool {
    scanned_text_needs_write(name_locked, existing_name, folder_name)
}

/// Komga-style SeriesItem order: locked keep value; unlocked use 1-based natural index.
///
/// Returns `(sort_order, sort_order_locked)`.
pub fn resolve_member_sort_order(
    locked_order: Option<f64>,
    natural_index_1based: f64,
) -> (f64, bool) {
    match locked_order {
        Some(order) => (order, true),
        None => (natural_index_1based, false),
    }
}
