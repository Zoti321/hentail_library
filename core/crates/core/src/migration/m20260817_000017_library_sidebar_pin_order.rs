use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::prelude::*;

/// Pinned library + Library sidebar order on `libraries` (ADR-0009).
#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        if !table_exists(manager, "libraries").await? {
            return Ok(());
        }
        if !column_exists(manager, "libraries", "pinned").await? {
            manager
                .get_connection()
                .execute_unprepared(
                    "ALTER TABLE libraries ADD COLUMN pinned INTEGER NOT NULL DEFAULT 1",
                )
                .await?;
        }
        if !column_exists(manager, "libraries", "sidebar_order").await? {
            manager
                .get_connection()
                .execute_unprepared(
                    "ALTER TABLE libraries ADD COLUMN sidebar_order INTEGER NOT NULL DEFAULT 0",
                )
                .await?;
        }
        backfill_sidebar_order(manager).await?;
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}

async fn backfill_sidebar_order(manager: &SchemaManager<'_>) -> Result<(), DbErr> {
    let rows = manager
        .get_connection()
        .query_all(Statement::from_string(
            manager.get_database_backend(),
            "SELECT library_id FROM libraries ORDER BY root_path ASC".to_string(),
        ))
        .await?;
    for (index, row) in rows.into_iter().enumerate() {
        let library_id: String = row.try_get_by_index(0)?;
        manager
            .get_connection()
            .execute(Statement::from_sql_and_values(
                manager.get_database_backend(),
                "UPDATE libraries SET pinned = 1, sidebar_order = ? WHERE library_id = ?",
                [
                    sea_orm::Value::Int(Some(index as i32)),
                    sea_orm::Value::String(Some(Box::new(library_id))),
                ],
            ))
            .await?;
    }
    Ok(())
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
