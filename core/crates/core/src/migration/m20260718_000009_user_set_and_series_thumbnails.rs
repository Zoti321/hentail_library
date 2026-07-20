use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        if table_exists(manager, "comic_thumbnails").await?
            && !column_exists(manager, "comic_thumbnails", "is_user_set").await?
        {
            manager
                .get_connection()
                .execute(Statement::from_string(
                    manager.get_database_backend(),
                    "ALTER TABLE comic_thumbnails ADD COLUMN is_user_set INTEGER NOT NULL DEFAULT 0"
                        .to_string(),
                ))
                .await?;
        }

        if !table_exists(manager, "series_thumbnails").await? {
            manager
                .get_connection()
                .execute(Statement::from_string(
                    manager.get_database_backend(),
                    r#"
CREATE TABLE series_thumbnails (
  series_id TEXT NOT NULL PRIMARY KEY,
  thumbnail BLOB NOT NULL,
  updated_at INTEGER NOT NULL,
  source_comic_id TEXT NOT NULL,
  source_page_index INTEGER NOT NULL,
  FOREIGN KEY(series_id) REFERENCES series(series_id) ON DELETE CASCADE
)
"#
                    .to_string(),
                ))
                .await?;
        }
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}

async fn table_exists(manager: &SchemaManager<'_>, table: &str) -> Result<bool, DbErr> {
    let stmt = Statement::from_string(
        manager.get_database_backend(),
        format!(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name='{table}' LIMIT 1"
        ),
    );
    Ok(manager
        .get_connection()
        .query_one(stmt)
        .await?
        .is_some())
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
