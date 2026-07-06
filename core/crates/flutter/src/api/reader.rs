use hentai_core::{
    self, clear_reader_page_cache, clear_reader_sessions, close_reader, load_page_bytes,
    load_page_list, load_reader_page, open_reader, prefetch_reader_pages, ReaderPageDto as CoreDto,
};

use super::init::HentaiErrorDto;

#[derive(Debug, Clone)]
pub struct ReaderPageListDto {
    pub resource_type: String,
    pub page_count: i32,
    pub dir_page_paths: Vec<String>,
}

impl From<hentai_core::ReaderPageListDto> for ReaderPageListDto {
    fn from(value: hentai_core::ReaderPageListDto) -> Self {
        Self {
            resource_type: value.resource_type,
            page_count: value.page_count,
            dir_page_paths: value.dir_page_paths,
        }
    }
}

#[derive(Debug, Clone)]
pub enum ReaderPageDto {
    FilePath { path: String },
    Bytes { data: Vec<u8> },
}

impl From<CoreDto> for ReaderPageDto {
    fn from(value: CoreDto) -> Self {
        match value {
            CoreDto::FilePath { path } => ReaderPageDto::FilePath { path },
            CoreDto::Bytes { data } => ReaderPageDto::Bytes { data },
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn open_reader_frb(
    comic_id: String,
    path: String,
    resource_type: String,
) -> Result<(), HentaiErrorDto> {
    open_reader(&comic_id, &path, &resource_type).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn load_page_list_frb(
    comic_id: String,
    path: String,
    resource_type: String,
) -> Result<ReaderPageListDto, HentaiErrorDto> {
    load_page_list(&comic_id, &path, &resource_type)
        .map(ReaderPageListDto::from)
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn load_page_bytes_frb(
    comic_id: String,
    path: String,
    resource_type: String,
    page_index: i32,
) -> Result<Vec<u8>, HentaiErrorDto> {
    load_page_bytes(&comic_id, &path, &resource_type, page_index).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn load_reader_page_frb(
    comic_id: String,
    path: String,
    resource_type: String,
    page_index: i32,
) -> Result<ReaderPageDto, HentaiErrorDto> {
    tokio::task::spawn_blocking(move || {
        load_reader_page(&comic_id, &path, &resource_type, page_index).map(ReaderPageDto::from)
    })
    .await
    .map_err(|error| {
        HentaiErrorDto::from(hentai_core::HentaiError::reader_invalid_content(error.to_string()))
    })?
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn prefetch_reader_pages_frb(
    comic_id: String,
    path: String,
    resource_type: String,
    page_indexes: Vec<i32>,
    generation: u64,
) -> Result<(), HentaiErrorDto> {
    tokio::spawn(async move {
        let _ = tokio::task::spawn_blocking(move || {
            prefetch_reader_pages(
                &comic_id,
                &path,
                &resource_type,
                &page_indexes,
                generation,
            )
        })
        .await;
    });
    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn clear_reader_page_cache_frb(comic_id: String) -> Result<(), HentaiErrorDto> {
    clear_reader_page_cache(&comic_id).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn close_reader_frb(comic_id: String) {
    close_reader(&comic_id);
}

#[flutter_rust_bridge::frb(sync)]
pub fn clear_reader_sessions_frb() {
    clear_reader_sessions();
}
