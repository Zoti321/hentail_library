pub(crate) fn scanned_text_present(value: &str) -> bool {
    !value.trim().is_empty()
}

/// Nonempty-scan text merge under one Metadata field lock.
///
/// Locked → keep existing; unlocked + non-empty scan → scan; unlocked + empty/blank scan → keep
/// existing (never clears).
#[must_use]
pub fn merge_scanned_text(locked: bool, existing: &str, scanned: &str) -> String {
    if locked || !scanned_text_present(scanned) {
        existing.to_string()
    } else {
        scanned.to_string()
    }
}

/// Whether [`merge_scanned_text`] would change `existing`.
#[must_use]
pub fn scanned_text_needs_write(locked: bool, existing: &str, scanned: &str) -> bool {
    merge_scanned_text(locked, existing, scanned) != existing
}
