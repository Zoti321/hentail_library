//! Name normalization for Metadata writes (ADR-0007).
//!
//! Three purposes, three rules, one place — so a write path cannot invent a fourth:
//!
//! | function | purpose | trims | case | duplicates | order |
//! |---|---|---|---|---|---|
//! | [`normalize_names`] | stored Metadata values | yes | preserved | first-seen kept | preserved |
//! | [`normalize_match_tokens`] | filter / query input | yes | lowercased | kept | preserved |
//! | [`normalize_tag_expression_tokens`] | tag-boolean-expression terms | yes | lowercased | removed | sorted |
//!
//! Stored values keep their original case because matching is case-insensitive in SQL
//! (`lower(column) = ?`, see `comic/filter_predicate.rs`).

use std::collections::BTreeSet;

/// Names as they are stored: trimmed, empties dropped, first-seen duplicates removed; order and
/// case preserved.
pub fn normalize_names(source: &[String]) -> Vec<String> {
    let mut out: Vec<String> = Vec::with_capacity(source.len());
    for value in source {
        let trimmed = value.trim();
        if trimmed.is_empty() || out.iter().any(|existing| existing.as_str() == trimmed) {
            continue;
        }
        out.push(trimmed.to_string());
    }
    out
}

/// Filter / query input: trimmed and lowercased, empties dropped; order and duplicates kept
/// (duplicates are harmless in an `IN (...)` predicate).
pub fn normalize_match_tokens(source: &[String]) -> Vec<String> {
    source
        .iter()
        .map(|value| value.trim().to_lowercase())
        .filter(|value| !value.is_empty())
        .collect()
}

/// One tag-boolean-expression operand: trimmed and lowercased, empties dropped, deduplicated,
/// sorted — a candidate set for the `lower(...) IN (...)` predicate of tag-expression search.
pub fn normalize_tag_expression_tokens(source: &[String]) -> Vec<String> {
    let mut set = BTreeSet::new();
    for value in source {
        let normalized = value.trim().to_lowercase();
        if !normalized.is_empty() {
            set.insert(normalized);
        }
    }
    set.into_iter().collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn names(values: &[&str]) -> Vec<String> {
        values.iter().map(|value| value.to_string()).collect()
    }

    #[test]
    fn normalize_names_trims_dedupes_and_preserves_order_and_case() {
        assert_eq!(
            normalize_names(&names(&[" Action ", "Drama", "action", "", "  ", "Drama"])),
            vec!["Action", "Drama", "action"]
        );
        assert!(normalize_names(&names(&["", "   "])).is_empty());
    }

    #[test]
    fn normalize_match_tokens_lowercases_and_keeps_duplicates() {
        assert_eq!(
            normalize_match_tokens(&names(&[" Tag ", "tag", "", "  "])),
            vec!["tag", "tag"]
        );
    }

    #[test]
    fn normalize_tag_expression_tokens_is_sorted_and_unique() {
        assert_eq!(
            normalize_tag_expression_tokens(&names(&[" b ", "A", "a", ""])),
            vec!["a", "b"]
        );
    }
}
