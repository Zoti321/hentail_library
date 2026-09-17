//! `read_data_version` 作为库变更检测手段的契约。
//!
//! 6 条 watch 循环（`watch_comic_changes` / `watch_home_page_counts` /
//! `watch_continue_reading` / `watch_tags` / `watch_authors` /
//! `watch_reading_histories`）都以「相邻两次 `read_data_version` 不相等」判定
//! 库已变更，因此契约是两条：**写入必须被观测到，且无写入时观测值必须稳定。**
//!
//! 独立事实源（SQLite 官方文档 pragma.html#pragma_data_version）：
//! - 「The `PRAGMA data_version` value is unchanged for commits made on the
//!   same database connection.」
//! - 「The `PRAGMA data_version` value is a local property of each database
//!   connection ... It is only meaningful to compare the `PRAGMA data_version`
//!   values returned by the same database connection at two different points
//!   in time.」
//!
//! 故 `data_version` 必须始终从同一条专用连接读取（`db::version_connection`），
//! 不能从 `max_connections(5)` 的共享池现取——否则比较的是彼此无关的计数器。

mod common;

use hentai_core::{connection, init_db_at_path, read_data_version};
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

fn fixture_db() -> (TempDir, std::path::PathBuf) {
    let temp = TempDir::new().expect("tempdir");
    let db_path = common::create_fixture_db(temp.path());
    (temp, db_path)
}

/// 经由应用连接池提交的写入必须被观测到——否则 watch 循环永远不刷新。
#[test]
fn read_data_version_observes_commit_made_through_the_app_pool() {
    common::with_global_db(|| {
        let (_temp, db_path) = fixture_db();
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");

            let before = read_data_version().await.expect("read version before");
            let db = connection().expect("connection");
            insert_comic(&db, "rev-1").await;
            let after = read_data_version().await.expect("read version after");

            assert_ne!(
                before, after,
                "写入已提交但 data_version 未变化：watch 循环会漏掉这次变更"
            );
        });
    });
}

/// 无任何写入时观测值必须稳定——否则每次轮询都误判「库已变更」。
///
/// 回归防护：改回共享池读取时，本测会观测到多条连接的计数器交替
/// （实测形如 `[30, 45, 30, 45, ...]`）。
#[test]
fn read_data_version_is_stable_without_any_write() {
    common::with_global_db(|| {
        let (_temp, db_path) = fixture_db();
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");

            let mut observed = Vec::new();
            for _ in 0..8 {
                observed.push(read_data_version().await.expect("read version"));
            }

            let first = observed[0];
            assert!(
                observed.iter().all(|v| *v == first),
                "无写入却观测到 data_version 变化，watch 循环会误报重载：{observed:?}"
            );
        });
    });
}

/// 扫描式并发写入结束、回到完全空闲后，观测值必须稳定。
///
/// 库扫描从多条池化连接交错提交，会让各连接的计数器发生分歧。回归防护：改回
/// 共享池读取时本测失败（实测形如 `[5, 7, 5, 8, 5, 5, 7, 5]`），即一次扫描会
/// **永久污染** revision 流——此后即使完全空闲，每次轮询都判定库已变更，
/// 6 条 watch 循环持续全量重载直到进程退出。
#[test]
fn read_data_version_is_stable_after_a_concurrent_write_burst() {
    common::with_global_db(|| {
        let (_temp, db_path) = fixture_db();
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");

            futures::future::join_all((0..6).map(|task| async move {
                let db = connection().expect("connection");
                for seq in 0..5 {
                    insert_comic(&db, &format!("scan-{task}-{seq}")).await;
                }
            }))
            .await;

            let mut observed = Vec::new();
            for _ in 0..8 {
                observed.push(read_data_version().await.expect("read version"));
            }
            let first = observed[0];
            assert!(
                observed.iter().all(|v| *v == first),
                "扫描结束后空闲期仍在交替，revision 流已被永久污染：{observed:?}"
            );
        });
    });
}
