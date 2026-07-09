use std::path::{Path, PathBuf};
use std::sync::{OnceLock, RwLock};

use sea_orm::{
    ConnectOptions, ConnectionTrait, Database, DatabaseConnection, DbErr, Statement,
};
use sea_orm_migration::MigratorTrait;

use crate::error::{HentaiError, HentaiErrorCode};
use crate::migration::Migrator;

#[derive(Debug, Clone)]
pub struct DbConfig {
    pub db_file_path: PathBuf,
}

static DB_CONFIG: OnceLock<RwLock<Option<DbConfig>>> = OnceLock::new();
static DB_CONN: OnceLock<RwLock<Option<DatabaseConnection>>> = OnceLock::new();

fn db_config_slot() -> &'static RwLock<Option<DbConfig>> {
    DB_CONFIG.get_or_init(|| RwLock::new(None))
}

fn db_conn_slot() -> &'static RwLock<Option<DatabaseConnection>> {
    DB_CONN.get_or_init(|| RwLock::new(None))
}

pub fn init_db(app_data_dir: &str, db_file_name: &str) -> Result<(), HentaiError> {
    crate::runtime::block_on(init_db_async(app_data_dir, db_file_name))
}

pub async fn init_db_async(app_data_dir: &str, db_file_name: &str) -> Result<(), HentaiError> {
    let app_data_dir = app_data_dir.trim();
    let db_file_name = db_file_name.trim();
    tracing::info!(app_data_dir, db_file_name, "init_db");
    if app_data_dir.is_empty() {
        return Err(HentaiError::validation("app_data_dir 不能为空"));
    }
    if db_file_name.is_empty() {
        return Err(HentaiError::validation("db_file_name 不能为空"));
    }

    let file_name = if db_file_name.ends_with(".sqlite") {
        db_file_name.to_string()
    } else {
        format!("{db_file_name}.sqlite")
    };

    let db_file_path = PathBuf::from(app_data_dir).join(file_name);
    let conn = open_connection(&db_file_path).await.map_err(map_db_err)?;

    {
        let mut guard = db_config_slot()
            .write()
            .map_err(|_| HentaiError::db_init_failed("DB 状态锁失败", None))?;
        *guard = Some(DbConfig {
            db_file_path: db_file_path.clone(),
        });
    }
    {
        let mut guard = db_conn_slot()
            .write()
            .map_err(|_| HentaiError::db_init_failed("DB 状态锁失败", None))?;
        *guard = Some(conn);
    }
    Ok(())
}

pub fn db_config() -> Result<DbConfig, HentaiError> {
    let guard = db_config_slot()
        .read()
        .map_err(|_| HentaiError::db_init_failed("DB 状态锁失败", None))?;
    guard.clone().ok_or_else(|| HentaiError {
        code: HentaiErrorCode::DbInitFailed,
        message: "init_db 尚未调用".to_string(),
        context: None,
    })
}

pub fn connection() -> Result<DatabaseConnection, HentaiError> {
    let guard = db_conn_slot()
        .read()
        .map_err(|_| HentaiError::db_init_failed("DB 状态锁失败", None))?;
    guard.clone().ok_or_else(|| HentaiError {
        code: HentaiErrorCode::DbInitFailed,
        message: "init_db 尚未调用".to_string(),
        context: None,
    })
}

/// 测试专用：打开任意 SQLite 文件并登记连接。
pub async fn init_db_at_path(db_file_path: impl AsRef<Path>) -> Result<(), HentaiError> {
    let db_file_path = db_file_path.as_ref().to_path_buf();
    let conn = open_connection(&db_file_path).await.map_err(map_db_err)?;
    {
        let mut guard = db_config_slot()
            .write()
            .map_err(|_| HentaiError::db_init_failed("DB 状态锁失败", None))?;
        *guard = Some(DbConfig {
            db_file_path: db_file_path.clone(),
        });
    }
    {
        let mut guard = db_conn_slot()
            .write()
            .map_err(|_| HentaiError::db_init_failed("DB 状态锁失败", None))?;
        *guard = Some(conn);
    }
    Ok(())
}

async fn open_connection(db_file_path: &Path) -> Result<DatabaseConnection, DbErr> {
    let mut options = ConnectOptions::new(format!(
        "sqlite://{}?mode=rwc",
        db_file_path.to_string_lossy().replace('\\', "/")
    ));
    options
        .max_connections(5)
        .min_connections(1)
        .sqlx_logging(false);
    let conn = Database::connect(options).await?;
    conn.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "PRAGMA foreign_keys = ON".to_string(),
    ))
    .await?;
    seed_drift_v2_if_needed(&conn).await?;
    Migrator::up(&conn, None).await?;
    Ok(conn)
}

async fn seed_drift_v2_if_needed(conn: &DatabaseConnection) -> Result<(), DbErr> {
    if !table_exists(conn, "comics").await? {
        return Ok(());
    }
    conn.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "CREATE TABLE IF NOT EXISTS seaql_migrations (
            version VARCHAR(255) PRIMARY KEY,
            applied_at BIGINT NOT NULL
        )"
        .to_string(),
    ))
    .await?;
    let count = conn
        .query_one(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT COUNT(*) AS c FROM seaql_migrations".to_string(),
        ))
        .await?
        .and_then(|row| row.try_get_by_index::<i64>(0).ok())
        .unwrap_or(0);
    if count == 0 {
        conn.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "INSERT INTO seaql_migrations (version, applied_at) VALUES ('m20240630_000002_drift_v2_seed', {})",
                chrono_like_unix_ms()
            ),
        ))
        .await?;
    }
    Ok(())
}

fn chrono_like_unix_ms() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0)
}

async fn table_exists(conn: &DatabaseConnection, table: &str) -> Result<bool, DbErr> {
    let stmt = Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        format!(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name='{table}' LIMIT 1"
        ),
    );
    Ok(conn.query_one(stmt).await?.is_some())
}

pub fn map_db_err(err: DbErr) -> HentaiError {
    HentaiError {
        code: HentaiErrorCode::DbQueryFailed,
        message: err.to_string(),
        context: None,
    }
}
