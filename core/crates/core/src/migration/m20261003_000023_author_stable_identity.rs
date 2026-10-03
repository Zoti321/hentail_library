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
    connection
        .execute_unprepared("PRAGMA foreign_keys = OFF")
        .await?;
    connection
        .execute_unprepared("CREATE TABLE IF NOT EXISTS _author_names_mig (name TEXT NOT NULL)")
        .await?;
    connection
        .execute_unprepared("DELETE FROM _author_names_mig")
        .await?;
    connection
        .execute_unprepared("INSERT INTO _author_names_mig (name) SELECT name FROM authors")
        .await?;
    connection
        .execute_unprepared(
            "CREATE TABLE IF NOT EXISTS _comic_authors_mig (
  comic_id TEXT NOT NULL,
  author_name TEXT NOT NULL
)",
        )
        .await?;
    connection
        .execute_unprepared("DELETE FROM _comic_authors_mig")
        .await?;
    if table_exists_on(connection, "comic_authors").await? {
        connection
            .execute_unprepared(
                "INSERT INTO _comic_authors_mig (comic_id, author_name)
SELECT comic_id, author_name FROM comic_authors",
            )
            .await?;
        connection
            .execute_unprepared("DROP TABLE comic_authors")
            .await?;
    }
    connection.execute_unprepared("DROP TABLE authors").await?;
    connection
        .execute_unprepared(
            "CREATE TABLE authors (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name TEXT NOT NULL UNIQUE
)",
        )
        .await?;
    connection
        .execute_unprepared("INSERT INTO authors (name) SELECT name FROM _author_names_mig")
        .await?;
    connection
        .execute_unprepared(
            "CREATE TABLE comic_authors (
  comic_id TEXT NOT NULL,
  author_id INTEGER NOT NULL,
  PRIMARY KEY (comic_id, author_id),
  FOREIGN KEY(comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE,
  FOREIGN KEY(author_id) REFERENCES authors(id) ON DELETE CASCADE
)",
        )
        .await?;
    connection
        .execute_unprepared(
            "INSERT OR IGNORE INTO comic_authors (comic_id, author_id)
SELECT m.comic_id, a.id
FROM _comic_authors_mig m
INNER JOIN authors a ON a.name = m.author_name",
        )
        .await?;
    connection
        .execute_unprepared("DROP TABLE _author_names_mig")
        .await?;
    connection
        .execute_unprepared("DROP TABLE _comic_authors_mig")
        .await?;
    connection
        .execute_unprepared("PRAGMA foreign_keys = ON")
        .await?;
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
