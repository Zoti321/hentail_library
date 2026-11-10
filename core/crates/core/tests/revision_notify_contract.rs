//! Revision 通知的契约：写路径提交后必须唤醒订阅者。
//!
//! 改造后不再轮询 `PRAGMA data_version`，watch 流完全依赖写路径显式
//! `revision::notify_committed()`。本测试按写入类别逐一断言 generation 递增，
//! 防止新增/重构写路径时漏通知导致 UI 长期陈旧。

mod common;

use std::path::Path;
use std::time::Duration;

use hentai_core::history::ReadingHistoryDto;
use hentai_core::named_facet::JunctionNamedFacet;
use hentai_core::revision;
use hentai_core::{create_local_library, init_db_at_path, record_reading, trash_comics};

/// 运行一次写入，断言它至少触发一次通知并把 generation 推给已有订阅者。
fn assert_write_notifies<T>(
    label: &str,
    write: impl std::future::Future<Output = Result<T, hentai_core::HentaiError>>,
) -> T {
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        let mut receiver = revision::subscribe();
        let before = revision::notify_count();
        let value = write.await.unwrap_or_else(|e| panic!("{label} 失败: {e}"));
        assert!(
            revision::notify_count() > before,
            "{label} 提交后未通知 revision：watch 流不会刷新"
        );
        tokio::time::timeout(Duration::from_millis(500), receiver.changed())
            .await
            .unwrap_or_else(|_| panic!("{label} 的通知未到达订阅者"))
            .unwrap_or_else(|_| panic!("{label} 通知期间 sender 已关闭"));
        value
    })
}

fn init_fixture() -> tempfile::TempDir {
    let temp = tempfile::TempDir::new().expect("tempdir");
    let db_path = common::create_fixture_db(temp.path());
    tokio::runtime::Runtime::new()
        .expect("runtime")
        .block_on(init_db_at_path(&db_path))
        .expect("init_db");
    temp
}

#[test]
fn raw_notify_reaches_every_subscriber() {
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        let mut first = revision::subscribe();
        let mut second = revision::subscribe();
        let before = revision::notify_count();
        revision::notify_committed();
        assert!(revision::notify_count() > before);
        for (name, receiver) in [("first", &mut first), ("second", &mut second)] {
            tokio::time::timeout(Duration::from_millis(500), receiver.changed())
                .await
                .unwrap_or_else(|_| panic!("{name} 未收到通知"))
                .expect("sender alive");
        }
    });
}

#[test]
fn reading_progress_write_notifies() {
    common::with_global_db(|| {
        let _temp = init_fixture();
        assert_write_notifies(
            "record_reading",
            record_reading(&ReadingHistoryDto {
                comic_id: "rev-progress".to_string(),
                title: "progress".to_string(),
                last_read_time_ms: 1,
                page_index: Some(0),
                page_count: None,
            }),
        );
    });
}

#[test]
fn named_facet_write_notifies() {
    common::with_global_db(|| {
        let _temp = init_fixture();
        assert_write_notifies(
            "add_named_facet_name",
            hentai_core::add_named_facet_name(JunctionNamedFacet::Tag, "rev-tag"),
        );
    });
}

#[test]
fn library_create_notifies() {
    common::with_global_db(|| {
        let temp = init_fixture();
        let root = Path::new(temp.path()).join("library-root");
        let root = root.to_string_lossy().to_string();
        assert_write_notifies("create_local_library", create_local_library(&root, None));
    });
}

#[test]
fn trash_commit_notifies() {
    common::with_global_db(|| {
        let _temp = init_fixture();
        assert_write_notifies(
            "trash_comics",
            trash_comics(vec!["rev-missing-comic".to_string()]),
        );
    });
}
