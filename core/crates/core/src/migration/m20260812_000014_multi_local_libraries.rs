use std::collections::HashMap;
use std::path::Path;

use sea_orm::{ConnectionTrait, Statement};
use sea_orm_migration::prelude::*;
use sha1::{Digest, Sha1};

use crate::comic_id::normalize_path_for_key;

/// Multi Local library: libraries + `app_prefs` + `library_id` on comics/series;
/// migrate each `saved_paths` root into one Local library.
#[derive(DeriveMigrationName)]
pub struct Migration;

const DEFAULT_FORMAT_GROUPS_JSON: &str = r#"["folder","pdf","epub","archive"]"#;
const PREF_CURRENT_LIBRARY_ID: &str = "current_library_id";

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        create_libraries_table(manager).await?;
        create_app_prefs_table(manager).await?;
        add_library_id_column(manager, "comics").await?;
        add_library_id_column(manager, "series").await?;
        migrate_saved_paths_to_libraries(manager).await?;
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}

async fn create_libraries_table(manager: &SchemaManager<'_>) -> Result<(), DbErr> {
    if table_exists(manager, "libraries").await? {
        return Ok(());
    }
    manager
        .get_connection()
        .execute_unprepared(
            r"
CREATE TABLE IF NOT EXISTS libraries (
  library_id TEXT NOT NULL PRIMARY KEY,
  kind TEXT NOT NULL DEFAULT 'local',
  root_path TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  enabled_format_groups TEXT NOT NULL,
  created_at INTEGER NOT NULL
)
",
        )
        .await?;
    Ok(())
}

async fn create_app_prefs_table(manager: &SchemaManager<'_>) -> Result<(), DbErr> {
    if table_exists(manager, "app_prefs").await? {
        return Ok(());
    }
    manager
        .get_connection()
        .execute_unprepared(
            r"
CREATE TABLE IF NOT EXISTS app_prefs (
  key TEXT NOT NULL PRIMARY KEY,
  value TEXT NOT NULL
)
",
        )
        .await?;
    Ok(())
}

async fn add_library_id_column(manager: &SchemaManager<'_>, table: &str) -> Result<(), DbErr> {
    if !table_exists(manager, table).await? {
        return Ok(());
    }
    if column_exists(manager, table, "library_id").await? {
        return Ok(());
    }
    manager
        .get_connection()
        .execute_unprepared(&format!(
            "ALTER TABLE {table} ADD COLUMN library_id TEXT NOT NULL DEFAULT ''"
        ))
        .await?;
    Ok(())
}

async fn migrate_saved_paths_to_libraries(manager: &SchemaManager<'_>) -> Result<(), DbErr> {
    if !table_exists(manager, "saved_paths").await? {
        return Ok(());
    }
    if !table_exists(manager, "libraries").await? {
        return Ok(());
    }

    let db = manager.get_connection();
    let backend = manager.get_database_backend();
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map_or(0, |d| crate::util::milliseconds_to_i64(d.as_millis()));

    let libraries = load_libraries_from_saved_paths(db, backend).await?;
    insert_library_rows(db, backend, &libraries, now).await?;
    assign_comic_library_ids(manager, db, backend, &libraries).await?;
    assign_series_library_ids(manager, db, backend, &libraries).await?;

    if let Some((first_id, _, _)) = libraries.first() {
        db.execute(Statement::from_sql_and_values(
            backend,
            "INSERT OR REPLACE INTO app_prefs (key, value) VALUES (?, ?)",
            [
                sea_orm::Value::String(Some(Box::new(PREF_CURRENT_LIBRARY_ID.to_string()))),
                sea_orm::Value::String(Some(Box::new(first_id.clone()))),
            ],
        ))
        .await?;
    }

    db.execute(Statement::from_string(
        backend,
        "DELETE FROM saved_paths".to_string(),
    ))
    .await?;

    Ok(())
}

async fn load_libraries_from_saved_paths(
    db: &impl ConnectionTrait,
    backend: sea_orm::DatabaseBackend,
) -> Result<Vec<(String, String, String)>, DbErr> {
    let path_rows = db
        .query_all(Statement::from_string(
            backend,
            "SELECT raw_path FROM saved_paths ORDER BY raw_path ASC".to_string(),
        ))
        .await?;
    let mut libraries: Vec<(String, String, String)> = Vec::new();
    for row in path_rows {
        let raw_path: String = row.try_get_by_index(0)?;
        let root = raw_path.trim();
        if root.is_empty() {
            continue;
        }
        let library_id = library_id_from_root(root);
        let name = library_name_from_root(root);
        libraries.push((library_id, root.to_string(), name));
    }
    Ok(libraries)
}

async fn insert_library_rows(
    db: &impl ConnectionTrait,
    backend: sea_orm::DatabaseBackend,
    libraries: &[(String, String, String)],
    now: i64,
) -> Result<(), DbErr> {
    for (library_id, root_path, name) in libraries {
        db.execute(Statement::from_sql_and_values(
            backend,
            "INSERT OR IGNORE INTO libraries \
             (library_id, kind, root_path, name, enabled_format_groups, created_at) \
             VALUES (?, 'local', ?, ?, ?, ?)",
            [
                sea_orm::Value::String(Some(Box::new(library_id.clone()))),
                sea_orm::Value::String(Some(Box::new(root_path.clone()))),
                sea_orm::Value::String(Some(Box::new(name.clone()))),
                sea_orm::Value::String(Some(Box::new(DEFAULT_FORMAT_GROUPS_JSON.to_string()))),
                sea_orm::Value::BigInt(Some(now)),
            ],
        ))
        .await?;
    }
    Ok(())
}

