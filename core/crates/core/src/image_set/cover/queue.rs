use std::collections::{HashMap, HashSet, VecDeque};
use std::sync::Arc;
use std::sync::OnceLock;
use std::time::{Duration, Instant};

use tokio::sync::{broadcast, oneshot, Mutex, Notify};

use crate::error::HentaiError;
use crate::thumbnail::ThumbnailPriority;

use super::{
    find_image_set_cover, image_set_cover_needs_generation, store_image_set_cover, ImageSetCoverDto,
};

const WORKER_COUNT: usize = 2;
const NEGATIVE_CACHE_RETRY: Duration = Duration::from_secs(600);
const CRITICAL_WAIT_TIMEOUT: Duration = Duration::from_secs(2);

#[derive(Debug, Clone)]
pub enum ImageSetCoverEvent {
    Ready {
        image_set_id: String,
        thumbnail: Option<Vec<u8>>,
    },
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

#[derive(Debug, Clone, Hash, PartialEq, Eq)]
struct CoverJobKey {
    library_id: String,
    image_set_id: String,
}

#[derive(Debug, Default)]
struct QueueInner {
    critical: VecDeque<CoverJobKey>,
    high: VecDeque<CoverJobKey>,
    low: VecDeque<CoverJobKey>,
    priorities: HashMap<CoverJobKey, ThumbnailPriority>,
    in_flight: HashSet<CoverJobKey>,
    negative_cache: HashMap<String, Instant>,
    waiters: HashMap<String, Vec<oneshot::Sender<()>>>,
    stats: QueueStats,
}

impl QueueInner {
    fn deque_for(&mut self, priority: ThumbnailPriority) -> &mut VecDeque<CoverJobKey> {
        match priority {
            ThumbnailPriority::Critical => &mut self.critical,
            ThumbnailPriority::High => &mut self.high,
            ThumbnailPriority::Low => &mut self.low,
        }
    }

    fn remove_from_deques(&mut self, key: &CoverJobKey) {
        self.critical.retain(|k| k != key);
        self.high.retain(|k| k != key);
        self.low.retain(|k| k != key);
    }

    fn pop_next(&mut self) -> Option<(CoverJobKey, ThumbnailPriority)> {
        for (deque, priority) in [
            (&mut self.critical, ThumbnailPriority::Critical),
            (&mut self.high, ThumbnailPriority::High),
            (&mut self.low, ThumbnailPriority::Low),
        ] {
            if let Some(key) = deque.pop_front() {
                self.priorities.remove(&key);
                self.in_flight.insert(key.clone());
                return Some((key, priority));
            }
        }
        None
    }

    fn has_pending(&self) -> bool {
        !self.critical.is_empty() || !self.high.is_empty() || !self.low.is_empty()
    }
}

struct CoverQueue {
    inner: Mutex<QueueInner>,
    notify_workers: Notify,
    events: broadcast::Sender<ImageSetCoverEvent>,
}

impl CoverQueue {
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

    fn subscribe(&self) -> broadcast::Receiver<ImageSetCoverEvent> {
        self.events.subscribe()
    }

    async fn worker_loop(self: Arc<Self>) {
        loop {
            let next = {
                let mut inner = self.inner.lock().await;
                inner.pop_next()
            };
            let Some((key, priority)) = next else {
                self.notify_workers.notified().await;
                continue;
            };
            self.process_one(key, priority).await;
        }
    }

    async fn process_one(self: &Arc<Self>, key: CoverJobKey, priority: ThumbnailPriority) {
        let force_retry = priority == ThumbnailPriority::Critical;
        let outcome = self
            .generate_one(&key.library_id, &key.image_set_id, force_retry)
            .await;
        let (ready_bytes, progress) = {
            let mut inner = self.inner.lock().await;
            inner.in_flight.remove(&key);
            match outcome {
                Ok(Some(bytes)) => {
                    inner.negative_cache.remove(&key.image_set_id);
                    inner.stats.done += 1;
                    (Some(bytes), true)
                }
                Ok(None) | Err(_) => {
                    inner
                        .negative_cache
                        .insert(key.image_set_id.clone(), Instant::now());
                    inner.stats.failed += 1;
                    inner.stats.done += 1;
                    (None, true)
                }
            }
        };
        if progress {
            let snapshot = {
                let inner = self.inner.lock().await;
                QueueStats {
                    total: inner.stats.total,
                    done: inner.stats.done,
                    failed: inner.stats.failed,
                }
            };
            let _ = self.events.send(ImageSetCoverEvent::Progress {
                done: snapshot.done,
                total: snapshot.total,
                failed: snapshot.failed,
            });
        }
        if let Some(thumbnail) = ready_bytes {
            let _ = self.events.send(ImageSetCoverEvent::Ready {
                image_set_id: key.image_set_id.clone(),
                thumbnail: Some(thumbnail),
            });
        }
        let waiters = {
            let mut inner = self.inner.lock().await;
            inner.waiters.remove(&key.image_set_id).unwrap_or_default()
        };
        for waiter in waiters {
            let _ = waiter.send(());
        }
        let has_pending = {
            let inner = self.inner.lock().await;
            inner.has_pending()
        };
        if has_pending {
            self.notify_workers.notify_one();
        }
    }

