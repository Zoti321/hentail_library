use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::prelude::*;

/// ADR-0005: 废弃系列阅读进度，仅保留 Comic Reading history。
#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .get_connection()
            .execute(Statement::from_string(
                manager.get_database_backend(),
                "DROP TABLE IF EXISTS series_reading_histories".to_string(),
            ))
            .await?;
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}
