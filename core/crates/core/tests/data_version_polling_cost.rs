//! `read_data_version` 轮询的空闲开销基线测量。
//!
//! 不是断言测——用于给 #128「是否值得改事件驱动」提供数据，故标记 `#[ignore]`
//! 不进 CI。手动运行：
//!
//! ```text
//! cargo test -p hentai-core --test data_version_polling_cost -- --ignored --nocapture
//! ```
//!
//! 稳态并发度依据（`app/lib` 侧订阅关系）：
//! - 常驻 1 条：`watch_comic_changes`（`libraryRevisionProvider` keepAlive 且在
//!   `build()` 内订阅）
//! - 访问首页后 +2：`watch_home_page_counts` / `watch_continue_reading`
//!   （均 keepAlive）
//! - 访问历史页后 +1：`watch_reading_histories`（`readingHistoryChangesStream`
//!   keepAlive）
//! - 访问作者管理页后 +1：`watch_authors`（`allAuthorsProvider` 非 autoDispose）
//! - 无消费方、不计入：`watch_tags`、`watch_home_series_comic_order_map`
//!
//! 即逛过一圈的用户稳定在 **5 条循环 × 2.5 次/秒 = 12.5 次/秒**。

mod common;

use std::time::{Duration, Instant};

use hentai_core::{init_db_at_path, read_data_version, revision};
use tempfile::TempDir;

/// 稳态活跃 watch 循环数量（改造后它们共用一条 poller）。
const WATCH_LOOPS: usize = 5;

#[test]
#[ignore = "measurement only; run manually with --ignored --nocapture"]
fn measure_idle_polling_cost() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");

            // 预热，排除首次连接建立与语句准备的一次性成本。
            for _ in 0..50 {
                read_data_version().await.expect("warmup");
            }

            // 串行基线：单次调用成本。
            const SAMPLES: usize = 2000;
            let started = Instant::now();
            let mut observed = Vec::with_capacity(SAMPLES);
            for _ in 0..SAMPLES {
                observed.push(read_data_version().await.expect("read version"));
            }
            let serial_elapsed = started.elapsed();
            let per_call = serial_elapsed / SAMPLES as u32;

            // 端到端：挂 5 个订阅者模拟稳态，量共享 poller 的真实轮询频率。
            const WINDOW: Duration = Duration::from_secs(4);
            let subscribers: Vec<_> = (0..WATCH_LOOPS).map(|_| revision::subscribe()).collect();
            let before = revision::poll_count();
            tokio::time::sleep(WINDOW).await;
            let polls = revision::poll_count() - before;
            drop(subscribers);
            let measured_rate = polls as f64 / WINDOW.as_secs_f64();

            let distinct = {
                let mut v = observed.clone();
                v.sort_unstable();
                v.dedup();
                v
            };
            let idle_cost_per_sec = per_call.as_secs_f64() * measured_rate;
            let legacy_rate = WATCH_LOOPS as f64 / revision::POLL_INTERVAL.as_secs_f64();

            println!("\n===== read_data_version 空闲开销基线 =====");
            println!("串行 {SAMPLES} 次：总 {serial_elapsed:?}，单次均值 {per_call:?}");
            println!(
                "{WATCH_LOOPS} 个订阅者 / {WINDOW:?} 窗口：实测 {polls} 次轮询 = {measured_rate:.2} 次/秒"
            );
            println!(
                "改造前（每条循环各自轮询）：{legacy_rate:.1} 次/秒 → 降低 {:.1}×",
                legacy_rate / measured_rate.max(f64::MIN_POSITIVE)
            );
            println!(
                "推算空闲 CPU 占用：{:.6} 秒/秒 = {:.4}%",
                idle_cost_per_sec,
                idle_cost_per_sec * 100.0
            );
            println!(
                "空闲期观测到的不同版本值：{}（1 = 零误报 bump）{:?}",
                distinct.len(),
                distinct
            );
            println!("==========================================\n");
        });
    });
}
