use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

const SQL_INSERT_MISSING: &str = r#"
INSERT INTO comic_reading_histories (comic_id, title, last_read_time, page_index)
SELECT srh.last_read_comic_id, c.title, srh.last_read_time, srh.page_index
FROM series_reading_histories srh
INNER JOIN comics c ON c.comic_id = srh.last_read_comic_id
WHERE NOT EXISTS (
  SELECT 1 FROM comic_reading_histories crh WHERE crh.comic_id = srh.last_read_comic_id
)
"#;

const SQL_UPDATE_NEWER: &str = r#"
UPDATE comic_reading_histories
SET title = (
      SELECT c.title FROM comics c
      WHERE c.comic_id = comic_reading_histories.comic_id
    ),
    last_read_time = (
      SELECT srh.last_read_time FROM series_reading_histories srh
      WHERE srh.last_read_comic_id = comic_reading_histories.comic_id
    ),
    page_index = (
      SELECT srh.page_index FROM series_reading_histories srh
      WHERE srh.last_read_comic_id = comic_reading_histories.comic_id
    )
WHERE EXISTS (
  SELECT 1 FROM series_reading_histories srh
  INNER JOIN comics c ON c.comic_id = srh.last_read_comic_id
  WHERE srh.last_read_comic_id = comic_reading_histories.comic_id
    AND srh.last_read_time > comic_reading_histories.last_read_time
)
"#;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        if !table_exists(manager, "series_reading_histories").await? {
            return Ok(());
        }
        let conn = manager.get_connection();
        let backend = conn.get_database_backend();
        conn.execute(Statement::from_string(backend, SQL_INSERT_MISSING.to_string()))
            .await?;
        conn.execute(Statement::from_string(backend, SQL_UPDATE_NEWER.to_string()))
            .await?;
        conn.execute(Statement::from_string(
            backend,
            "DROP TABLE IF EXISTS series_reading_histories".to_string(),
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
