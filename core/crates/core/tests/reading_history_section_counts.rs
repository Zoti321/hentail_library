#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

mod common;

use std::path::Path;

use hentai_core::{
    connection, fetch_reading_history_section_counts, fetch_reading_page, init_db_at_path, now_ms,
    reading_history_section_bounds, record_reading, PageRequestDto, ReadingHistoryDto,
};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;

const MS_PER_HOUR: i64 = 3_600_000;

async fn create_reading_histories_table() {
    let db = connection().expect("connection");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "CREATE TABLE IF NOT EXISTS comic_reading_histories (
            comic_id TEXT NOT NULL PRIMARY KEY,
            title TEXT NOT NULL,
            last_read_time INTEGER NOT NULL,
            page_index INTEGER
        )"
        .to_string(),
    ))
    .await
    .expect("create comic_reading_histories");
}

fn create_db(dir: &Path) {
    let db_path = dir.join("history_section_counts.sqlite");
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        init_db_at_path(&db_path).await.expect("init_db");
        create_reading_histories_table().await;
    });
}

async fn seed_relative_to_now(offset_minutes: i32) {
    let now = now_ms();
    let bounds = reading_history_section_bounds(now, offset_minutes);
    let samples = [
        ("today", "Alpha", bounds.today_start_ms + MS_PER_HOUR),
        ("today2", "Zeta alpha", bounds.today_start_ms + 2 * MS_PER_HOUR),
        ("yesterday", "Beta", bounds.yesterday_start_ms + MS_PER_HOUR),
        ("week", "Gamma", bounds.week_start_ms + MS_PER_HOUR),
        ("month", "Delta", bounds.month_start_ms + MS_PER_HOUR),
        (
            "earlier",
            "Epsilon",
            bounds.month_start_ms.saturating_sub(MS_PER_HOUR),
        ),
    ];
    for (comic_id, title, last_read_time_ms) in samples {
        // Skip week sample when week_start == today (Monday) or week_start == yesterday.
        if comic_id == "week" && bounds.week_start_ms >= bounds.yesterday_start_ms {
            continue;
        }
        // Skip month sample when month_start >= week_start (early days of month).
        if comic_id == "month" && bounds.month_start_ms >= bounds.week_start_ms {
            continue;
        }
        record_reading(&ReadingHistoryDto {
            comic_id: comic_id.to_string(),
            title: title.to_string(),
            last_read_time_ms,
            page_index: Some(1),
            page_count: None,
        })
        .await
        .expect("record reading");
    }
}

#[test]
fn section_counts_match_five_buckets_and_total() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        create_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            let offset = 0;
            seed_relative_to_now(offset).await;

            let counts = fetch_reading_history_section_counts(None, offset)
                .await
                .expect("counts");
            let page = fetch_reading_page(
                PageRequestDto {
                    page: 1,
                    page_size: 50,
                },
                None,
            )
            .await
            .expect("page");

            assert_eq!(counts.total(), page.total_count);
            assert_eq!(counts.today, 2);
            assert_eq!(counts.yesterday, 1);
            assert!(counts.earlier >= 1);
        });
    });
}

#[test]
fn section_counts_respect_keyword_filter() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        create_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            seed_relative_to_now(0).await;
            let counts = fetch_reading_history_section_counts(Some("alpha".to_string()), 0)
                .await
                .expect("counts");
            let page = fetch_reading_page(
                PageRequestDto {
                    page: 1,
                    page_size: 50,
                },
                Some("alpha".to_string()),
            )
            .await
            .expect("page");
            assert_eq!(counts.total(), page.total_count);
            assert_eq!(page.total_count, 2);
            assert_eq!(counts.today, 2);
        });
    });
}

#[test]
fn section_bounds_unit_fixture_matches_dart_wednesday() {
    const MS_PER_DAY: i64 = 86_400_000;
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
    let now = days_from_civil(2026, 3, 11) * MS_PER_DAY + 15 * MS_PER_HOUR;
    let bounds = reading_history_section_bounds(now, 0);
    assert_eq!(bounds.today_start_ms, days_from_civil(2026, 3, 11) * MS_PER_DAY);
    assert_eq!(
        bounds.yesterday_start_ms,
        days_from_civil(2026, 3, 10) * MS_PER_DAY
    );
    assert_eq!(bounds.week_start_ms, days_from_civil(2026, 3, 9) * MS_PER_DAY);
    assert_eq!(bounds.month_start_ms, days_from_civil(2026, 3, 1) * MS_PER_DAY);
}
