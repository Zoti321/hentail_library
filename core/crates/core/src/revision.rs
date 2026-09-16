//! 库变更通知的单一来源。
//!
//! 一条后台 poller 观测 `PRAGMA data_version`，变化时通过 [`tokio::sync::watch`]
//! 广播给全部订阅者。各 watch 循环订阅它而非自行轮询——否则轮询频率会随订阅者
//! 数量线性增长（稳态 5 条循环即 12.5 次查询/秒）。
//!
//! 为何不做成写路径显式 bump：实测轮询的空闲开销约 0.13% CPU
//! （见 `tests/data_version_polling_cost.rs`），不足以支撑「所有写路径都必须
//! 记得 bump」的正确性风险——漏一处会导致长期陈旧，比漏一拍严重。

use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::OnceLock;
use std::time::Duration;

use tokio::sync::watch;

/// poller 的观测间隔。
pub const POLL_INTERVAL: Duration = Duration::from_millis(400);

static SENDER: OnceLock<watch::Sender<u64>> = OnceLock::new();
static POLLER: OnceLock<()> = OnceLock::new();
static POLL_COUNT: AtomicU64 = AtomicU64::new(0);

/// 订阅库变更。返回的接收端在库发生变更时被唤醒；首次订阅会启动 poller。
///
/// 广播的是单调递增的代号（generation），仅表示「变了」——不要把它当成
/// `data_version` 本身，后者是连接局部计数器，跨连接比较无意义。
pub fn subscribe() -> watch::Receiver<u64> {
    let sender = sender();
    start_poller();
    sender.subscribe()
}

/// 诊断用：poller 迄今真正查询 `data_version` 的次数（无订阅者时不计）。
pub fn poll_count() -> u64 {
    POLL_COUNT.load(Ordering::Relaxed)
}

fn sender() -> &'static watch::Sender<u64> {
    SENDER.get_or_init(|| watch::channel(0).0)
}

fn start_poller() {
    POLLER.get_or_init(|| {
        crate::runtime::runtime().spawn(poll_loop());
    });
}

async fn poll_loop() {
    let sender = sender();
    // init_db 可能尚未调用，此时先记 None，待首次读成功再作为基线（不视为变更）。
    let mut last: Option<i32> = crate::comic::read_data_version().await.ok();

    loop {
        tokio::time::sleep(POLL_INTERVAL).await;

        // 无人监听时不查库；下次有订阅者再恢复。
        if sender.receiver_count() == 0 {
            continue;
        }
        POLL_COUNT.fetch_add(1, Ordering::Relaxed);

        let Ok(version) = crate::comic::read_data_version().await else {
            continue;
        };
        match last {
            None => last = Some(version),
            Some(previous) if previous != version => {
                last = Some(version);
                sender.send_modify(|generation| *generation = generation.wrapping_add(1));
            }
            Some(_) => {}
        }
    }
}
