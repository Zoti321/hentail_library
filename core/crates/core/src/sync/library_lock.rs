use std::sync::atomic::{AtomicBool, Ordering};

use crate::error::HentaiError;

static LIBRARY_WRITE_BUSY: AtomicBool = AtomicBool::new(false);

/// 库级写操作互斥（Library sync / Metadata refresh 全局单飞）。
pub struct LibraryWriteGuard;

impl LibraryWriteGuard {
    pub fn try_acquire() -> Result<Self, HentaiError> {
        if LIBRARY_WRITE_BUSY
            .compare_exchange(false, true, Ordering::SeqCst, Ordering::SeqCst)
            .is_err()
        {
            return Err(HentaiError::validation(
                "库写入操作进行中，请稍后再试",
            ));
        }
        Ok(Self)
    }
}

impl Drop for LibraryWriteGuard {
    fn drop(&mut self) {
        LIBRARY_WRITE_BUSY.store(false, Ordering::SeqCst);
    }
}

pub fn try_acquire_library_write_lock() -> Result<LibraryWriteGuard, HentaiError> {
    LibraryWriteGuard::try_acquire()
}
