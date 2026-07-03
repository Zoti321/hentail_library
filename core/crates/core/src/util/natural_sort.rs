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
}
