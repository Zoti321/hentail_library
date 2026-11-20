use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::prelude::*;

/// Image set workspace: user order + exclude, submissions schema, per-library mutation gates.
#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let conn = manager.get_connection();
        let backend = manager.get_database_backend();
        if !has_column(conn, backend, "image_set_images", "sort_order").await? {
            conn.execute_unprepared(
                "ALTER TABLE image_set_images ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0",
            )
            .await?;
        }
        if !has_column(conn, backend, "image_set_images", "excluded").await? {
            conn.execute_unprepared(
                "ALTER TABLE image_set_images ADD COLUMN excluded INTEGER NOT NULL DEFAULT 0 CHECK (excluded IN (0, 1))",
            )
            .await?;
        }
        if !has_column(conn, backend, "libraries", "image_set_resource_mutation").await? {
            conn.execute_unprepared(
                "ALTER TABLE libraries ADD COLUMN image_set_resource_mutation INTEGER NOT NULL DEFAULT 0 CHECK (image_set_resource_mutation IN (0, 1))",
            )
            .await?;
        }
        if !has_column(conn, backend, "libraries", "image_set_managed_layout").await? {
            conn.execute_unprepared(
                "ALTER TABLE libraries ADD COLUMN image_set_managed_layout INTEGER NOT NULL DEFAULT 0 CHECK (image_set_managed_layout IN (0, 1))",
            )
            .await?;
        }
        conn.execute_unprepared(
            "CREATE TABLE IF NOT EXISTS image_set_submissions (
                submission_id TEXT PRIMARY KEY NOT NULL,
                library_id TEXT NOT NULL REFERENCES libraries(library_id) ON DELETE CASCADE ON UPDATE CASCADE,
                image_set_id TEXT NOT NULL REFERENCES image_sets(image_set_id) ON DELETE CASCADE ON UPDATE CASCADE,
                name TEXT NOT NULL
            );
            CREATE INDEX IF NOT EXISTS image_set_submissions_by_set
                ON image_set_submissions(image_set_id);
            CREATE TABLE IF NOT EXISTS image_set_submission_members (
                submission_id TEXT NOT NULL REFERENCES image_set_submissions(submission_id) ON DELETE CASCADE ON UPDATE CASCADE,
                image_set_image_id TEXT NOT NULL REFERENCES image_set_images(image_set_image_id) ON DELETE CASCADE ON UPDATE CASCADE,
                sort_order INTEGER NOT NULL,
                PRIMARY KEY (submission_id, image_set_image_id)
            );
            CREATE INDEX IF NOT EXISTS image_set_submission_members_by_image
                ON image_set_submission_members(image_set_image_id);",
        )
        .await?;
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
