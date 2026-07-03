use hentai_core::{
    add_author as core_add, count_all_authors as core_count, delete_authors_by_names,
    fetch_authors_page as core_fetch, list_all_authors, rename_author as core_rename, watch_authors,
};

use super::comic::PageRequestDto;
use super::init::HentaiErrorDto;

#[derive(Debug, Clone)]
pub struct AuthorPagedNamesDto {
    pub items: Vec<String>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

#[flutter_rust_bridge::frb(sync)]
pub fn list_all_authors_frb() -> Result<Vec<String>, HentaiErrorDto> {
    hentai_core::runtime::block_on(list_all_authors()).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn fetch_authors_page_frb(request: PageRequestDto) -> Result<AuthorPagedNamesDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(async {
        let total = core_count().await?;
        let page_size = request.page_size.max(1);
        if total <= 0 {
            return Ok::<AuthorPagedNamesDto, hentai_core::HentaiError>(AuthorPagedNamesDto {
                items: vec![],
                total_count: 0,
                page: 1,
                page_size,
            });
        }
        let total_pages = (total + page_size as i64 - 1) / page_size as i64;
        let mut page = request.page.max(1);
        if page as i64 > total_pages {
            page = total_pages as i32;
        }
        let offset = (page - 1) * page_size;
        let items = core_fetch(page_size, offset).await?;
        Ok(AuthorPagedNamesDto {
            items,
            total_count: total,
            page,
            page_size,
        })
    })
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn add_author_frb(name: String) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_add(&name)).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_authors_by_names_frb(names: Vec<String>) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(delete_authors_by_names(names)).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn rename_author_frb(old_name: String, new_name: String) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_rename(&old_name, &new_name)).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn watch_authors_frb(sink: crate::frb_generated::StreamSink<Vec<String>>) -> Result<(), HentaiErrorDto> {
    watch_authors(|items| {
        sink.add(items)
            .map_err(|_| hentai_core::HentaiError::validation("stream closed"))
    })
    .await
    .map_err(HentaiErrorDto::from)
}
