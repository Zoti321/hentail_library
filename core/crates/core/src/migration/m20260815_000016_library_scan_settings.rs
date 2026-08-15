use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::prelude::*;

/// Per-library Scan on startup + Scan interval (Komga-aligned).
#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        if !table_exists(manager, "libraries").await? {
            return Ok(());
        }
        if !column_exists(manager, "libraries", "scan_on_startup").await? {
            manager
                .get_connection()
                .execute_unprepared(
                    "ALTER TABLE libraries ADD COLUMN scan_on_startup INTEGER NOT NULL DEFAULT 0",
                )
                .await?;
        }
        if !column_exists(manager, "libraries", "scan_interval").await? {
            manager
                .get_connection()
                .execute_unprepared(
                    "ALTER TABLE libraries ADD COLUMN scan_interval TEXT NOT NULL DEFAULT 'disabled'",
                )
                .await?;
        }
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}

async fn table_exists(manager: &SchemaManager<'_>, table: &str) -> Result<bool, DbErr> {
    let result = manager
        .get_connection()
        .query_all(Statement::from_sql_and_values(
            manager.get_database_backend(),
            "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
            [sea_orm::Value::String(Some(Box::new(table.to_string())))],
        ))
        .await?;
    Ok(!result.is_empty())
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
    for row in rows {
        let name: String = row.try_get_by_index(1)?;
        if name == column {
            return Ok(true);
        }
    }
    Ok(false)
}
