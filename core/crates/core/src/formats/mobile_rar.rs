use std::path::{Path, PathBuf};

use crate::error::HentaiError;

pub struct RarBackend {
    pub path: PathBuf,
    pub entry_names: Vec<String>,
}

fn unsupported() -> HentaiError {
    HentaiError::validation("当前平台不支持 RAR/CBR 格式")
}

pub fn count_rar_images(_file: &Path) -> Result<Option<i32>, HentaiError> {
    Ok(None)
}

pub fn open_rar_backend(_file: &Path) -> Result<RarBackend, HentaiError> {
    Err(unsupported())
}

pub fn read_rar_cover_bytes(_file: &Path) -> Result<Option<Vec<u8>>, HentaiError> {
    Ok(None)
}

pub fn read_rar_page(_backend: &RarBackend, _page_index: usize) -> Result<Vec<u8>, HentaiError> {
    Err(unsupported())
}
