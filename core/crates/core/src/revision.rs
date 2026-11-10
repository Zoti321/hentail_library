//! 库变更通知的单一来源。
//!
//! 写路径在事务提交（或 autocommit 语句）成功后调用 [`notify_committed`]，
//! 由 [`tokio::sync::watch`] 把单调递增的 generation 广播给全部订阅者。
//!
//! 历史实现轮询 `PRAGMA data_version`（400ms）作为外部事实流；那意味着同一份
//! 事实有两个来源（轮询 + 领域事件），且需要专用连接、连接代号与空闲开销。
//! 现收敛为「写路径显式通知」：跨进程/外部工具直接改库不再被自动感知，
//! 需要感知的入口（如 metadata import）须在完成处显式通知。

use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::OnceLock;

use tokio::sync::watch;

static SENDER: OnceLock<watch::Sender<u64>> = OnceLock::new();
static NOTIFY_COUNT: AtomicU64 = AtomicU64::new(0);

/// 订阅库变更。返回的接收端在写入提交后被唤醒。
///
/// 广播值只是单调递增的代号，仅表示「变了」。
pub fn subscribe() -> watch::Receiver<u64> {
    sender().subscribe()
}

/// 写路径提交成功后调用：唤醒全部订阅者。
///
/// 重复调用是安全的（只多一次重新查询），因此可以在嵌套写路径中宽松调用。
pub fn notify_committed() {
    NOTIFY_COUNT.fetch_add(1, Ordering::Relaxed);
    sender().send_modify(|generation| *generation = generation.wrapping_add(1));
}

/// 诊断用：迄今发生通知的次数。
pub fn notify_count() -> u64 {
    NOTIFY_COUNT.load(Ordering::Relaxed)
}

fn sender() -> &'static watch::Sender<u64> {
    SENDER.get_or_init(|| watch::channel(0).0)
}
