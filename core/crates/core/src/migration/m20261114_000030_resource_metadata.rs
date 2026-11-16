use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager.get_connection().execute_unprepared(
            "CREATE TABLE IF NOT EXISTS resource_metadata_libraries (
                library_id TEXT PRIMARY KEY NOT NULL REFERENCES libraries(library_id) ON DELETE CASCADE ON UPDATE CASCADE,
                enabled INTEGER NOT NULL DEFAULT 0 CHECK (enabled IN (0, 1))
            );
            CREATE TABLE IF NOT EXISTS resource_metadata_jobs (
                comic_id TEXT PRIMARY KEY NOT NULL REFERENCES comics(comic_id) ON DELETE CASCADE ON UPDATE CASCADE,
                revision INTEGER NOT NULL,
                fields TEXT NOT NULL,
                snapshot TEXT NOT NULL,
                state TEXT NOT NULL DEFAULT 'pending',
                attempts INTEGER NOT NULL DEFAULT 0,
                due_at INTEGER NOT NULL DEFAULT 0,
                error TEXT,
                last_success_at INTEGER,
                applied_revision INTEGER NOT NULL DEFAULT 0,
                recovery TEXT
            );
            CREATE INDEX IF NOT EXISTS resource_metadata_jobs_due ON resource_metadata_jobs(state, due_at);"
        ).await?;
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}
