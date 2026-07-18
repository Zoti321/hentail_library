use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::prelude::*;

/// Ensures the current schema exists for installs that already applied earlier
/// migrations while `m20240630_000002_drift_v2_seed` was still a no-op
/// (empty DB, no tables, but seaql_migrations fully populated).
#[derive(DeriveMigrationName)]
pub struct Migration;

const SQL: &str = r#"
CREATE TABLE IF NOT EXISTS comics (
  comic_id TEXT NOT NULL PRIMARY KEY,
  path TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_size INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT 0,
  last_updated_at INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS comic_meta (
  comic_id TEXT NOT NULL PRIMARY KEY,
  title TEXT NOT NULL,
  content_rating TEXT NOT NULL DEFAULT 'unknown',
  page_count INTEGER NOT NULL CHECK (page_count > 0),
  description TEXT,
  published_at INTEGER,
  FOREIGN KEY(comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS tags (
  name TEXT NOT NULL PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS authors (
  name TEXT NOT NULL PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS comic_tags (
  comic_id TEXT NOT NULL,
  tag_name TEXT NOT NULL,
  PRIMARY KEY (comic_id, tag_name),
  FOREIGN KEY(comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE,
  FOREIGN KEY(tag_name) REFERENCES tags(name) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS comic_authors (
  comic_id TEXT NOT NULL,
  author_name TEXT NOT NULL,
  PRIMARY KEY (comic_id, author_name),
  FOREIGN KEY(comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE,
  FOREIGN KEY(author_name) REFERENCES authors(name) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS series (
  series_id TEXT NOT NULL PRIMARY KEY,
  folder_path TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  serialization_status TEXT NOT NULL DEFAULT 'unknown'
    CHECK (serialization_status IN ('unknown', 'ongoing', 'ended', 'hiatus')),
  total_count INTEGER NULL CHECK (total_count IS NULL OR total_count > 0)
);

CREATE TABLE IF NOT EXISTS series_items (
  series_id TEXT NOT NULL,
  comic_id TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  PRIMARY KEY (series_id, comic_id),
  UNIQUE (comic_id),
  FOREIGN KEY (series_id) REFERENCES series(series_id) ON DELETE CASCADE,
  FOREIGN KEY (comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS comic_thumbnails (
  comic_id TEXT NOT NULL PRIMARY KEY,
  thumbnail BLOB NOT NULL,
  updated_at INTEGER NOT NULL,
  source_modified_ms INTEGER NOT NULL DEFAULT 0,
  source_size INTEGER NOT NULL DEFAULT 0,
  is_user_set INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS series_thumbnails (
  series_id TEXT NOT NULL PRIMARY KEY,
  thumbnail BLOB NOT NULL,
  updated_at INTEGER NOT NULL,
  source_comic_id TEXT NOT NULL,
  source_page_index INTEGER NOT NULL,
  FOREIGN KEY(series_id) REFERENCES series(series_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS saved_paths (
  raw_path TEXT NOT NULL PRIMARY KEY,
  security_bookmark TEXT
);

CREATE TABLE IF NOT EXISTS comic_reading_histories (
  comic_id TEXT NOT NULL PRIMARY KEY,
  title TEXT NOT NULL,
  last_read_time INTEGER NOT NULL,
  page_index INTEGER
);

CREATE TABLE IF NOT EXISTS series_reading_histories (
  series_id TEXT NOT NULL PRIMARY KEY,
  last_read_comic_id TEXT NOT NULL,
  last_read_time INTEGER NOT NULL,
  page_index INTEGER,
  FOREIGN KEY(series_id) REFERENCES series(series_id) ON DELETE CASCADE
);
"#;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let conn = manager.get_connection();
        let backend = conn.get_database_backend();
        for stmt in SQL.split(';') {
            let sql = stmt.trim();
            if sql.is_empty() {
                continue;
            }
            conn.execute(Statement::from_string(backend, sql.to_string()))
                .await?;
        }
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}
