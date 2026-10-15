//! 迁移不得把 `foreign_keys=OFF` 的连接留在连接池里。
//!
//! `PRAGMA foreign_keys` 是连接级状态，而迁移拿到的 `SchemaManager` 背后是连接池
//! （sea-orm-migration 只对 Postgres 包事务，SQLite 上每条 execute 各自 acquire）。
//! 若迁移把 `PRAGMA foreign_keys = OFF` 与 `= ON` 拆成两条 execute，二者可能落到不同
//! 连接，被留下 OFF 的连接会随池存活整个进程：其上 `ON DELETE CASCADE` 静默失效，
//! 也会放行违反 FK 的写入。
//!
//! 该污染只在池增长到 ≥2 条连接时发生（修复前用同款检查实测约 1/30 次启动命中，
//! 见 m20261003_000023 / m20250705_000006 的修复），所以本测试是**概率性守卫**：
//! 它不能证明污染不存在，但一旦出现就会被抓住。
//!
//! 修法是让 pragma + DDL 落在同一个多语句串里（`execute_unprepared` 一次 acquire），
//! 参照 m20260801_000011_series_item_sort_order_real.rs。

mod common;

use std::time::Duration;

use sea_orm::{ConnectionTrait, DatabaseBackend, DatabaseTransaction, Statement, TransactionTrait};
use tempfile::TempDir;

#[test]
fn every_pooled_connection_keeps_foreign_keys_enabled() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("temp dir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            hentai_core::init_db_at_path(&db_path)
                .await
                .expect("init db");
            let db = hentai_core::connection().expect("connection");

            // 逐条借出连接直到池被占满，这样池里的每条连接都由我们持有并检查。
            // 池上限 5（db.rs 的 max_connections），借满后再 begin 只会等到超时。
            let mut held: Vec<DatabaseTransaction> = Vec::new();
            for _ in 0..5 {
                match tokio::time::timeout(Duration::from_secs(2), db.begin()).await {
                    Ok(Ok(txn)) => held.push(txn),
                    Ok(Err(err)) => panic!("begin failed: {err}"),
                    Err(_) => break,
                }
            }
            let checked = held.len();
            assert!(checked > 0, "池里至少应有一条连接");

            for (index, txn) in held.iter().enumerate() {
                let fk = foreign_keys(txn).await;
                assert_eq!(
                    fk, 1,
                    "池中第 {index} 条连接（共检查 {checked} 条）的 foreign_keys = {fk}：\
                     迁移把 PRAGMA 与 DDL 拆成了多条 execute，OFF/ON 落到了不同连接"
                );
            }

            for txn in held {
                txn.rollback().await.expect("rollback");
            }
        });
    });
}

async fn foreign_keys(conn: &DatabaseTransaction) -> i64 {
    let stmt = Statement::from_string(DatabaseBackend::Sqlite, "PRAGMA foreign_keys");
    let row = conn
        .query_one(stmt)
        .await
        .expect("pragma query")
        .expect("pragma row");
    row.try_get_by_index::<i64>(0).expect("pragma value")
}
