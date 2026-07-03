use std::fs::File;
use std::path::{Path, PathBuf};

use sevenz_rust::{Archive, Password, SevenZReader};

use crate::error::HentaiError;

use super::{is_comic_image_name, map_archive_err, map_reader_err, sort_archive_entry_names};

pub struct SevenZBackend {
    pub path: PathBuf,
    pub entry_names: Vec<String>,
}

pub fn count_sevenz_images(file: &Path) -> Result<Option<i32>, HentaiError> {
    let names = list_sevenz_image_names(file)?;
    if names.is_empty() {
        return Ok(None);
    }
    Ok(Some(names.len() as i32))
}

pub fn open_sevenz_backend(file: &Path) -> Result<SevenZBackend, HentaiError> {
    let entry_names = list_sevenz_image_names(file)?;
    if entry_names.is_empty() {
        return Err(HentaiError::reader_invalid_content(format!(
            "压缩包内无漫画图片: {}",
            file.display()
        )));
    }
    Ok(SevenZBackend {
        path: file.to_path_buf(),
        entry_names,
    })
}

pub fn read_sevenz_page(backend: &SevenZBackend, page_index: usize) -> Result<Vec<u8>, HentaiError> {
    let target = backend.entry_names.get(page_index).ok_or_else(|| {
        HentaiError::reader_invalid_content(format!(
            "页索引越界: index={page_index} count={}",
            backend.entry_names.len()
        ))
    })?;
    read_sevenz_entry(&backend.path, target)
}

fn list_sevenz_image_names(file: &Path) -> Result<Vec<String>, HentaiError> {
    let mut reader = File::open(file).map_err(|e| map_archive_err("7z 打开失败", e))?;
    let len = reader
        .metadata()
        .map_err(|e| map_archive_err("7z stat 失败", e))?
        .len();
    let archive = Archive::read(&mut reader, len, &[])
        .map_err(|e| map_archive_err("7z 解析失败", e))?;
    let mut names = Vec::new();
    for entry in &archive.files {
        if entry.is_directory() {
            continue;
        }
        let name = entry.name().to_string();
        if is_comic_image_name(&name) {
            names.push(name);
        }
    }
    Ok(sort_archive_entry_names(names))
}

fn read_sevenz_entry(file: &Path, target_name: &str) -> Result<Vec<u8>, HentaiError> {
    let mut reader = SevenZReader::open(file, Password::empty())
        .map_err(|e| map_reader_err("7z 打开失败", e))?;
    let mut found = None;
    reader
        .for_each_entries(|entry, data| {
            if entry.is_directory() {
                return Ok(true);
            }
            if entry.name() == target_name {
                let mut buf = Vec::new();
                data.read_to_end(&mut buf)
                    .map_err(|e| sevenz_rust::Error::io(e))?;
                found = Some(buf);
                return Ok(false);
            }
            Ok(true)
        })
        .map_err(|e| map_reader_err("7z 解压失败", e))?;
    found.ok_or_else(|| {
        HentaiError::reader_invalid_content(format!("7z 内未找到条目: {target_name}"))
    })
}
