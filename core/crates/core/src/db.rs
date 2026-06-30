use std::path::PathBuf;
use std::sync::{OnceLock, RwLock};

use crate::error::{HentaiError, HentaiErrorCode};

#[derive(Debug, Clone)]
pub struct DbConfig {
    pub db_file_path: PathBuf,
}

static DB_CONFIG: OnceLock<RwLock<Option<DbConfig>>> = OnceLock::new();

fn db_slot() -> &'static RwLock<Option<DbConfig>> {
    DB_CONFIG.get_or_init(|| RwLock::new(None))
}

/// 打开/登记数据库路径（#13 占位：SeaORM 接管在后续 issue）。
pub fn init_db(app_data_dir: &str, db_file_name: &str) -> Result<(), HentaiError> {
    let app_data_dir = app_data_dir.trim();
    let db_file_name = db_file_name.trim();
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
    let mut guard = db_slot()
        .write()
        .map_err(|_| HentaiError::db_init_failed("DB 状态锁失败", None))?;
    *guard = Some(DbConfig { db_file_path });
    Ok(())
}

pub fn db_config() -> Result<DbConfig, HentaiError> {
    let guard = db_slot()
        .read()
        .map_err(|_| HentaiError::db_init_failed("DB 状态锁失败", None))?;
    guard
        .clone()
        .ok_or_else(|| HentaiError {
            code: HentaiErrorCode::DbInitFailed,
            message: "init_db 尚未调用".to_string(),
            context: None,
        })
}
