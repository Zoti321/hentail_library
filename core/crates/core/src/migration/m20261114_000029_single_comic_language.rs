use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let db = manager.get_connection();
        let rows = db
            .query_all(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "SELECT comic_id, languages FROM comic_meta".to_owned(),
            ))
            .await?;
        for row in rows {
            let raw: String = row.try_get("", "languages")?;
            let Ok(values) = serde_json::from_str::<Vec<String>>(&raw) else {
                continue;
            };
            let normalized = crate::comic::serialize_languages(&values);
            if raw == normalized {
                continue;
            }
            let comic_id: String = row.try_get("", "comic_id")?;
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "UPDATE comic_meta SET languages = ? WHERE comic_id = ?",
                [normalized.into(), comic_id.into()],
            ))
            .await?;
        }
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        // Discarded secondary languages cannot be reconstructed by a down migration.
        Ok(())
    }
}
