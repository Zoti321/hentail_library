use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::prelude::*;

use crate::util::natural_sort::compute_sort_key;

/// Persist lexicographic sort keys for catalog title/name natural ordering.
#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        add_text_column(manager, "comic_meta", "title_sort_key").await?;
        add_text_column(manager, "series", "name_sort_key").await?;
        backfill_comic_title_sort_keys(manager).await?;
        backfill_series_name_sort_keys(manager).await?;
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}

async fn add_text_column(
    manager: &SchemaManager<'_>,
    table: &str,
    column: &str,
) -> Result<(), DbErr> {
    if !table_exists(manager, table).await? {
        return Ok(());
    }
    if column_exists(manager, table, column).await? {
        return Ok(());
    }
    manager
        .get_connection()
        .execute_unprepared(&format!(
            "ALTER TABLE {table} ADD COLUMN {column} TEXT NOT NULL DEFAULT ''"
        ))
        .await?;
    Ok(())
}

async fn backfill_comic_title_sort_keys(manager: &SchemaManager<'_>) -> Result<(), DbErr> {
    if !table_exists(manager, "comic_meta").await? {
        return Ok(());
    }
    if !column_exists(manager, "comic_meta", "title_sort_key").await? {
        return Ok(());
    }
    let db = manager.get_connection();
    let rows = db
        .query_all(Statement::from_string(
            manager.get_database_backend(),
            "SELECT comic_id, title FROM comic_meta".to_string(),
        ))
        .await?;
    for row in rows {
        let comic_id: String = row.try_get_by_index(0)?;
        let title: String = row.try_get_by_index(1)?;
        let key = compute_sort_key(&title);
        db.execute(Statement::from_sql_and_values(
            manager.get_database_backend(),
            "UPDATE comic_meta SET title_sort_key = ? WHERE comic_id = ?",
            [
                sea_orm::Value::String(Some(Box::new(key))),
                sea_orm::Value::String(Some(Box::new(comic_id))),
            ],
        ))
        .await?;
    }
    Ok(())
}

async fn backfill_series_name_sort_keys(manager: &SchemaManager<'_>) -> Result<(), DbErr> {
    if !table_exists(manager, "series").await? {
        return Ok(());
    }
    if !column_exists(manager, "series", "name_sort_key").await? {
        return Ok(());
    }
    let db = manager.get_connection();
    let rows = db
        .query_all(Statement::from_string(
            manager.get_database_backend(),
            "SELECT series_id, name FROM series".to_string(),
        ))
        .await?;
    for row in rows {
        let series_id: String = row.try_get_by_index(0)?;
        let name: String = row.try_get_by_index(1)?;
        let key = compute_sort_key(&name);
        db.execute(Statement::from_sql_and_values(
            manager.get_database_backend(),
            "UPDATE series SET name_sort_key = ? WHERE series_id = ?",
            [
                sea_orm::Value::String(Some(Box::new(key))),
                sea_orm::Value::String(Some(Box::new(series_id))),
            ],
        ))
        .await?;
    }
    Ok(())
}

async fn table_exists(manager: &SchemaManager<'_>, table: &str) -> Result<bool, DbErr> {
    let stmt = Statement::from_string(
        manager.get_database_backend(),
        format!("SELECT 1 FROM sqlite_master WHERE type='table' AND name='{table}' LIMIT 1"),
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
