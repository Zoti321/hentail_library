use sea_orm::Statement;
use sea_orm_migration::prelude::*;

/// SeriesItem.sort_order → REAL；新增 sort_order_locked（Komga 式锁定）。
///
/// 使用单连接 `execute_unprepared` 批量执行，避免连接池上 PRAGMA/DDL 跨连接失效。
#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        if !table_exists(manager, "series_items").await? {
            return Ok(());
        }
        if column_exists(manager, "series_items", "sort_order_locked").await? {
            return Ok(());
        }

        manager
            .get_connection()
            .execute_unprepared(
                r#"
PRAGMA foreign_keys=OFF;
CREATE TABLE __series_items_v2 (
  series_id TEXT NOT NULL,
  comic_id TEXT NOT NULL,
  sort_order REAL NOT NULL,
  sort_order_locked INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (series_id, comic_id),
  UNIQUE (comic_id),
  FOREIGN KEY (series_id) REFERENCES series(series_id) ON DELETE CASCADE,
  FOREIGN KEY (comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE
);
INSERT INTO __series_items_v2 (series_id, comic_id, sort_order, sort_order_locked)
  SELECT series_id, comic_id, CAST(sort_order AS REAL), 0 FROM series_items;
DROP TABLE series_items;
ALTER TABLE __series_items_v2 RENAME TO series_items;
PRAGMA foreign_keys=ON;
"#,
            )
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
