use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let conn = manager.get_connection();
        conn.execute_unprepared(
            "CREATE TABLE IF NOT EXISTS comic_finished_marks (
                comic_id TEXT NOT NULL PRIMARY KEY,
                finished_at_ms INTEGER NOT NULL
            )",
        )
        .await?;
        conn.execute_unprepared(
            "CREATE TABLE IF NOT EXISTS reading_duration_total (
                id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
                total_ms INTEGER NOT NULL CHECK (total_ms >= 0),
                updated_at_ms INTEGER NOT NULL
            )",
        )
        .await?;
        // Seed singleton row; now_ms approximated via SQLite unixepoch*1000.
        conn.execute_unprepared(
            "INSERT OR IGNORE INTO reading_duration_total (id, total_ms, updated_at_ms)
             VALUES (1, 0, CAST(strftime('%s','now') AS INTEGER) * 1000)",
        )
        .await?;
        Ok(())
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let conn = manager.get_connection();
        conn.execute_unprepared("DROP TABLE IF EXISTS comic_finished_marks")
            .await?;
        conn.execute_unprepared("DROP TABLE IF EXISTS reading_duration_total")
            .await?;
        Ok(())
    }
}
