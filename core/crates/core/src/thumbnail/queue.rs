use std::collections::{HashMap, HashSet, VecDeque};
use std::sync::Arc;
use std::sync::OnceLock;
use std::time::{Duration, Instant};

use tokio::sync::{broadcast, Mutex, Notify, oneshot};

use crate::comic::find_comic_by_id;
use crate::db::connection;
use crate::error::HentaiError;
use crate::thumbnail::generate::{store_thumbnail_for_comic, thumbnail_needs_generation};
use crate::thumbnail::{ComicThumbnailDto, find_thumbnail_by_comic_id};

const WORKER_COUNT: usize = 2;
const NEGATIVE_CACHE_RETRY: Duration = Duration::from_secs(600);
pub const CRITICAL_WAIT_TIMEOUT: Duration = Duration::from_secs(2);

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum ThumbnailPriority {
    Critical = 0,
    High = 1,
    Low = 2,
}

#[derive(Debug, Clone)]
pub enum ThumbnailEvent {
    Ready { comic_id: String },
    Progress {
        done: i32,
        total: i32,
        failed: i32,
    },
}

#[derive(Debug, Default)]
struct QueueStats {
    total: i32,
    done: i32,
    failed: i32,
}

#[derive(Debug, Default)]
struct QueueInner {
    critical: VecDeque<String>,
    high: VecDeque<String>,
    low: VecDeque<String>,
    priorities: HashMap<String, ThumbnailPriority>,
    in_flight: HashSet<String>,
    negative_cache: HashMap<String, Instant>,
    waiters: HashMap<String, Vec<oneshot::Sender<()>>>,
    stats: QueueStats,
}

impl QueueInner {
    fn deque_for(&mut self, priority: ThumbnailPriority) -> &mut VecDeque<String> {
        match priority {
            ThumbnailPriority::Critical => &mut self.critical,
            ThumbnailPriority::High => &mut self.high,
            ThumbnailPriority::Low => &mut self.low,
        }
    }

    fn remove_from_deques(&mut self, comic_id: &str) {
        self.critical.retain(|id| id != comic_id);
        self.high.retain(|id| id != comic_id);
        self.low.retain(|id| id != comic_id);
    }

    fn pop_next(&mut self) -> Option<(String, ThumbnailPriority)> {
        for (deque, priority) in [
            (&mut self.critical, ThumbnailPriority::Critical),
            (&mut self.high, ThumbnailPriority::High),
            (&mut self.low, ThumbnailPriority::Low),
        ] {
            if let Some(id) = deque.pop_front() {
                self.priorities.remove(&id);
                self.in_flight.insert(id.clone());
                return Some((id, priority));
            }
        }
        None
    }

    fn has_pending(&self) -> bool {
        !self.critical.is_empty() || !self.high.is_empty() || !self.low.is_empty()
    }
}

pub struct ThumbnailQueue {
    inner: Mutex<QueueInner>,
    notify_workers: Notify,
    events: broadcast::Sender<ThumbnailEvent>,
}

impl ThumbnailQueue {
    fn new() -> Self {
        let (events, _) = broadcast::channel(256);
        Self {
            inner: Mutex::new(QueueInner::default()),
            notify_workers: Notify::new(),
            events,
        }
    }

    fn ensure_workers(self: &Arc<Self>) {
        static WORKERS_STARTED: OnceLock<()> = OnceLock::new();
        WORKERS_STARTED.get_or_init(|| {
            for _ in 0..WORKER_COUNT {
                let worker_queue = Arc::clone(self);
                tokio::spawn(async move {
                    worker_queue.worker_loop().await;
                });
            }
        });
    }

    pub fn subscribe(&self) -> broadcast::Receiver<ThumbnailEvent> {
        self.events.subscribe()
    }

    async fn stats_snapshot(&self) -> QueueStats {
        let inner = self.inner.lock().await;
        QueueStats {
            total: inner.stats.total,
            done: inner.stats.done,
            failed: inner.stats.failed,
        }
    }

    async fn worker_loop(self: Arc<Self>) {
        loop {
            let next = {
                let mut inner = self.inner.lock().await;
                inner.pop_next()
            };
            let Some((comic_id, priority)) = next else {
                self.notify_workers.notified().await;
                continue;
            };
            self.process_one(&comic_id, priority).await;
        }
    }

    async fn process_one(self: &Arc<Self>, comic_id: &str, priority: ThumbnailPriority) {
        let force_retry = priority == ThumbnailPriority::Critical;
        let outcome = self.generate_for_comic_id(comic_id, force_retry).await;
        let (ready, progress) = {
            let mut inner = self.inner.lock().await;
            inner.in_flight.remove(comic_id);
            match outcome {
                Ok(true) => {
                    inner.negative_cache.remove(comic_id);
                    inner.stats.done += 1;
                    (true, true)
                }
                Ok(false) => {
                    inner.negative_cache.insert(comic_id.to_string(), Instant::now());
                    inner.stats.failed += 1;
                    inner.stats.done += 1;
                    (false, true)
                }
                Err(_) => {
                    inner.negative_cache.insert(comic_id.to_string(), Instant::now());
                    inner.stats.failed += 1;
                    inner.stats.done += 1;
                    (false, true)
                }
            }
        };
        if progress {
            self.emit_progress().await;
        }
        if ready {
            let _ = self.events.send(ThumbnailEvent::Ready {
                comic_id: comic_id.to_string(),
            });
        }
        self.notify_waiters(comic_id).await;
        let has_pending = {
            let inner = self.inner.lock().await;
            inner.has_pending()
        };
        if has_pending {
            self.notify_workers.notify_one();
        }
    }

