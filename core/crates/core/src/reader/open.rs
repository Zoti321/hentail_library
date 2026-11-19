use crate::error::HentaiError;
use crate::runtime::block_on;

use crate::formats::{read_pdf_page, read_rar_page, read_sevenz_page};

use super::backend::{read_epub_page, read_zip_page, ReaderBackend};
use super::dto::ReaderPageListDto;
use super::manager::ReaderSessionRead;
use super::writeback::writeback_after_open;

#[tracing::instrument(err, skip(read), fields(comic_id = read.comic_id, resource_type = read.resource_type, path = read.path))]
pub fn load_page_list(read: &ReaderSessionRead) -> Result<ReaderPageListDto, HentaiError> {
    let comic_id = &read.comic_id;
    let resource_type = &read.resource_type;
    let list = read.with_backend(|backend| match backend {
        ReaderBackend::Dir(dir) => Ok(ReaderPageListDto {
            resource_type: "dir".to_string(),
            page_count: crate::util::usize_to_i32(dir.files.len()),
            dir_page_paths: dir
                .files
                .iter()
                .map(|p| p.to_string_lossy().to_string())
                .collect(),
        }),
        ReaderBackend::Zip(zip) => Ok(ReaderPageListDto {
            resource_type: resource_type.clone(),
            page_count: crate::util::usize_to_i32(zip.entry_indices.len()),
            dir_page_paths: vec![],
        }),
        ReaderBackend::Epub(epub) => Ok(ReaderPageListDto {
            resource_type: "epub".to_string(),
            page_count: crate::util::usize_to_i32(epub.image_entries.len()),
            dir_page_paths: vec![],
        }),
        ReaderBackend::Rar(rar) => Ok(ReaderPageListDto {
            resource_type: resource_type.clone(),
            page_count: crate::util::usize_to_i32(rar.entry_names.len()),
            dir_page_paths: vec![],
        }),
        ReaderBackend::SevenZ(sevenz) => Ok(ReaderPageListDto {
            resource_type: resource_type.clone(),
            page_count: crate::util::usize_to_i32(sevenz.entry_names.len()),
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
    // First-open physical metadata writeback (ADR-0008 / #59). Best-effort.
    if let Err(err) = block_on(writeback_after_open(read, list.page_count)) {
        tracing::warn!(comic_id, error = %err, "page_count writeback failed");
    }
    Ok(list)
}

#[tracing::instrument(err, skip(read), fields(comic_id = read.comic_id, resource_type = read.resource_type))]
pub fn load_page_bytes(read: &ReaderSessionRead, page_index: i32) -> Result<Vec<u8>, HentaiError> {
    let page_index = usize::try_from(page_index)
        .map_err(|_| HentaiError::reader_invalid_content(format!("页索引无效: {page_index}")))?;
    read.with_backend(|backend| match backend {
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
