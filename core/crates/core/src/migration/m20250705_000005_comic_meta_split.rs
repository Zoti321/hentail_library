use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

const SQL_CREATE_COMIC_META: &str = r#"
CREATE TABLE IF NOT EXISTS comic_meta (
  comic_id TEXT NOT NULL PRIMARY KEY,
  title TEXT NOT NULL,
  content_rating TEXT NOT NULL DEFAULT 'unknown',
  page_count INTEGER NOT NULL CHECK (page_count > 0),
  description TEXT,
  published_at INTEGER,
  FOREIGN KEY(comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE
)
"#;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let conn = manager.get_connection();
        let backend = conn.get_database_backend();

        if !table_exists(manager, "comics").await? {
            return Ok(());
        }

        conn.execute(Statement::from_string(
            backend,
            SQL_CREATE_COMIC_META.to_string(),
        ))
        .await?;

        add_column_if_missing(
            manager,
            "comics",
            "resource_size",
            "INTEGER NOT NULL DEFAULT 0",
        )
        .await?;
        add_column_if_missing(
            manager,
            "comics",
            "created_at",
            "INTEGER NOT NULL DEFAULT 0",
        )
        .await?;
        add_column_if_missing(
            manager,
            "comics",
            "last_updated_at",
            "INTEGER NOT NULL DEFAULT 0",
        )
        .await?;

        let now_ms = unix_now_ms();
        conn.execute(Statement::from_string(
            backend,
            format!(
                "UPDATE comics SET created_at = {now_ms}, last_updated_at = {now_ms} \
                 WHERE created_at = 0 OR last_updated_at = 0"
            ),
        ))
        .await?;

        if column_exists(manager, "comics", "title").await? {
            conn.execute(Statement::from_string(
                backend,
                "INSERT OR IGNORE INTO comic_meta (comic_id, title, content_rating, page_count, description, published_at)
                 SELECT comic_id, title, content_rating, page_count, NULL, NULL
                 FROM comics
                 WHERE page_count IS NOT NULL AND page_count > 0"
                    .to_string(),
            ))
            .await?;

            conn.execute(Statement::from_string(
                backend,
                "DELETE FROM comics WHERE page_count IS NULL OR page_count <= 0".to_string(),
            ))
            .await?;

            drop_column_if_exists(manager, "comics", "title").await?;
            drop_column_if_exists(manager, "comics", "content_rating").await?;
            drop_column_if_exists(manager, "comics", "page_count").await?;
        }

        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}

fn unix_now_ms() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0)
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

async fn add_column_if_missing(
    manager: &SchemaManager<'_>,
    table: &str,
    column: &str,
    definition: &str,
) -> Result<(), DbErr> {
    if column_exists(manager, table, column).await? {
        return Ok(());
    }
    let conn = manager.get_connection();
    conn.execute(Statement::from_string(
        conn.get_database_backend(),
        format!("ALTER TABLE {table} ADD COLUMN {column} {definition}"),
    ))
    .await?;
    Ok(())
}

async fn drop_column_if_exists(
    manager: &SchemaManager<'_>,
    table: &str,
    column: &str,
) -> Result<(), DbErr> {
    if !column_exists(manager, table, column).await? {
        return Ok(());
    }
    manager
        .alter_table(
            Table::alter()
                .table(Alias::new(table))
                .drop_column(Alias::new(column))
                .to_owned(),
        )
        .await
}
