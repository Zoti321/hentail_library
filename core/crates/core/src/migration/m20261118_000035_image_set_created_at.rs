use sea_orm::Statement;
use sea_orm_migration::prelude::*;

/// Image set catalog insertion time (epoch ms) for the catalog query sort; prior rows read as 0.
#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let rows = manager
            .get_connection()
            .query_all(Statement::from_string(
                manager.get_database_backend(),
                "PRAGMA table_info(image_sets)".to_string(),
            ))
            .await?;
        let exists = rows.iter().any(|row| {
            row.try_get_by_index::<String>(1)
                .is_ok_and(|name| name == "created_at")
        });
        if !exists {
            manager
                .get_connection()
                .execute_unprepared(
                    "ALTER TABLE image_sets ADD COLUMN created_at INTEGER NOT NULL DEFAULT 0",
                )
                .await?;
        }
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}
