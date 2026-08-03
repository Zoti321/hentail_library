use std::path::Path;
use std::time::UNIX_EPOCH;

use crate::error::HentaiError;

use super::media::{extension_lower, is_comic_image_extension};

pub fn read_resource_size(path: &Path, resource_type: &str) -> Result<Option<i64>, HentaiError> {
    if !path.exists() {
        return Ok(None);
    }
    if resource_type == "dir" {
        return compute_dir_image_files_size(path);
    }
    let meta = std::fs::metadata(path).map_err(|e| {
        HentaiError::validation(format!("stat 失败: {} ({})", path.display(), e))
    })?;
    Ok(Some(meta.len() as i64))
}

fn compute_dir_image_files_size(dir: &Path) -> Result<Option<i64>, HentaiError> {
    let mut total = 0i64;
    for entry in std::fs::read_dir(dir).map_err(|e| {
        HentaiError::validation(format!("读取目录失败: {} ({})", dir.display(), e))
    })? {
        let entry = entry.map_err(|e| HentaiError::validation(e.to_string()))?;
        let path = entry.path();
        if path.is_dir() {
            return Ok(None);
        }
        if path.is_file() && is_comic_image_extension(&extension_lower(&path)) {
            let meta = std::fs::metadata(&path).map_err(|e| HentaiError::validation(e.to_string()))?;
            total += meta.len() as i64;
        }
    }
    if total <= 0 {
        return Ok(None);
    }
    Ok(Some(total))
}

pub fn read_source_stat(path: &Path, resource_type: &str) -> Result<Option<(i64, i64)>, HentaiError> {
    if !path.exists() {
        return Ok(None);
    }
    let meta = std::fs::metadata(path).map_err(|e| {
        HentaiError::validation(format!("stat 失败: {} ({})", path.display(), e))
    })?;
    let modified_ms = meta
        .modified()
        .ok()
        .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0);
    let size = read_resource_size(path, resource_type)?.unwrap_or(0);
    Ok(Some((modified_ms, size)))
}
