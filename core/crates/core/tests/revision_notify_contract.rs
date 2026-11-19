#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

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

fn with_retained_dictionary_db(test: impl FnOnce(&tokio::runtime::Runtime)) {
    common::with_global_db(|| {
        // Retain test files for manual cleanup under the repository removal policy.
        let temp = tempfile::tempdir().expect("tempdir").keep();
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime
            .block_on(init_db_at_path(&temp.join("dictionary-delete.sqlite")))
            .expect("init database");
        test(&runtime);
    });
}

#[test]
fn dictionary_delete_notifies_subscribers_once_after_success() {
    with_retained_dictionary_db(|runtime| {
        runtime.block_on(async {
            for facet in [
                JunctionNamedFacet::Tag,
                JunctionNamedFacet::Parody,
                JunctionNamedFacet::Character,
            ] {
                hentai_core::add_named_facet_name(facet, "remove-me")
                    .await
                    .expect("seed dictionary name");
                let notifications = revision::notify_count();
                let changes = revision::subscribe();

                hentai_core::delete_named_facet_by_names(facet, vec!["remove-me".to_string()])
                    .await
                    .expect("delete dictionary name");

                assert!(!hentai_core::list_all_named_facet_names(facet)
                    .await
                    .expect("remaining names")
                    .contains(&"remove-me".to_string()));
                assert_eq!(revision::notify_count(), notifications + 1, "{facet:?}");
                assert!(
                    changes.has_changed().expect("revision remains open"),
                    "{facet:?}"
                );
            }
        });
    });
}

#[test]
fn dictionary_delete_missing_name_notifies_but_empty_request_does_not() {
    with_retained_dictionary_db(|runtime| {
        runtime.block_on(async {
            let notifications = revision::notify_count();
            let changes = revision::subscribe();
            hentai_core::delete_named_facet_by_names(JunctionNamedFacet::Tag, Vec::new())
                .await
                .expect("empty request");
            assert_eq!(revision::notify_count(), notifications);
            assert!(!changes.has_changed().expect("revision remains open"));

            hentai_core::delete_named_facet_by_names(
                JunctionNamedFacet::Tag,
                vec!["missing".to_string()],
            )
            .await
            .expect("idempotent deletion");
            assert_eq!(revision::notify_count(), notifications + 1);
            assert!(changes.has_changed().expect("revision remains open"));
        });
    });
}

#[test]
fn dictionary_delete_sql_failure_keeps_names_without_notification() {
    use sea_orm::ConnectionTrait;

    with_retained_dictionary_db(|runtime| {
        runtime.block_on(async {
            let db = hentai_core::connection().expect("connection");
            for facet in [
                JunctionNamedFacet::Tag,
                JunctionNamedFacet::Parody,
                JunctionNamedFacet::Character,
            ] {
                hentai_core::add_named_facet_name(facet, "retained")
                    .await
                    .expect("seed dictionary name");
                // SQLite trigger names are DB-global; keep one unique name per facet table.
                let trigger = format!("block_dictionary_delete_{}", facet.dict_table());
                db.execute_unprepared(&format!(
                    "CREATE TRIGGER {trigger} BEFORE DELETE ON {} \
                     BEGIN SELECT RAISE(ABORT, 'dictionary delete blocked'); END",
                    facet.dict_table(),
                ))
                .await
                .expect("inject deletion failure");
                let notifications = revision::notify_count();
                let changes = revision::subscribe();

                let error =
                    hentai_core::delete_named_facet_by_names(facet, vec!["retained".to_string()])
                        .await
                        .expect_err("dictionary deletion fails");

                assert!(
                    error.message.contains("dictionary delete blocked"),
                    "{error:?}"
                );
                assert!(hentai_core::list_all_named_facet_names(facet)
                    .await
                    .expect("retained names")
                    .contains(&"retained".to_string()));
                assert_eq!(revision::notify_count(), notifications);
                assert!(!changes.has_changed().expect("revision remains open"));
                db.execute_unprepared(&format!("DROP TRIGGER IF EXISTS {trigger}"))
                    .await
                    .expect("remove injected failure");
                hentai_core::delete_named_facet_by_names(facet, vec!["retained".to_string()])
                    .await
                    .expect("new deletion succeeds and lock was released");
                assert_eq!(revision::notify_count(), notifications + 1);
            }
        });
    });
}
