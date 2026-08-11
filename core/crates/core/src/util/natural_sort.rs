pub fn compare_filename_natural(a: &str, b: &str) -> std::cmp::Ordering {
    let a_parts = split_natural(a);
    let b_parts = split_natural(b);
    for (ap, bp) in a_parts.iter().zip(b_parts.iter()) {
        match (ap.parse::<u64>(), bp.parse::<u64>()) {
            (Ok(na), Ok(nb)) => match na.cmp(&nb) {
                std::cmp::Ordering::Equal => continue,
                other => return other,
            },
            _ => match ap.cmp(bp) {
                std::cmp::Ordering::Equal => continue,
                other => return other,
            },
        }
    }
    a_parts.len().cmp(&b_parts.len())
}

/// Lexicographic sort key approximating ASCII-case-insensitive natural order.
///
/// Numeric runs are zero-padded to [`SORT_KEY_NUMERIC_WIDTH`] digits so that
/// SQL `ORDER BY sort_key` matches natural numeric ordering (e.g. `Vol 2` < `Vol 10`).
pub const SORT_KEY_NUMERIC_WIDTH: usize = 20;

pub fn compute_sort_key(display: &str) -> String {
    let mut out = String::with_capacity(display.len());
    for part in split_natural(display) {
        if let Ok(n) = part.parse::<u64>() {
            out.push_str(&format!("{n:0width$}", width = SORT_KEY_NUMERIC_WIDTH));
        } else {
            for ch in part.chars() {
                out.push(ch.to_ascii_lowercase());
            }
        }
    }
    out
}

fn split_natural(s: &str) -> Vec<String> {
    let mut parts = Vec::new();
    let mut current = String::new();
    let mut was_digit = false;
    for ch in s.chars() {
        let is_digit = ch.is_ascii_digit();
        if !current.is_empty() && is_digit != was_digit {
            parts.push(current.clone());
            current.clear();
        }
        current.push(ch);
        was_digit = is_digit;
    }
    if !current.is_empty() {
        parts.push(current);
    }
    parts
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn natural_sort_orders_numeric_suffixes() {
        let mut names = vec!["page2", "page10", "page1"];
        names.sort_by(|a, b| compare_filename_natural(a, b));
        assert_eq!(names, vec!["page1", "page2", "page10"]);
    }

    #[test]
    fn sort_key_orders_vol_numbers_naturally() {
        let a = compute_sort_key("Vol 2");
        let b = compute_sort_key("Vol 10");
        assert!(a < b, "expected {a:?} < {b:?}");
    }

    #[test]
    fn sort_key_is_ascii_case_insensitive() {
        assert_eq!(compute_sort_key("Alpha"), compute_sort_key("alpha"));
        assert_eq!(compute_sort_key("Beta"), compute_sort_key("BETA"));
        assert!(compute_sort_key("Alpha") < compute_sort_key("Beta"));
    }

    #[test]
    fn sort_key_leading_zeros_share_numeric_value() {
        assert_eq!(compute_sort_key("01"), compute_sort_key("1"));
        assert_eq!(compute_sort_key("Vol 01"), compute_sort_key("Vol 1"));
    }

    #[test]
    fn sort_key_orders_match_padded_lexicographic_list() {
        let mut titles = vec!["Vol 10", "Vol 2", "vol 1", "Alpha"];
        titles.sort_by_key(|t| compute_sort_key(t));
        assert_eq!(titles, vec!["Alpha", "vol 1", "Vol 2", "Vol 10"]);
    }
}
