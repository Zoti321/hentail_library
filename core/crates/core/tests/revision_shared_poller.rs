//! 共享 revision poller 的契约。
//!
//! 改造前每条 watch 循环各自 `sleep(400ms)` + `read_data_version()`，稳态 5 条
//! 循环即 12.5 次查询/秒。改造后所有订阅者共用一条 poller，查询频率恒为
//! 2.5 次/秒，且不随订阅者数量增长。

mod common;

use std::time::Duration;

use hentai_core::{connection, init_db_at_path, revision};
use sea_orm::{ConnectionTrait, DatabaseConnection, Statement};
use tempfile::TempDir;

async fn insert_comic(db: &DatabaseConnection, comic_id: &str) {
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        format!(
            "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
             VALUES ('{comic_id}', 'E:/lib/{comic_id}.cbz', 'cbz', 1, 1, 1)"
        ),
    ))
    .await
    .expect("insert comic");
}

/// 轮询频率不随订阅者数量增长——这是本次改造的全部意义。
///
/// 差分测量：同样长度的窗口内，1 个订阅者与 8 个订阅者产生的轮询次数必须相当。
/// 若每个订阅者各自轮询（改造前的形态），8 路会是 1 路的约 8 倍。
#[test]
fn poll_rate_does_not_grow_with_subscriber_count() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");

            const WINDOW: Duration = Duration::from_millis(1600);

            let single = revision::subscribe();
            let before_single = revision::poll_count();
            tokio::time::sleep(WINDOW).await;
            let single_polls = revision::poll_count() - before_single;
            drop(single);

            let many: Vec<_> = (0..8).map(|_| revision::subscribe()).collect();
            let before_many = revision::poll_count();
            tokio::time::sleep(WINDOW).await;
            let many_polls = revision::poll_count() - before_many;
            drop(many);

            assert!(
                single_polls > 0,
                "poller 未运行：窗口内零次轮询（订阅应当启动 poller）"
            );
            assert!(
                many_polls <= single_polls + 2,
                "轮询次数随订阅者数量增长：1 路 {single_polls} 次，8 路 {many_polls} 次"
            );
        });
    });
}

/// 一次写入必须唤醒所有订阅者（广播语义，不是「只唤醒一个」）。
#[test]
fn a_single_commit_wakes_every_subscriber() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");

            let mut subscribers: Vec<_> = (0..4).map(|_| revision::subscribe()).collect();

            let db = connection().expect("connection");
            insert_comic(&db, "broadcast-1").await;

            for (index, rx) in subscribers.iter_mut().enumerate() {
                let woken = tokio::time::timeout(Duration::from_secs(5), rx.changed()).await;
                assert!(
                    matches!(woken, Ok(Ok(()))),
                    "第 {index} 个订阅者未被写入唤醒：{woken:?}"
                );
            }
        });
    });
}

/// 订阅者全部离开后必须停止观测——共享 poller 不应在无人监听时继续查库。
#[test]
fn observation_stops_when_no_subscriber_remains() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");

            // 先订阅一次以启动 poller，再全部释放。
            drop(revision::subscribe());
            tokio::time::sleep(Duration::from_millis(800)).await;

            let idle_before = revision::poll_count();
            tokio::time::sleep(Duration::from_millis(1600)).await;
            let idle_polls = revision::poll_count() - idle_before;

            assert_eq!(
                idle_polls, 0,
                "无订阅者时仍在观测 data_version：{idle_polls} 次"
            );
        });
    });
}

/// 无写入时订阅者不得被唤醒——否则退回成本次修复前的误报重载。
#[test]
fn subscribers_are_not_woken_without_a_commit() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");

            let mut rx = revision::subscribe();
            let woken = tokio::time::timeout(Duration::from_millis(1600), rx.changed()).await;

            assert!(
                woken.is_err(),
                "无写入却被唤醒，watch 循环会空转重载：{woken:?}"
            );
        });
    });
}
