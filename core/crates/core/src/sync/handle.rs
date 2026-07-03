use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};

#[derive(Clone)]
pub struct SyncHandle {
    pub(crate) cancelled: Arc<AtomicBool>,
}

pub fn create_sync_handle() -> SyncHandle {
    SyncHandle {
        cancelled: Arc::new(AtomicBool::new(false)),
    }
}

pub fn cancel_sync(handle: &SyncHandle) {
    handle.cancelled.store(true, Ordering::Relaxed);
}

impl SyncHandle {
    pub fn is_cancelled(&self) -> bool {
        self.cancelled.load(Ordering::Relaxed)
    }
}
