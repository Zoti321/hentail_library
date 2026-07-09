use crate::error::HentaiError;

use crate::formats::{read_pdf_page, read_rar_page, read_sevenz_page};

use super::backend::{read_epub_page, read_zip_page, ReaderBackend};
use super::dto::ReaderPageListDto;
use super::manager::{open_reader, with_session};

#[tracing::instrument(err, fields(comic_id, resource_type, path))]
pub fn load_page_list(
    comic_id: &str,
    path: &str,
    resource_type: &str,
) -> Result<ReaderPageListDto, HentaiError> {
    open_reader(comic_id, path, resource_type)?;
    let list = with_session(comic_id, |backend| match backend {
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
        ReaderBackend::Rar(rar) => Ok(ReaderPageListDto {
            resource_type: resource_type.to_string(),
            page_count: rar.entry_names.len() as i32,
            dir_page_paths: vec![],
        }),
        ReaderBackend::SevenZ(sevenz) => Ok(ReaderPageListDto {
            resource_type: resource_type.to_string(),
            page_count: sevenz.entry_names.len() as i32,
            dir_page_paths: vec![],
        }),
        ReaderBackend::Pdf(pdf) => Ok(ReaderPageListDto {
            resource_type: "pdf".to_string(),
            page_count: pdf.page_count,
            dir_page_paths: vec![],
        }),
    })?;
    tracing::info!(
        comic_id,
        page_count = list.page_count,
        resource_type = %list.resource_type,
        "reader page list loaded"
    );
    Ok(list)
}

#[tracing::instrument(err, fields(comic_id, resource_type, page_index), skip(path))]
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
        ReaderBackend::Rar(rar) => read_rar_page(rar, page_index),
        ReaderBackend::SevenZ(sevenz) => read_sevenz_page(sevenz, page_index),
        ReaderBackend::Pdf(pdf) => read_pdf_page(pdf, page_index),
    })
}
