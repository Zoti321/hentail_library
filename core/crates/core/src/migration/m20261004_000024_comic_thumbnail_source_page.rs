use sea_orm::Statement;
use sea_orm_migration::prelude::*;

/// 用户指定封面页码：Author image 高清链路据此取与缩略图同一页；迁移前的行为空。
#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        if !table_exists(manager, "comic_thumbnails").await? {
            return Ok(());
        }
        if !column_exists(manager, "comic_thumbnails", "source_page_index").await? {
            manager
                .get_connection()
                .execute_unprepared(
                    "ALTER TABLE comic_thumbnails ADD COLUMN source_page_index INTEGER",
                )
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
        format!("SELECT 1 FROM sqlite_master WHERE type='table' AND name='{table}' LIMIT 1"),
    );
    Ok(manager.get_connection().query_one(stmt).await?.is_some())
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
