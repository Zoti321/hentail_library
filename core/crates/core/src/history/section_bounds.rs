//! Local-calendar five-bucket boundaries for reading history (aligned with Dart
//! `history_time_grouping.dart`).

const MS_PER_DAY: i64 = 86_400_000;
const MS_PER_MINUTE: i64 = 60_000;

/// Half-open UTC ms ranges for the five history time sections.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ReadingHistorySectionBounds {
    pub today_start_ms: i64,
    pub yesterday_start_ms: i64,
    pub week_start_ms: i64,
    pub month_start_ms: i64,
}

/// Compute section day-start boundaries for [now_ms] in the client's local zone.
///
/// [client_timezone_offset_minutes] matches Dart `DateTime.timeZoneOffset.inMinutes`
/// (east of UTC positive).
pub fn reading_history_section_bounds(
    now_ms: i64,
    client_timezone_offset_minutes: i32,
) -> ReadingHistorySectionBounds {
    let offset_ms = i64::from(client_timezone_offset_minutes).saturating_mul(MS_PER_MINUTE);
    let local_ms = now_ms.saturating_add(offset_ms);
    let today_day = local_ms.div_euclid(MS_PER_DAY);
    let weekday = weekday_mon1(today_day);
    let yesterday_day = today_day - 1;
    let week_start_day = today_day - i64::from(weekday - 1);
    let (year, month, _) = civil_from_days(today_day);
    let month_start_day = days_from_civil(year, month, 1);

    ReadingHistorySectionBounds {
        today_start_ms: local_day_start_to_utc_ms(today_day, offset_ms),
        yesterday_start_ms: local_day_start_to_utc_ms(yesterday_day, offset_ms),
        week_start_ms: local_day_start_to_utc_ms(week_start_day, offset_ms),
        month_start_ms: local_day_start_to_utc_ms(month_start_day, offset_ms),
    }
}

fn local_day_start_to_utc_ms(local_day_index: i64, offset_ms: i64) -> i64 {
    local_day_index.saturating_mul(MS_PER_DAY).saturating_sub(offset_ms)
}

/// Dart `DateTime.weekday`: Monday = 1 … Sunday = 7. Unix day 0 (1970-01-01) is Thursday = 4.
fn weekday_mon1(unix_day: i64) -> i32 {
    ((unix_day + 3).rem_euclid(7) + 1) as i32
}

/// Days since Unix epoch for civil Y-M-D (Howard Hinnant).
fn days_from_civil(year: i32, month: u32, day: u32) -> i64 {
    let mut y = i64::from(year);
    let m = i64::from(month);
    let d = i64::from(day);
    y -= i64::from(m <= 2);
    let era = y.div_euclid(400);
    let yoe = y - era * 400;
    let doy = (153 * (m + if m > 2 { -3 } else { 9 }) + 2) / 5 + d - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    era * 146_097 + doe - 719_468
}

fn civil_from_days(z: i64) -> (i32, u32, u32) {
    let z = z + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z - era * 146_097;
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = mp + if mp < 10 { 3 } else { -9 };
    let y = y + i64::from(m <= 2);
    (y as i32, m as u32, d as u32)
}

#[cfg(test)]
mod tests {
    #![allow(clippy::unwrap_used)]

    use super::*;

    #[test]
    fn bounds_match_dart_wednesday_fixture_utc() {
        // 2026-03-11 15:00 local with offset 0 (same as Dart clock DateTime(2026, 3, 11, 15)).
        let now = days_from_civil(2026, 3, 11) * MS_PER_DAY + 15 * 3_600_000;
        let bounds = reading_history_section_bounds(now, 0);
        assert_eq!(bounds.today_start_ms, days_from_civil(2026, 3, 11) * MS_PER_DAY);
        assert_eq!(
            bounds.yesterday_start_ms,
            days_from_civil(2026, 3, 10) * MS_PER_DAY
        );
        // Week starts Monday 2026-03-09.
        assert_eq!(bounds.week_start_ms, days_from_civil(2026, 3, 9) * MS_PER_DAY);
        assert_eq!(bounds.month_start_ms, days_from_civil(2026, 3, 1) * MS_PER_DAY);
    }

    #[test]
    fn weekday_mon1_unix_epoch_thursday() {
        assert_eq!(weekday_mon1(0), 4);
        assert_eq!(weekday_mon1(4), 1); // 1970-01-05 Monday
    }
}