    async fn generate_for_comic_id(
        &self,
        comic_id: &str,
        force_retry: bool,
    ) -> Result<bool, HentaiError> {
        let db = connection()?;
        let Some(comic) = find_comic_by_id(comic_id).await? else {
            return Ok(false);
        };
        if !thumbnail_needs_generation(&db, &comic).await? {
            return Ok(true);
        }
        if !force_retry {
            let inner = self.inner.lock().await;
            if let Some(failed_at) = inner.negative_cache.get(comic_id) {
                if failed_at.elapsed() < NEGATIVE_CACHE_RETRY {
                    return Ok(false);
                }
            }
        }
        store_thumbnail_for_comic(&db, &comic).await
    }

    async fn emit_progress(&self) {
        let snapshot = self.stats_snapshot().await;
        let _ = self.events.send(ThumbnailEvent::Progress {
            done: snapshot.done,
            total: snapshot.total,
            failed: snapshot.failed,
        });
    }

    async fn notify_waiters(&self, comic_id: &str) {
        let waiters = {
            let mut inner = self.inner.lock().await;
            inner.waiters.remove(comic_id).unwrap_or_default()
        };
        for waiter in waiters {
            let _ = waiter.send(());
        }
    }

    async fn register_waiter(&self, comic_id: &str) -> oneshot::Receiver<()> {
        let (tx, rx) = oneshot::channel();
        let mut inner = self.inner.lock().await;
        inner.waiters.entry(comic_id.to_string()).or_default().push(tx);
        rx
    }

    async fn enqueue(&self, comic_id: String, priority: ThumbnailPriority) -> bool {
        let mut inner = self.inner.lock().await;
        if inner.in_flight.contains(&comic_id) {
            return inner.has_pending() || !inner.in_flight.is_empty();
        }
        if let Some(existing) = inner.priorities.get(&comic_id).copied() {
            if priority >= existing {
                return inner.has_pending();
            }
            inner.remove_from_deques(&comic_id);
        }
        inner.priorities.insert(comic_id.clone(), priority);
        inner.deque_for(priority).push_back(comic_id);
        inner.has_pending()
    }

    async fn enqueue_batch_low(&self, comic_ids: Vec<String>) {
        let mut inner = self.inner.lock().await;
        let mut newly_added = 0i32;
        for comic_id in comic_ids {
            if inner.priorities.contains_key(&comic_id) || inner.in_flight.contains(&comic_id) {
                continue;
            }
            inner.priorities.insert(comic_id.clone(), ThumbnailPriority::Low);
            inner.low.push_back(comic_id);
            newly_added += 1;
        }
        inner.stats.total += newly_added;
        drop(inner);
        self.emit_progress().await;
        self.notify_workers.notify_waiters();
    }
}

static THUMBNAIL_QUEUE: OnceLock<Arc<ThumbnailQueue>> = OnceLock::new();

pub fn thumbnail_queue() -> Arc<ThumbnailQueue> {
    let queue = THUMBNAIL_QUEUE.get_or_init(|| Arc::new(ThumbnailQueue::new()));
    queue.ensure_workers();
    Arc::clone(queue)
}

pub async fn ensure_thumbnail(
    comic_id: &str,
    priority: ThumbnailPriority,
) -> Result<Option<ComicThumbnailDto>, HentaiError> {
    let queue = thumbnail_queue();
    if let Some(existing) = find_thumbnail_by_comic_id(comic_id).await? {
        return Ok(Some(existing));
    }

    let force_retry = priority == ThumbnailPriority::Critical;
    if !force_retry {
        let inner = queue.inner.lock().await;
        if let Some(failed_at) = inner.negative_cache.get(comic_id) {
            if failed_at.elapsed() < NEGATIVE_CACHE_RETRY {
                return Ok(None);
            }
        }
    }

    let db = connection()?;
    let Some(comic) = find_comic_by_id(comic_id).await? else {
        return Ok(None);
    };
    if !thumbnail_needs_generation(&db, &comic).await? {
        return find_thumbnail_by_comic_id(comic_id).await;
    }

    let has_work = queue.enqueue(comic_id.to_string(), priority).await;
    if has_work {
        queue.notify_workers.notify_waiters();
    }

    if priority != ThumbnailPriority::Critical {
        return Ok(None);
    }

    let rx = queue.register_waiter(comic_id).await;
    tokio::select! {
        _ = tokio::time::sleep(CRITICAL_WAIT_TIMEOUT) => {}
        _ = rx => {}
    }
    find_thumbnail_by_comic_id(comic_id).await
}

pub async fn enqueue_thumbnails_low(comic_ids: Vec<String>) -> Result<(), HentaiError> {
    if comic_ids.is_empty() {
        return Ok(());
    }
    thumbnail_queue().enqueue_batch_low(comic_ids).await;
    Ok(())
}

pub async fn watch_thumbnail_events(
    mut emit: impl FnMut(ThumbnailEvent) -> Result<(), HentaiError>,
) -> Result<(), HentaiError> {
    let queue = thumbnail_queue();
    let mut rx = queue.subscribe();
    let snapshot = queue.stats_snapshot().await;
    emit(ThumbnailEvent::Progress {
        done: snapshot.done,
        total: snapshot.total,
        failed: snapshot.failed,
    })?;
    loop {
        match rx.recv().await {
            Ok(event) => emit(event)?,
            Err(broadcast::error::RecvError::Lagged(_)) => continue,
            Err(broadcast::error::RecvError::Closed) => break,
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn thumbnail_priority_orders_critical_first() {
        assert!(ThumbnailPriority::Critical < ThumbnailPriority::High);
        assert!(ThumbnailPriority::High < ThumbnailPriority::Low);
    }
}
