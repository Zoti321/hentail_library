use std::path::{Path, PathBuf};

use unrar::Archive;

use crate::error::HentaiError;

use super::{is_comic_image_name, map_archive_err, map_reader_err, sort_archive_entry_names};

pub struct RarBackend {
    pub path: PathBuf,
    pub entry_names: Vec<String>,
}

pub fn count_rar_images(file: &Path) -> Result<Option<i32>, HentaiError> {
    let names = list_rar_image_names(file)?;
    if names.is_empty() {
        return Ok(None);
    }
    Ok(Some(names.len() as i32))
}

pub fn open_rar_backend(file: &Path) -> Result<RarBackend, HentaiError> {
    let entry_names = list_rar_image_names(file)?;
    if entry_names.is_empty() {
        return Err(HentaiError::reader_invalid_content(format!(
            "压缩包内无漫画图片: {}",
            file.display()
        )));
    }
    Ok(RarBackend {
        path: file.to_path_buf(),
        entry_names,
    })
}

pub fn read_rar_page(backend: &RarBackend, page_index: usize) -> Result<Vec<u8>, HentaiError> {
    let target = backend.entry_names.get(page_index).ok_or_else(|| {
        HentaiError::reader_invalid_content(format!(
            "页索引越界: index={page_index} count={}",
            backend.entry_names.len()
        ))
    })?;
    read_rar_entry(&backend.path, target)
}

fn list_rar_image_names(file: &Path) -> Result<Vec<String>, HentaiError> {
    let archive = Archive::new(file)
        .open_for_listing()
        .map_err(|e| map_archive_err("rar 列表失败", e))?;
    let mut names = Vec::new();
    for entry in archive {
        let header = entry.map_err(|e| map_archive_err("rar 条目读取失败", e))?;
        if header.is_directory() {
            continue;
        }
        let name = header.filename.to_string_lossy().to_string();
        if is_comic_image_name(&name) {
            names.push(name);
        }
    }
    Ok(sort_archive_entry_names(names))
}

fn read_rar_entry(file: &Path, target_name: &str) -> Result<Vec<u8>, HentaiError> {
    let mut archive = Archive::new(file)
        .open_for_processing()
        .map_err(|e| map_reader_err("rar 打开失败", e))?;
    loop {
        let Some(header) = archive
            .read_header()
            .map_err(|e| map_reader_err("rar 读取头失败", e))?
        else {
            break;
        };
        if header.entry().is_directory() {
            archive = header
                .skip()
                .map_err(|e| map_reader_err("rar 跳过目录失败", e))?;
            continue;
        }
        let name = header.entry().filename.to_string_lossy();
        if name == target_name {
            let (data, _) = header
                .read()
                .map_err(|e| map_reader_err("rar 读取条目失败", e))?;
            return Ok(data);
        }
        archive = header
            .skip()
            .map_err(|e| map_reader_err("rar 跳过条目失败", e))?;
    }
    Err(HentaiError::reader_invalid_content(format!(
        "rar 内未找到条目: {target_name}"
    )))
}
