//! 阅读历史滚动保留窗口（与产品文案「最长保留一年」一致）。

pub const READING_HISTORY_RETENTION_DAYS: i64 = 365;

const MS_PER_DAY: i64 = 86_400_000;

/// `last_read_time` 低于此值（毫秒）的记录视为已过期。
pub fn reading_history_retention_cutoff_ms(now_ms: i64) -> i64 {
    now_ms.saturating_sub(READING_HISTORY_RETENTION_DAYS * MS_PER_DAY)
}

pub fn reading_history_within_retention(last_read_time_ms: i64, now_ms: i64) -> bool {
    last_read_time_ms >= reading_history_retention_cutoff_ms(now_ms)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cutoff_is_one_year_before_now() {
        let now = 10_000_000_000_i64;
        assert_eq!(
            reading_history_retention_cutoff_ms(now),
            now - READING_HISTORY_RETENTION_DAYS * MS_PER_DAY
        );
    }

    #[test]
    fn within_retention_boundary() {
        let now = 10_000_000_000_i64;
        let cutoff = reading_history_retention_cutoff_ms(now);
        assert!(reading_history_within_retention(cutoff, now));
        assert!(!reading_history_within_retention(cutoff - 1, now));
    }
}
