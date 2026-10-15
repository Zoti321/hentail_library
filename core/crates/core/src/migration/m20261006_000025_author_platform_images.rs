use sea_orm::Statement;
use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        if !column_exists(manager, "author_links", "version").await? {
            manager
                .get_connection()
                .execute_unprepared(
                    "ALTER TABLE author_links ADD COLUMN version INTEGER NOT NULL DEFAULT 1",
                )
                .await?;
        }
        manager
            .get_connection()
            .execute_unprepared(
                "CREATE TABLE IF NOT EXISTS author_image_cache (
                    author_link_id INTEGER NOT NULL,
                    slot TEXT NOT NULL CHECK(slot IN ('avatar', 'background')),
                    profile_url TEXT NOT NULL,
                    image_url TEXT,
                    checked_at INTEGER NOT NULL,
                    fetched_at INTEGER,
                    cache_key TEXT,
                    link_version INTEGER NOT NULL,
                    PRIMARY KEY (author_link_id, slot),
                    FOREIGN KEY (author_link_id) REFERENCES author_links(id) ON DELETE CASCADE
                )",
            )
            .await?;
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}

async fn column_exists(
    manager: &SchemaManager<'_>,
    table: &str,
    column: &str,
) -> Result<bool, DbErr> {
    let rows = manager
        .get_connection()
        .query_all(Statement::from_string(
            manager.get_database_backend(),
            format!("PRAGMA table_info({table})"),
        ))
        .await?;
    Ok(rows.iter().any(|row| {
        row.try_get_by_index::<String>(1)
            .map(|name| name == column)
            .unwrap_or(false)
    }))
}
