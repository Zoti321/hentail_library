use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .get_connection()
            .execute_unprepared(
                "CREATE TABLE IF NOT EXISTS comic_content_fingerprints (
                comic_id TEXT PRIMARY KEY NOT NULL REFERENCES comics(comic_id) ON DELETE CASCADE,
                digest TEXT NOT NULL,
                resource_type TEXT NOT NULL,
                modified_ms INTEGER NOT NULL,
                size INTEGER NOT NULL
            )",
            )
            .await?;
        Ok(())
    }
    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}
