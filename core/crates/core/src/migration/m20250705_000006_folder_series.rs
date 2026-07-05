use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

const SQL_CREATE_SERIES: &str = r#"
CREATE TABLE IF NOT EXISTS series (
  series_id TEXT NOT NULL PRIMARY KEY,
  folder_path TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  serialization_status TEXT NOT NULL DEFAULT 'unknown'
    CHECK (serialization_status IN ('unknown', 'ongoing', 'ended', 'hiatus')),
  total_count INTEGER NULL CHECK (total_count IS NULL OR total_count > 0)
)
"#;

const SQL_CREATE_SERIES_ITEMS: &str = r#"
CREATE TABLE IF NOT EXISTS series_items (
  series_id TEXT NOT NULL,
  comic_id TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  PRIMARY KEY (series_id, comic_id),
  UNIQUE (comic_id),
  FOREIGN KEY (series_id) REFERENCES series(series_id) ON DELETE CASCADE,
  FOREIGN KEY (comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE
)
"#;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let conn = manager.get_connection();
        let backend = conn.get_database_backend();

        if !table_exists(manager, "series").await? {
            conn.execute(Statement::from_string(
                backend,
                SQL_CREATE_SERIES.to_string(),
            ))
            .await?;
            conn.execute(Statement::from_string(
                backend,
                SQL_CREATE_SERIES_ITEMS.to_string(),
            ))
            .await?;
            return Ok(());
        }

        conn.execute(Statement::from_string(
            backend,
            "DELETE FROM series_items".to_string(),
        ))
        .await?;
        conn.execute(Statement::from_string(
            backend,
            "DELETE FROM series".to_string(),
        ))
        .await?;

        conn.execute(Statement::from_string(
            backend,
            "PRAGMA foreign_keys = OFF".to_string(),
        ))
        .await?;
        conn.execute(Statement::from_string(
            backend,
            "DROP TABLE IF EXISTS series_items".to_string(),
        ))
        .await?;
        conn.execute(Statement::from_string(
            backend,
            "DROP TABLE IF EXISTS series".to_string(),
        ))
        .await?;
        conn.execute(Statement::from_string(
            backend,
            SQL_CREATE_SERIES.to_string(),
        ))
        .await?;
        conn.execute(Statement::from_string(
            backend,
            SQL_CREATE_SERIES_ITEMS.to_string(),
        ))
        .await?;
        conn.execute(Statement::from_string(
            backend,
            "PRAGMA foreign_keys = ON".to_string(),
        ))
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
