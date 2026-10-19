//! Library-level write seam (ADR-0026): the one place that owns the library write
//! lock, and the transaction boundary for cross-comic bulk writes.
//!
//! Policy:
//! - Cross-comic bulk library writes hold the lock: library sync, metadata refresh,
//!   trash / restore / purge, metadata-backup import, and the bulk dictionary /
//!   facet / reading-history operations.
//!
//! Held-lock entry points (keep in sync with ADR-0026):
//! `sync_library`, `refresh_comic_metadata`, `refresh_series_metadata`,
//! `refresh_library_metadata`, `apply_comic_metadata_bulk_patch`, `trash_comics`,
//! `restore_comics`, `purge_comics`, `update_local_library_root`,
//! `import_comic_metadata`, `rename_tag`, `delete_tags_by_names`, `rename_author`,
//! `delete_authors_by_names`, `rename_named_facet_name`, `delete_named_facet_by_names`,
//! `merge_named_facet_name`, `clear_all_reading`.
//! - Single-comic user writes do not take the lock, so one comic stays editable
//!   while a library sync runs.
//! - Single-flight and fail-fast: a second acquisition fails with
//!   [`HentaiError::validation`] (`"库写入操作进行中，请稍后再试"`). There is no queueing
//!   and no re-entrancy detection, so an entry point that already holds the lock
//!   must delegate to the matching `*_locked` body instead of calling another
//!   public entry point.
//!
//! Two entry points:
//! - [`with_library_write`] holds the lock for the whole body; the body keeps its own
//!   transaction granularity (per library, per comic, ...).
//! - [`begin_library_write_txn`] holds the lock and opens one transaction. Dropping the
//!   session without [`LibraryWriteTxn::commit`] rolls that transaction back and
//!   releases the lock.
//!
//! Naming note: the `*_locked` suffix in this module means "already holds the library
//! write lock". It is unrelated to the Metadata field lock suffix of the same spelling
//! (`set_series_item_sort_order_locked`).

use std::future::Future;
use std::sync::atomic::{AtomicBool, Ordering};

use sea_orm::{DatabaseTransaction, TransactionTrait};

use crate::db::{connection, map_db_err};
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
            return Err(HentaiError::validation("库写入操作进行中，请稍后再试"));
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

/// 持锁执行 `f`；锁在 `f` 返回（含错误返回）后释放。
pub async fn with_library_write<T, F, Fut>(f: F) -> Result<T, HentaiError>
where
    F: FnOnce() -> Fut,
    Fut: Future<Output = Result<T, HentaiError>>,
{
    let _guard = try_acquire_library_write_lock()?;
    f().await
}

/// 持锁 + 单一事务的写会话。
///
/// 需要确定性回滚时调用 [`LibraryWriteTxn::rollback`]；未调用 `commit` / `rollback`
/// 就 drop 时，字段声明顺序保证先由 sea-orm 触发事务回滚（未提交改动对其它连接不可见，
/// 连接回收后真正回滚），随后才释放库级写锁。
#[must_use = "LibraryWriteTxn 未 commit 时会在 drop 回滚"]
pub struct LibraryWriteTxn {
    /// 声明在 `_guard` 之前：结构体字段按声明顺序 drop，事务必须先于锁释放。
    txn: DatabaseTransaction,
    _guard: LibraryWriteGuard,
}

impl LibraryWriteTxn {
    /// 事务句柄，供接收 `ConnectionTrait` 的写路径使用。
    pub fn txn(&self) -> &DatabaseTransaction {
        &self.txn
    }

    pub async fn commit(self) -> Result<(), HentaiError> {
        self.txn.commit().await.map_err(map_db_err)
    }

    /// 显式回滚（等价于未提交就 drop，但回滚在本调用内完成）。
    pub async fn rollback(self) -> Result<(), HentaiError> {
        self.txn.rollback().await.map_err(map_db_err)
    }
}

pub async fn begin_library_write_txn() -> Result<LibraryWriteTxn, HentaiError> {
    let guard = try_acquire_library_write_lock()?;
    let db = connection()?;
    let txn = db.begin().await.map_err(map_db_err)?;
    Ok(LibraryWriteTxn { txn, _guard: guard })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn seam_is_single_flight_and_releases_the_lock() {
        let guard = try_acquire_library_write_lock().expect("first acquire");
        assert!(try_acquire_library_write_lock().is_err());
        drop(guard);
        try_acquire_library_write_lock().expect("acquire after release");

        with_library_write(|| async {
            assert!(
                try_acquire_library_write_lock().is_err(),
                "body runs under the lock"
            );
            Err::<(), _>(HentaiError::validation("boom"))
        })
        .await
        .expect_err("body error propagates");
        try_acquire_library_write_lock().expect("released after error");
    }
}
