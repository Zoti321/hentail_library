//! Image set Read session (#586): catalog-ordered pages and raw page bytes.
//!
//! Stateless: no reader session store, and never writes Comic reading history or progress.

use std::fs::File;
use std::io::{BufReader, Read};
use std::path::{Component, Path, PathBuf};

use zip::ZipArchive;

use crate::error::HentaiError;
use crate::formats::{map_archive_err, read_rar_entry, read_sevenz_entry};
use crate::image_set::{list_image_set_images, ImageSetImageDto};
use crate::library::find_library_by_id;

/// Catalog-ordered page snapshot of one Image set Read session.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImageSetReaderSessionDto {
    pub library_id: String,
    pub image_set_id: String,
    pub pages: Vec<ImageSetImageDto>,
    /// 0-based index into `pages`.
    pub start_index: usize,
}

/// Opens an Image set Read session in synced catalog order.
pub async fn open_image_set_reader(
    library_id: &str,
    image_set_id: &str,
    start_index: usize,
) -> Result<ImageSetReaderSessionDto, HentaiError> {
    let pages = list_image_set_images(library_id, image_set_id).await?;
    if pages.is_empty() {
        return Err(HentaiError::reader_invalid_content("图集内无图片"));
    }
    if start_index >= pages.len() {
        return Err(HentaiError::reader_invalid_content(format!(
            "页索引越界: index={start_index} count={}",
            pages.len()
        )));
    }
    Ok(ImageSetReaderSessionDto {
        library_id: library_id.to_string(),
        image_set_id: image_set_id.to_string(),
        pages,
        start_index,
    })
}

/// Raw bytes of one Image set page, resolved from its catalog carrier under the Library root.
pub async fn load_image_set_page_bytes(
    library_id: &str,
    image: &ImageSetImageDto,
) -> Result<Vec<u8>, HentaiError> {
    let library = find_library_by_id(library_id)
        .await?
        .ok_or_else(|| HentaiError::validation(format!("图集库不存在: {library_id}")))?;
    let carrier = resolve_carrier_path(&library.root_path, &image.carrier_relative_path)?;
    match image.carrier_kind.as_str() {
        "loose" => std::fs::read(&carrier)
            .map_err(|e| HentaiError::reader_invalid_content(format!("读取图片失败: {e}"))),
        "zip" => read_zip_member(&carrier, &image.member_path),
        "rar" => read_rar_entry(&carrier, &image.member_path),
        "sevenz" => read_sevenz_entry(&carrier, &image.member_path),
        other => Err(HentaiError::reader_invalid_content(format!(
            "未知图集载体: {other}"
        ))),
    }
}

/// Joins a catalog carrier path onto the Library root; rejects absolute, empty or `..` segments.
fn resolve_carrier_path(root: &str, carrier_relative_path: &str) -> Result<PathBuf, HentaiError> {
    let relative = Path::new(carrier_relative_path);
    let safe = !carrier_relative_path.is_empty()
        && relative
            .components()
            .all(|component| matches!(component, Component::Normal(_)));
    if !safe {
        return Err(HentaiError::validation(format!(
            "图集载体路径无效: {carrier_relative_path}"
        )));
    }
    Ok(Path::new(root).join(relative))
}

fn read_zip_member(file: &Path, member_path: &str) -> Result<Vec<u8>, HentaiError> {
    let handle = File::open(file).map_err(|e| map_archive_err("zip 打开失败", e))?;
    let mut archive =
        ZipArchive::new(BufReader::new(handle)).map_err(|e| map_archive_err("zip 解析失败", e))?;
    let raw_name = archive
        .file_names()
        .find(|name| name.replace('\\', "/") == member_path)
        .map(str::to_string)
        .ok_or_else(|| {
            HentaiError::reader_invalid_content(format!("压缩包内无条目: {member_path}"))
        })?;
    let mut entry = archive
        .by_name(&raw_name)
        .map_err(|e| map_archive_err("zip 条目读取失败", e))?;
    let mut buf = Vec::new();
    entry
        .read_to_end(&mut buf)
        .map_err(|e| map_archive_err("zip 条目读取失败", e))?;
    Ok(buf)
}
