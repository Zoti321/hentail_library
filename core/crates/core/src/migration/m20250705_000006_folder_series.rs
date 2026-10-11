use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

const SQL_CREATE_SERIES: &str = r#"
CREATE TABLE IF NOT EXISTS series (
  series_id TEXT NOT NULL PRIMARY KEY,
  folder_path TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  serialization_status TEXT NOT NULL DEFAULT 'unknown'
    CHECK (serialization_status IN ('unknown', 'ongoing', 'ended', 'hiatus')),
  total_count INTEGER NULL CHECK (total_count IS NULL OR total_count > 0)
)
"#;

const SQL_CREATE_SERIES_ITEMS: &str = r#"
CREATE TABLE IF NOT EXISTS series_items (
  series_id TEXT NOT NULL,
  comic_id TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  PRIMARY KEY (series_id, comic_id),
  UNIQUE (comic_id),
  FOREIGN KEY (series_id) REFERENCES series(series_id) ON DELETE CASCADE,
  FOREIGN KEY (comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE
)
"#;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let conn = manager.get_connection();

        if !table_exists(manager, "series").await? {
            conn.execute_unprepared(SQL_CREATE_SERIES).await?;
            conn.execute_unprepared(SQL_CREATE_SERIES_ITEMS).await?;
            return Ok(());
        }

        // 清空 + 重建必须在**同一个连接**上完成：`PRAGMA foreign_keys` 是连接级状态，而
        // SchemaManager 背后是连接池（sea-orm-migration 只对 Postgres 包事务，SQLite 上
        // 每条 execute 各自 acquire）。逐条 execute 会让 OFF/ON 落到不同连接，把
        // `foreign_keys=OFF` 的连接留在池里，之后该连接上 `ON DELETE CASCADE` 静默失效。
        // 因此与 m20260801_000011 一致：pragma + DDL 合成一个多语句串（一次 acquire）。
        let sql = format!(
            "DELETE FROM series_items;
DELETE FROM series;
PRAGMA foreign_keys = OFF;
DROP TABLE IF EXISTS series_items;
DROP TABLE IF EXISTS series;
{};
{};
PRAGMA foreign_keys = ON",
            SQL_CREATE_SERIES.trim(),
            SQL_CREATE_SERIES_ITEMS.trim()
        );
        conn.execute_unprepared(&sql).await?;

        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}

async fn table_exists(manager: &SchemaManager<'_>, table: &str) -> Result<bool, DbErr> {
    let stmt = Statement::from_string(
        manager.get_database_backend(),
        format!("SELECT 1 FROM sqlite_master WHERE type='table' AND name='{table}' LIMIT 1"),
    );
    Ok(manager.get_connection().query_one(stmt).await?.is_some())
}
