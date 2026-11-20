use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::prelude::*;

/// Catalog cover JPEG for Image sets (ADR-0067): long-edge ≤512, workspace first image.
#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let conn = manager.get_connection();
        if table_exists(conn, manager.get_database_backend(), "image_set_thumbnails").await? {
            return Ok(());
        }
        conn.execute_unprepared(
            "CREATE TABLE image_set_thumbnails (
                image_set_id TEXT NOT NULL PRIMARY KEY,
                thumbnail BLOB NOT NULL,
                source_image_set_image_id TEXT NOT NULL,
                source_modified_ms INTEGER NOT NULL DEFAULT 0,
                source_size INTEGER NOT NULL DEFAULT 0,
                updated_at INTEGER NOT NULL,
                FOREIGN KEY(image_set_id) REFERENCES image_sets(image_set_id) ON DELETE CASCADE
            )",
        )
        .await?;
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}

async fn table_exists<C: ConnectionTrait>(
    conn: &C,
    backend: sea_orm::DatabaseBackend,
    table: &str,
) -> Result<bool, DbErr> {
    let row = conn
        .query_one(Statement::from_string(
            backend,
            format!(
                "SELECT 1 FROM sqlite_master WHERE type='table' AND name='{table}' LIMIT 1"
            ),
        ))
        .await?;
    Ok(row.is_some())
}