    async fn generate_one(
        &self,
        library_id: &str,
        image_set_id: &str,
        force_retry: bool,
    ) -> Result<Option<Vec<u8>>, HentaiError> {
        if !image_set_cover_needs_generation(library_id, image_set_id).await? {
            return Ok(find_image_set_cover(image_set_id)
                .await?
                .map(|row| row.thumbnail));
        }
        if !force_retry {
            let inner = self.inner.lock().await;
            if let Some(failed_at) = inner.negative_cache.get(image_set_id) {
                if failed_at.elapsed() < NEGATIVE_CACHE_RETRY {
                    return Ok(None);
                }
            }
        }
        store_image_set_cover(library_id, image_set_id).await
    }

    async fn enqueue(&self, key: CoverJobKey, priority: ThumbnailPriority) -> bool {
        let mut inner = self.inner.lock().await;
        if inner.in_flight.contains(&key) {
            return inner.has_pending() || !inner.in_flight.is_empty();
        }
        if let Some(existing) = inner.priorities.get(&key).copied() {
            if priority >= existing {
                return inner.has_pending();
            }
            inner.remove_from_deques(&key);
        }
        inner.priorities.insert(key.clone(), priority);
        inner.deque_for(priority).push_back(key);
        inner.has_pending()
    }

    async fn enqueue_batch_low(&self, jobs: Vec<(String, String)>) {
        let mut inner = self.inner.lock().await;
        let mut newly_added = 0i32;
        for (library_id, image_set_id) in jobs {
            let key = CoverJobKey {
                library_id,
                image_set_id,
            };
            if inner.priorities.contains_key(&key) || inner.in_flight.contains(&key) {
                continue;
            }
            inner
                .priorities
                .insert(key.clone(), ThumbnailPriority::Low);
            inner.low.push_back(key);
            newly_added += 1;
        }
        inner.stats.total += newly_added;
        drop(inner);
        let snapshot = {
            let inner = self.inner.lock().await;
            QueueStats {
                total: inner.stats.total,
                done: inner.stats.done,
                failed: inner.stats.failed,
            }
        };
        let _ = self.events.send(ImageSetCoverEvent::Progress {
            done: snapshot.done,
            total: snapshot.total,
            failed: snapshot.failed,
        });
        self.notify_workers.notify_waiters();
    }

    async fn register_waiter(&self, image_set_id: &str) -> oneshot::Receiver<()> {
        let (tx, rx) = oneshot::channel();
        let mut inner = self.inner.lock().await;
        inner
            .waiters
            .entry(image_set_id.to_string())
            .or_default()
            .push(tx);
        rx
    }
}

static COVER_QUEUE: OnceLock<Arc<CoverQueue>> = OnceLock::new();

fn cover_queue() -> Arc<CoverQueue> {
    let queue = COVER_QUEUE.get_or_init(|| Arc::new(CoverQueue::new()));
    queue.ensure_workers();
    Arc::clone(queue)
}

pub async fn ensure_image_set_cover(
    library_id: &str,
    image_set_id: &str,
    priority: ThumbnailPriority,
) -> Result<Option<ImageSetCoverDto>, HentaiError> {
    let queue = cover_queue();
    if let Some(existing) = find_image_set_cover(image_set_id).await? {
        if !image_set_cover_needs_generation(library_id, image_set_id).await? {
            return Ok(Some(existing));
        }
    }

    let force_retry = priority == ThumbnailPriority::Critical;
    if !force_retry {
        let inner = queue.inner.lock().await;
        if let Some(failed_at) = inner.negative_cache.get(image_set_id) {
            if failed_at.elapsed() < NEGATIVE_CACHE_RETRY {
                return Ok(None);
            }
        }
    }

    if !image_set_cover_needs_generation(library_id, image_set_id).await? {
        return find_image_set_cover(image_set_id).await;
    }

    let key = CoverJobKey {
        library_id: library_id.to_string(),
        image_set_id: image_set_id.to_string(),
    };
    let has_work = queue.enqueue(key, priority).await;
    if has_work {
        queue.notify_workers.notify_waiters();
    }

    if priority != ThumbnailPriority::Critical {
        return Ok(None);
    }

    let rx = queue.register_waiter(image_set_id).await;
    tokio::select! {
        () = tokio::time::sleep(CRITICAL_WAIT_TIMEOUT) => {}
        _ = rx => {}
    }
    find_image_set_cover(image_set_id).await
}

pub async fn enqueue_image_set_covers_low(
    jobs: Vec<(String, String)>,
) -> Result<(), HentaiError> {
    if jobs.is_empty() {
        return Ok(());
    }
    cover_queue().enqueue_batch_low(jobs).await;
    Ok(())
}

pub async fn watch_image_set_cover_events(
    mut emit: impl FnMut(ImageSetCoverEvent) -> Result<(), HentaiError>,
) -> Result<(), HentaiError> {
    let queue = cover_queue();
    let mut rx = queue.subscribe();
    let snapshot = {
        let inner = queue.inner.lock().await;
        QueueStats {
            total: inner.stats.total,
            done: inner.stats.done,
            failed: inner.stats.failed,
        }
    };
    emit(ImageSetCoverEvent::Progress {
        done: snapshot.done,
        total: snapshot.total,
        failed: snapshot.failed,
    })?;
    loop {
        match rx.recv().await {
            Ok(event) => emit(event)?,
            Err(broadcast::error::RecvError::Lagged(_)) => {}
            Err(broadcast::error::RecvError::Closed) => break,
        }
    }
    Ok(())
}
