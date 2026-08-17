use std::fs::File;
use std::io::BufReader;
use std::path::{Path, PathBuf};

use crate::error::HentaiError;

use super::{
    system_time_to_ms, ResourceAccess, ResourceEntry, ResourceKind, ResourceStat, ResourceStream,
};

/// Local filesystem [ResourceAccess]. Location keys are OS path strings
/// (same comicId path semantics as today).
#[derive(Debug, Default, Clone, Copy)]
pub struct LocalResourceAccess;

impl LocalResourceAccess {
    pub fn path_for(location: &str) -> PathBuf {
        PathBuf::from(location)
    }
}

impl ResourceAccess for LocalResourceAccess {
    fn list(&self, location: &str) -> Result<Vec<ResourceEntry>, HentaiError> {
        let dir = Path::new(location);
        let entries = std::fs::read_dir(dir).map_err(|e| {
            HentaiError::validation(format!("目录扫描失败: {} ({})", dir.display(), e))
        })?;
        let mut out = Vec::new();
        for entry in entries {
            let entry = entry.map_err(|e| HentaiError::validation(e.to_string()))?;
            let path = entry.path();
            let file_type = entry
                .file_type()
                .map_err(|e| HentaiError::validation(e.to_string()))?;
            let kind = if file_type.is_dir() {
                ResourceKind::Dir
            } else if file_type.is_file() {
                ResourceKind::File
            } else {
                continue;
            };
            let name = entry.file_name().to_string_lossy().into_owned();
            out.push(ResourceEntry {
                name,
                location: path.to_string_lossy().into_owned(),
                kind,
            });
        }
        Ok(out)
    }

    fn stat(&self, location: &str) -> Result<Option<ResourceStat>, HentaiError> {
        let path = Path::new(location);
        if !path.exists() {
            return Ok(None);
        }
        let meta = std::fs::metadata(path).map_err(|e| {
            HentaiError::validation(format!("stat 失败: {} ({})", path.display(), e))
        })?;
        let kind = if meta.is_dir() {
            ResourceKind::Dir
        } else if meta.is_file() {
            ResourceKind::File
        } else {
            return Ok(None);
        };
        let modified_ms = meta
            .modified()
            .ok()
            .map(system_time_to_ms)
            .unwrap_or(0);
        Ok(Some(ResourceStat {
            kind,
            size: meta.len(),
            modified_ms,
        }))
    }

    fn open_stream(&self, location: &str) -> Result<ResourceStream, HentaiError> {
        let path = Path::new(location);
        let file = File::open(path).map_err(|e| {
            HentaiError::validation(format!("打开失败: {} ({})", path.display(), e))
        })?;
        Ok(Box::new(BufReader::new(file)))
    }
}