fn library_roots_normalized(libraries: &[(String, String, String)]) -> Vec<(String, String)> {
    libraries
        .iter()
        .map(|(id, root, _)| (id.clone(), normalize_path_for_key(root)))
        .collect()
}

async fn assign_comic_library_ids(
    manager: &SchemaManager<'_>,
    db: &impl ConnectionTrait,
    backend: sea_orm::DatabaseBackend,
    libraries: &[(String, String, String)],
) -> Result<(), DbErr> {
    if !table_exists(manager, "comics").await?
        || !column_exists(manager, "comics", "library_id").await?
    {
        return Ok(());
    }
    let comic_rows = db
        .query_all(Statement::from_string(
            backend,
            "SELECT comic_id, path FROM comics".to_string(),
        ))
        .await?;
    let roots_norm = library_roots_normalized(libraries);
    for row in comic_rows {
        let comic_id: String = row.try_get_by_index(0)?;
        let path: String = row.try_get_by_index(1)?;
        let Some(library_id) = longest_matching_library(&path, &roots_norm) else {
            continue;
        };
        db.execute(Statement::from_sql_and_values(
            backend,
            "UPDATE comics SET library_id = ? WHERE comic_id = ?",
            [
                sea_orm::Value::String(Some(Box::new(library_id))),
                sea_orm::Value::String(Some(Box::new(comic_id))),
            ],
        ))
        .await?;
    }
    Ok(())
}

async fn assign_series_library_ids(
    manager: &SchemaManager<'_>,
    db: &impl ConnectionTrait,
    backend: sea_orm::DatabaseBackend,
    libraries: &[(String, String, String)],
) -> Result<(), DbErr> {
    if !table_exists(manager, "series").await?
        || !column_exists(manager, "series", "library_id").await?
    {
        return Ok(());
    }
    let series_rows = db
        .query_all(Statement::from_string(
            backend,
            "SELECT series_id, folder_path FROM series".to_string(),
        ))
        .await?;
    let roots_norm = library_roots_normalized(libraries);
    let comic_library = load_comic_library_map(manager, db, backend).await?;
    for row in series_rows {
        let series_id: String = row.try_get_by_index(0)?;
        let folder_path: String = row.try_get_by_index(1)?;
        let library_id =
            resolve_series_library_id(db, backend, &series_id, &folder_path, &roots_norm, &comic_library)
                .await?;
        if let Some(library_id) = library_id {
            db.execute(Statement::from_sql_and_values(
                backend,
                "UPDATE series SET library_id = ? WHERE series_id = ?",
                [
                    sea_orm::Value::String(Some(Box::new(library_id))),
                    sea_orm::Value::String(Some(Box::new(series_id))),
                ],
            ))
            .await?;
        }
    }
    Ok(())
}

async fn load_comic_library_map(
    manager: &SchemaManager<'_>,
    db: &impl ConnectionTrait,
    backend: sea_orm::DatabaseBackend,
) -> Result<HashMap<String, String>, DbErr> {
    let mut comic_library: HashMap<String, String> = HashMap::new();
    if !table_exists(manager, "comics").await? {
        return Ok(comic_library);
    }
    let rows = db
        .query_all(Statement::from_string(
            backend,
            "SELECT comic_id, library_id FROM comics WHERE library_id != ''".to_string(),
        ))
        .await?;
    for row in rows {
        let comic_id: String = row.try_get_by_index(0)?;
        let library_id: String = row.try_get_by_index(1)?;
        comic_library.insert(comic_id, library_id);
    }
    Ok(comic_library)
}

async fn resolve_series_library_id(
    db: &impl ConnectionTrait,
    backend: sea_orm::DatabaseBackend,
    series_id: &str,
    folder_path: &str,
    roots_norm: &[(String, String)],
    comic_library: &HashMap<String, String>,
) -> Result<Option<String>, DbErr> {
    let mut library_id = longest_matching_library(folder_path, roots_norm);
    if library_id.is_none() {
        let member = db
            .query_one(Statement::from_sql_and_values(
                backend,
                "SELECT comic_id FROM series_items WHERE series_id = ? LIMIT 1",
                [sea_orm::Value::String(Some(Box::new(series_id.to_owned())))],
            ))
            .await?;
        if let Some(member_row) = member {
            let comic_id: String = member_row.try_get_by_index(0)?;
            library_id = comic_library.get(&comic_id).cloned();
        }
    }
    Ok(library_id)
}

fn library_id_from_root(root: &str) -> String {
    let normalized = normalize_path_for_key(root);
    let mut hasher = Sha1::new();
    hasher.update(b"library:");
    hasher.update(normalized.as_bytes());
    format!("{:x}", hasher.finalize())
}

fn library_name_from_root(root: &str) -> String {
    let trimmed = root.trim().trim_end_matches(['/', '\\']);
    Path::new(trimmed)
        .file_name()
        .and_then(|n| n.to_str())
        .filter(|s| !s.is_empty())
        .unwrap_or(trimmed)
        .to_string()
}

fn longest_matching_library(path: &str, roots: &[(String, String)]) -> Option<String> {
    let path_key = normalize_path_for_key(path);
    if path_key.is_empty() {
        return None;
    }
    let mut best: Option<(usize, String)> = None;
    for (library_id, root_key) in roots {
        if root_key.is_empty() {
            continue;
        }
        if path_key == *root_key || path_key.starts_with(&format!("{root_key}/")) {
            let len = root_key.len();
            if best
                .as_ref()
                .is_none_or(|(best_len, _)| len > *best_len)
            {
                best = Some((len, library_id.clone()));
            }
        }
    }
    best.map(|(_, id)| id)
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
            .is_ok_and(|name| name == column)
    }))
}
