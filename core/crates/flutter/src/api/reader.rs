use hentai_core::{
    self, clear_reader_page_cache, clear_reader_sessions, close_reader, load_page_bytes,
    load_page_list, load_reader_page, open_reader, prefetch_reader_pages, ReaderPageCacheRequest,
    ReaderPageDto as CoreDto, ReaderPageRead, ReaderSessionRead,
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

#[flutter_rust_bridge::frb]
pub async fn open_reader_frb(
    comic_id: String,
    path: String,
    resource_type: String,
) -> Result<(), HentaiErrorDto> {
    tokio::task::spawn_blocking(move || open_reader(&comic_id, &path, &resource_type))
        .await
        .map_err(|error| {
            HentaiErrorDto::from(hentai_core::HentaiError::reader_invalid_content(
                error.to_string(),
            ))
        })?
        .map_err(HentaiErrorDto::from)
}

/// 会话已 open：仅传 comic_id，path/resource_type 从会话取。
#[flutter_rust_bridge::frb]
pub async fn load_page_list_frb(comic_id: String) -> Result<ReaderPageListDto, HentaiErrorDto> {
    let read = capture_session(&comic_id)?;
    tokio::task::spawn_blocking(move || load_page_list(&read).map(ReaderPageListDto::from))
        .await
        .map_err(|error| {
            HentaiErrorDto::from(hentai_core::HentaiError::reader_invalid_content(
                error.to_string(),
            ))
        })?
        .map_err(HentaiErrorDto::from)
}

/// 会话已 open：仅传 comic_id + 页码。
#[flutter_rust_bridge::frb]
pub async fn load_page_bytes_frb(
    comic_id: String,
    page_index: i32,
) -> Result<Vec<u8>, HentaiErrorDto> {
    let read = capture_session(&comic_id)?;
    tokio::task::spawn_blocking(move || load_page_bytes(&read, page_index))
        .await
        .map_err(|error| {
            HentaiErrorDto::from(hentai_core::HentaiError::reader_invalid_content(
                error.to_string(),
            ))
        })?
        .map_err(HentaiErrorDto::from)
}

/// 会话已 open：仅传 comic_id + 页码。
#[flutter_rust_bridge::frb]
pub async fn load_reader_page_frb(
    comic_id: String,
    page_index: i32,
) -> Result<ReaderPageDto, HentaiErrorDto> {
    let read = tokio::task::block_in_place(|| ReaderPageRead::capture(&comic_id))
        .map_err(HentaiErrorDto::from)?;
    tokio::task::spawn_blocking(move || load_reader_page(&read, page_index).map(ReaderPageDto::from))
        .await
        .map_err(|error| {
            HentaiErrorDto::from(hentai_core::HentaiError::reader_invalid_content(
                error.to_string(),
            ))
        })?
        .map_err(HentaiErrorDto::from)
}

/// 会话已 open：仅传 comic_id + 页码列表。
#[flutter_rust_bridge::frb]
pub async fn prefetch_reader_pages_frb(
    comic_id: String,
    page_indexes: Vec<i32>,
    generation: u64,
) -> Result<(), HentaiErrorDto> {
    // Client generations remain on the wire; native ownership follows accepted requests.
    let _ = generation;
    let request = ReaderPageCacheRequest::begin(&comic_id);
    let Ok(session) = capture_session(&comic_id) else {
        return Ok(());
    };
    tokio::spawn(async move {
        let _ = tokio::task::spawn_blocking(move || {
            prefetch_reader_pages(request, &session, &page_indexes)
        })
        .await;
    });
    Ok(())
}

fn capture_session(comic_id: &str) -> Result<ReaderSessionRead, HentaiErrorDto> {
    // Native FRB uses a multithread runtime; compensate while waiting for a decoding session.
    tokio::task::block_in_place(|| ReaderSessionRead::capture(comic_id))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn clear_reader_page_cache_frb(comic_id: String) -> Result<(), HentaiErrorDto> {
    let request = ReaderPageCacheRequest::begin_clear(&comic_id);
    tokio::task::spawn_blocking(move || clear_reader_page_cache(&request))
        .await
        .map_err(|error| {
            HentaiErrorDto::from(hentai_core::HentaiError::reader_invalid_content(
                error.to_string(),
            ))
        })?
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn close_reader_frb(comic_id: String) -> Result<(), HentaiErrorDto> {
    tokio::task::spawn_blocking(move || close_reader(&comic_id))
        .await
        .map_err(|error| {
            HentaiErrorDto::from(hentai_core::HentaiError::reader_invalid_content(
                error.to_string(),
            ))
        })?;
    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn clear_reader_sessions_frb() {
    clear_reader_sessions();
}
