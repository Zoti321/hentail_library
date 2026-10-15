use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::prelude::*;

/// Author 稳定身份：`authors.id` + `comic_authors.author_id` + `author_links`（ADR-0024）。
#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        if !table_exists(manager, "authors").await? {
            return Ok(());
        }
        let connection = manager.get_connection();
        if !column_exists(manager, "authors", "id").await? {
            migrate_name_keyed_authors(connection).await?;
        }
        connection
            .execute_unprepared(
                "CREATE TABLE IF NOT EXISTS author_links (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  author_id INTEGER NOT NULL,
  platform TEXT NOT NULL,
  url TEXT NOT NULL,
  platform_display_name TEXT,
  sort_key INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(author_id) REFERENCES authors(id) ON DELETE CASCADE
)",
            )
            .await?;
        connection
            .execute_unprepared(
                "CREATE INDEX IF NOT EXISTS idx_author_links_author_id ON author_links (author_id)",
            )
            .await?;
        connection
            .execute_unprepared(
                "CREATE INDEX IF NOT EXISTS idx_comic_authors_author_id ON comic_authors (author_id)",
            )
            .await?;
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}

async fn migrate_name_keyed_authors(connection: &impl ConnectionTrait) -> Result<(), DbErr> {
    // 清空 + 重建必须在**同一个连接**上完成：`PRAGMA foreign_keys` 是连接级状态，而
    // SchemaManager 背后是连接池（sea-orm-migration 只对 Postgres 包事务，SQLite 上
    // 每条 execute 各自 acquire）。逐条 execute 会让 OFF/ON 落到不同连接，把
    // `foreign_keys=OFF` 的连接留在池里，之后该连接上 `ON DELETE CASCADE` 静默失效。
    // 因此与 m20260801_000011 一致：pragma + DDL 合成一个多语句串（一次 acquire）。
    // 语句里用到的分支条件必须先在这条连接上查清，不能在批中插入读查询。
    let comic_authors_exists = table_exists_on(connection, "comic_authors").await?;
    let mut sql = String::from(
        "PRAGMA foreign_keys = OFF;
CREATE TABLE IF NOT EXISTS _author_names_mig (name TEXT NOT NULL);
DELETE FROM _author_names_mig;
INSERT INTO _author_names_mig (name) SELECT name FROM authors;
CREATE TABLE IF NOT EXISTS _comic_authors_mig (
  comic_id TEXT NOT NULL,
  author_name TEXT NOT NULL
);
DELETE FROM _comic_authors_mig;",
    );
    if comic_authors_exists {
        sql.push_str(
            "
INSERT INTO _comic_authors_mig (comic_id, author_name)
SELECT comic_id, author_name FROM comic_authors;
DROP TABLE comic_authors;",
        );
    }
    sql.push_str(
        "
DROP TABLE authors;
CREATE TABLE authors (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name TEXT NOT NULL UNIQUE
);
INSERT INTO authors (name) SELECT name FROM _author_names_mig;
CREATE TABLE comic_authors (
  comic_id TEXT NOT NULL,
  author_id INTEGER NOT NULL,
  PRIMARY KEY (comic_id, author_id),
  FOREIGN KEY(comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE,
  FOREIGN KEY(author_id) REFERENCES authors(id) ON DELETE CASCADE
);
INSERT OR IGNORE INTO comic_authors (comic_id, author_id)
SELECT m.comic_id, a.id
FROM _comic_authors_mig m
INNER JOIN authors a ON a.name = m.author_name;
DROP TABLE _author_names_mig;
DROP TABLE _comic_authors_mig;
PRAGMA foreign_keys = ON",
    );
    connection.execute_unprepared(&sql).await?;
    Ok(())
}

async fn table_exists(manager: &SchemaManager<'_>, table: &str) -> Result<bool, DbErr> {
    table_exists_on(manager.get_connection(), table).await
}

async fn table_exists_on(connection: &impl ConnectionTrait, table: &str) -> Result<bool, DbErr> {
    let stmt = Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        format!("SELECT 1 FROM sqlite_master WHERE type='table' AND name='{table}' LIMIT 1"),
    );
    Ok(connection.query_one(stmt).await?.is_some())
}

async fn column_exists(
    manager: &SchemaManager<'_>,
    table: &str,
    column: &str,
) -> Result<bool, DbErr> {
    let stmt = Statement::from_string(
        manager.get_database_backend(),
        format!("PRAGMA table_info({table})"),
    );
    let rows = manager.get_connection().query_all(stmt).await?;
    Ok(rows.iter().any(|row| {
        row.try_get_by_index::<String>(1)
            .map(|name| name == column)
            .unwrap_or(false)
    }))
}
