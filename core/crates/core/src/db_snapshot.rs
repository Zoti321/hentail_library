use std::fs;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

use rusqlite::Connection;
use sea_orm::{ConnectOptions, Database, DatabaseConnection, DbErr};
use sea_orm_migration::MigratorTrait;

use crate::error::HentaiError;
use crate::migration::Migrator;

const SNAPSHOT_DIR_NAME: &str = "internal_db_snapshots";
const MAX_SNAPSHOT_FILES: usize = 2;

/// 在 SeaORM migration 前创建 SQLite Online Backup 快照（失败仅记录日志，不阻塞 migration）。
pub async fn maybe_snapshot_before_migration(db_file_path: &Path) -> Result<(), HentaiError> {
    if !should_create_snapshot(db_file_path).await? {
        return Ok(());
    }

    let snapshot_dir = db_file_path
        .parent()
        .map(|dir| dir.join(SNAPSHOT_DIR_NAME))
        .unwrap_or_else(|| PathBuf::from(SNAPSHOT_DIR_NAME));

    match create_snapshot(db_file_path, &snapshot_dir) {
        Ok(path) => {
            tracing::info!(
                source = %db_file_path.display(),
                snapshot = %path.display(),
                "internal db snapshot created before migration"
            );
            Ok(())
        }
        Err(err) => {
            tracing::error!(
                source = %db_file_path.display(),
                error = %err,
                "internal db snapshot failed; continuing migration"
            );
            Ok(())
        }
    }
}

async fn should_create_snapshot(db_file_path: &Path) -> Result<bool, HentaiError> {
    if !db_file_path.is_file() {
        return Ok(false);
    }
    let metadata = fs::metadata(db_file_path).map_err(|err| {
        HentaiError::validation(format!(
            "无法读取数据库文件元数据 {}: {err}",
            db_file_path.display()
        ))
    })?;
    if metadata.len() == 0 {
        return Ok(false);
    }
    let pending = count_pending_migrations(db_file_path).await?;
    Ok(pending > 0)
}

async fn count_pending_migrations(db_file_path: &Path) -> Result<usize, HentaiError> {
    let conn = open_readonly_migration_probe(db_file_path)
        .await
        .map_err(crate::db::map_db_err)?;
    let pending = Migrator::get_pending_migrations(&conn)
        .await
        .map_err(crate::db::map_db_err)?;
    Ok(pending.len())
}

async fn open_readonly_migration_probe(db_file_path: &Path) -> Result<DatabaseConnection, DbErr> {
    let mut options = ConnectOptions::new(format!(
        "sqlite://{}?mode=rwc",
        db_file_path.to_string_lossy().replace('\\', "/")
    ));
    options
        .max_connections(1)
        .min_connections(1)
        .sqlx_logging(false);
    Database::connect(options).await
}

fn create_snapshot(source: &Path, snapshot_dir: &Path) -> Result<PathBuf, HentaiError> {
    fs::create_dir_all(snapshot_dir).map_err(|err| {
        HentaiError::validation(format!(
            "无法创建内部快照目录 {}: {err}",
            snapshot_dir.display()
        ))
    })?;

    let dest = snapshot_dir.join(snapshot_file_name());
    {
        let src_conn = Connection::open(source).map_err(|err| {
            HentaiError::validation(format!("无法打开源数据库 {}: {err}", source.display()))
        })?;
        let mut dest_conn = Connection::open(&dest).map_err(|err| {
            HentaiError::validation(format!("无法创建快照文件 {}: {err}", dest.display()))
        })?;
        let backup = rusqlite::backup::Backup::new(&src_conn, &mut dest_conn)
            .map_err(|err| HentaiError::validation(format!("SQLite backup 初始化失败: {err}")))?;
        backup
            .run_to_completion(512, std::time::Duration::from_millis(100), None)
            .map_err(|err| HentaiError::validation(format!("SQLite backup 失败: {err}")))?;
    }

    prune_old_snapshots(snapshot_dir, MAX_SNAPSHOT_FILES)?;
    Ok(dest)
}

fn snapshot_file_name() -> String {
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default();
    let total_secs = now.as_secs();
    let day_seconds = total_secs % 86_400;
    let days = total_secs / 86_400;
    let hours = day_seconds / 3_600;
    let minutes = (day_seconds % 3_600) / 60;
    let seconds = day_seconds % 60;
    let (year, month, day) = civil_from_days(days as i64);
    format!("snapshot-{year:04}{month:02}{day:02}-{hours:02}{minutes:02}{seconds:02}.sqlite")
}

fn prune_old_snapshots(snapshot_dir: &Path, max_files: usize) -> Result<(), HentaiError> {
    let mut snapshots = Vec::new();
    for entry in fs::read_dir(snapshot_dir).map_err(|err| {
        HentaiError::validation(format!(
            "无法读取快照目录 {}: {err}",
            snapshot_dir.display()
        ))
    })? {
        let entry =
            entry.map_err(|err| HentaiError::validation(format!("读取快照目录项失败: {err}")))?;
        let path = entry.path();
        if path.is_file()
            && path
                .file_name()
                .and_then(|name| name.to_str())
                .is_some_and(|name| name.starts_with("snapshot-") && name.ends_with(".sqlite"))
        {
            snapshots.push(path);
        }
    }
    if snapshots.len() <= max_files {
        return Ok(());
    }
    snapshots.sort_by_key(|path| {
        fs::metadata(path)
            .and_then(|meta| meta.modified())
            .unwrap_or(SystemTime::UNIX_EPOCH)
    });
    for path in snapshots.iter().take(snapshots.len() - max_files) {
        if let Err(err) = fs::remove_file(path) {
            tracing::warn!(path = %path.display(), error = %err, "failed to prune old db snapshot");
        }
    }
    Ok(())
}

fn civil_from_days(days: i64) -> (i32, u32, u32) {
    let z = days + 719_468;
    let era = if z >= 0 { z } else { z - 146_096 } / 146_097;
    let doe = (z - era * 146_097) as u32;
    let yoe = (doe - doe / 1_460 + doe / 365 - doe / 1_460) / 365;
    let y = yoe as i32 + era as i32 * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let year = if m <= 2 { y + 1 } else { y };
    (year, m, d)
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[test]
    fn backup_produces_valid_sqlite() {
        let temp = TempDir::new().expect("tempdir");
        let source = temp.path().join("source.sqlite");
        {
            let conn = Connection::open(&source).expect("open source");
            conn.execute_batch(
                "PRAGMA foreign_keys = ON; CREATE TABLE t (id INTEGER PRIMARY KEY);",
            )
            .expect("seed");
        }
        let snapshot_path = create_snapshot(&source, temp.path()).expect("snapshot");
        assert!(snapshot_path.exists());
        let conn = Connection::open(&snapshot_path).expect("open snapshot");
        conn.query_row("SELECT COUNT(*) FROM t", [], |row| row.get::<_, i64>(0))
            .expect("query");
    }
}
