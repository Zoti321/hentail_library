use sea_orm::Statement;
use sea_orm_migration::prelude::*;

/// Comic Character：全局名字典 + Comic 附着 + Metadata field lock（对齐 Parody / #73）。
#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .get_connection()
            .execute_unprepared(
                "CREATE TABLE IF NOT EXISTS characters (
  name TEXT NOT NULL PRIMARY KEY
)",
            )
            .await?;
        manager
            .get_connection()
            .execute_unprepared(
                "CREATE TABLE IF NOT EXISTS comic_characters (
  comic_id TEXT NOT NULL,
  character_name TEXT NOT NULL,
  PRIMARY KEY (comic_id, character_name),
  FOREIGN KEY(comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE,
  FOREIGN KEY(character_name) REFERENCES characters(name) ON DELETE CASCADE
)",
            )
            .await?;
        add_bool_column(manager, "comic_meta", "characters_locked").await?;
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}

async fn add_bool_column(
    manager: &SchemaManager<'_>,
    table: &str,
    column: &str,
) -> Result<(), DbErr> {
    if !table_exists(manager, table).await? {
        return Ok(());
    }
    if column_exists(manager, table, column).await? {
        return Ok(());
    }
    manager
        .get_connection()
        .execute_unprepared(&format!(
            "ALTER TABLE {table} ADD COLUMN {column} INTEGER NOT NULL DEFAULT 0"
        ))
        .await?;
    Ok(())
}

async fn table_exists(manager: &SchemaManager<'_>, table: &str) -> Result<bool, DbErr> {
    let stmt = Statement::from_string(
        manager.get_database_backend(),
        format!("SELECT 1 FROM sqlite_master WHERE type='table' AND name='{table}' LIMIT 1"),
    );
    Ok(manager
        .get_connection()
        .query_one(stmt)
        .await?
        .is_some())
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
