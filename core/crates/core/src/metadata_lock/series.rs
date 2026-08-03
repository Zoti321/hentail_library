fn scanned_text_present(value: &str) -> bool {
    !value.trim().is_empty()
}

/// Folder-derived Series name under Metadata field lock.
///
/// Unlocked + non-empty folder name → folder name; otherwise keep existing.
pub fn merge_series_name(name_locked: bool, existing_name: &str, folder_name: &str) -> String {
    if name_locked || !scanned_text_present(folder_name) {
        existing_name.to_string()
    } else {
        folder_name.to_string()
    }
}

/// Whether sync / Metadata refresh should write Series.name.
pub fn series_name_needs_write(name_locked: bool, existing_name: &str, folder_name: &str) -> bool {
    !name_locked
        && scanned_text_present(folder_name)
        && merge_series_name(false, existing_name, folder_name) != existing_name
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
