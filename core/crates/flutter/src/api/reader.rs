use hentai_core::{
    self, clear_reader_sessions, close_reader, load_page_bytes, load_page_list, open_reader,
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

#[flutter_rust_bridge::frb(sync)]
pub fn close_reader_frb(comic_id: String) {
    close_reader(&comic_id);
}

#[flutter_rust_bridge::frb(sync)]
pub fn clear_reader_sessions_frb() {
    clear_reader_sessions();
}
