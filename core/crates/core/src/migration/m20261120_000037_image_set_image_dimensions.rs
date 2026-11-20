use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::prelude::*;

/// Persist optional pixel width/height on Image set images (ADR-0066).
#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let conn = manager.get_connection();
        let backend = manager.get_database_backend();
        if !has_column(conn, backend, "image_set_images", "width").await? {
            conn.execute_unprepared(
                "ALTER TABLE image_set_images ADD COLUMN width INTEGER NULL",
            )
            .await?;
        }
        if !has_column(conn, backend, "image_set_images", "height").await? {
            conn.execute_unprepared(
                "ALTER TABLE image_set_images ADD COLUMN height INTEGER NULL",
            )
            .await?;
        }
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}

async fn has_column<C: ConnectionTrait>(
    conn: &C,
    backend: sea_orm::DatabaseBackend,
    table: &str,
    column: &str,
) -> Result<bool, DbErr> {
    let rows = conn
        .query_all(Statement::from_string(
            backend,
            format!("PRAGMA table_info({table})"),
        ))
        .await?;
    Ok(rows.iter().any(|row| {
        row.try_get_by_index::<String>(1)
            .is_ok_and(|name| name == column)
    }))
}
