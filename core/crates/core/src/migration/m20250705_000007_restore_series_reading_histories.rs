use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

const SQL_CREATE: &str = r#"
CREATE TABLE IF NOT EXISTS series_reading_histories (
  series_id TEXT NOT NULL PRIMARY KEY,
  last_read_comic_id TEXT NOT NULL,
  last_read_time INTEGER NOT NULL,
  page_index INTEGER,
  FOREIGN KEY(series_id) REFERENCES series(series_id) ON DELETE CASCADE
)
"#;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .get_connection()
            .execute_unprepared(SQL_CREATE)
            .await?;
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}
