use sea_orm::Statement;
use sea_orm_migration::prelude::*;

/// Comic trash 删除时间（ADR-0023）：非空即处于 trash。
#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        if !table_exists(manager, "comics").await? {
            return Ok(());
        }
        let connection = manager.get_connection();
        if !column_exists(manager, "comics", "deleted_at").await? {
            connection
                .execute_unprepared("ALTER TABLE comics ADD COLUMN deleted_at INTEGER")
                .await?;
        }
        connection
            .execute_unprepared(
                "CREATE INDEX IF NOT EXISTS idx_comics_deleted_at ON comics (deleted_at)",
            )
            .await?;
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
