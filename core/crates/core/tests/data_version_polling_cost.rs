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

use hentai_core::{init_db_at_path, read_data_version};
use tempfile::TempDir;

/// 稳态并发轮询者数量。
const WATCH_LOOPS: usize = 5;
/// 每条循环的轮询间隔（`sleep(Duration::from_millis(400))`）。
const POLL_INTERVAL: Duration = Duration::from_millis(400);

fn polls_per_second() -> f64 {
    WATCH_LOOPS as f64 / POLL_INTERVAL.as_secs_f64()
}

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

            // 并发基线：5 条循环同时读，暴露单连接（max_connections(1)）串行化的影响。
            const ROUNDS: usize = 400;
            let concurrent_started = Instant::now();
            for _ in 0..ROUNDS {
                futures::future::join_all(
                    (0..WATCH_LOOPS)
                        .map(|_| async { read_data_version().await.expect("concurrent read") }),
                )
                .await;
            }
            let concurrent_elapsed = concurrent_started.elapsed();
            let per_round = concurrent_elapsed / ROUNDS as u32;
            let per_concurrent_call = concurrent_elapsed / (ROUNDS * WATCH_LOOPS) as u32;

            let distinct = {
                let mut v = observed.clone();
                v.sort_unstable();
                v.dedup();
                v
            };
            let idle_cost_per_sec = per_call.as_secs_f64() * polls_per_second();

            println!("\n===== read_data_version 空闲开销基线 =====");
            println!("串行 {SAMPLES} 次：总 {serial_elapsed:?}，单次均值 {per_call:?}");
            println!(
                "并发 {WATCH_LOOPS} 路 × {ROUNDS} 轮：总 {concurrent_elapsed:?}，\
                 每轮 {per_round:?}，摊到单次 {per_concurrent_call:?}"
            );
            println!(
                "稳态轮询频率：{:.1} 次/秒（{WATCH_LOOPS} 条循环 × {:?} 间隔）",
                polls_per_second(),
                POLL_INTERVAL
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
