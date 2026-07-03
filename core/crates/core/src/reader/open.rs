use crate::error::HentaiError;

use super::backend::{read_epub_page, read_zip_page, ReaderBackend};
use super::dto::ReaderPageListDto;
use super::manager::{open_reader, with_session};

pub fn load_page_list(
    comic_id: &str,
    path: &str,
    resource_type: &str,
) -> Result<ReaderPageListDto, HentaiError> {
    open_reader(comic_id, path, resource_type)?;
    with_session(comic_id, |backend| match backend {
        ReaderBackend::Dir(dir) => Ok(ReaderPageListDto {
            resource_type: "dir".to_string(),
            page_count: dir.files.len() as i32,
            dir_page_paths: dir
                .files
                .iter()
                .map(|p| p.to_string_lossy().to_string())
                .collect(),
        }),
        ReaderBackend::Zip(zip) => Ok(ReaderPageListDto {
            resource_type: resource_type.to_string(),
            page_count: zip.entry_indices.len() as i32,
            dir_page_paths: vec![],
        }),
        ReaderBackend::Epub(epub) => Ok(ReaderPageListDto {
            resource_type: "epub".to_string(),
            page_count: epub.image_entries.len() as i32,
            dir_page_paths: vec![],
        }),
    })
}

pub fn load_page_bytes(
    comic_id: &str,
    path: &str,
    resource_type: &str,
    page_index: i32,
) -> Result<Vec<u8>, HentaiError> {
    if resource_type == "dir" {
        return Err(HentaiError::reader_invalid_content(
            "目录资源请通过 dir_page_paths 读取文件",
        ));
    }
    open_reader(comic_id, path, resource_type)?;
    let page_index = usize::try_from(page_index).map_err(|_| {
        HentaiError::reader_invalid_content(format!("页索引无效: {page_index}"))
    })?;
    with_session(comic_id, |backend| match backend {
        ReaderBackend::Dir(_) => Err(HentaiError::reader_invalid_content(
            "目录资源请通过 dir_page_paths 读取文件",
        )),
        ReaderBackend::Zip(zip) => read_zip_page(zip, page_index),
        ReaderBackend::Epub(epub) => read_epub_page(epub, page_index),
    })
}
