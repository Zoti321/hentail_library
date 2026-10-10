//! Multi-value Metadata patch algebra: Tags / Authors / Languages / Parodies / Characters.
//!
//! The single implementation of add / remove / replace for list-valued Metadata. The bulk patch
//! (`comic/bulk_patch.rs`) merges through this module, and any single-Comic partial patch should
//! too, instead of growing a second copy.
//!
//! Values are compared verbatim — case-sensitive and untrimmed — because normalization belongs to
//! the write path ([`super::normalize`]) and matching to SQL `lower()`.

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MultiValueOp {
    Add,
    Remove,
    Replace,
}

#[derive(Debug, Clone)]
pub struct MultiValuePatch {
    pub op: MultiValueOp,
    pub values: Vec<String>,
}

/// `Add` appends values that are not present yet (first-seen order kept), `Remove` drops every
/// value listed in the patch, `Replace` takes the patch list as the whole new list.
pub fn merge_multi_value(current: &[String], patch: &MultiValuePatch) -> Vec<String> {
    match patch.op {
        MultiValueOp::Add => {
            let mut out = current.to_vec();
            for value in &patch.values {
                if !out.iter().any(|existing| existing == value) {
                    out.push(value.clone());
                }
            }
            out
        }
        MultiValueOp::Remove => current
            .iter()
            .filter(|value| !patch.values.iter().any(|remove| remove == *value))
            .cloned()
            .collect(),
        MultiValueOp::Replace => patch.values.clone(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn merge_add_dedupes_preserving_order() {
        let current = vec!["a".to_string(), "b".to_string()];
        let patch = MultiValuePatch {
            op: MultiValueOp::Add,
            values: vec!["b".to_string(), "c".to_string()],
        };
        assert_eq!(
            merge_multi_value(&current, &patch),
            vec!["a", "b", "c"]
                .into_iter()
                .map(String::from)
                .collect::<Vec<_>>()
        );
    }

    #[test]
    fn merge_remove_is_noop_when_missing() {
        let current = vec!["a".to_string()];
        let patch = MultiValuePatch {
            op: MultiValueOp::Remove,
            values: vec!["z".to_string()],
        };
        assert_eq!(merge_multi_value(&current, &patch), current);
    }

    #[test]
    fn merge_replace_replaces_whole_list() {
        let current = vec!["a".to_string(), "b".to_string()];
        let patch = MultiValuePatch {
            op: MultiValueOp::Replace,
            values: vec!["x".to_string()],
        };
        assert_eq!(merge_multi_value(&current, &patch), vec!["x".to_string()]);
    }
}
