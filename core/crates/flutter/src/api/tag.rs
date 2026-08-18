use hentai_core::{
    add_tag as core_add, count_all_tags as core_count, delete_tags_by_names, fetch_tags_page as core_fetch,
    import_ehtag_dictionary as core_import_ehtag, list_all_tags, rename_tag as core_rename, watch_tags,
    TagDictionaryImportResult,
};

use super::comic::PageRequestDto;
use super::init::HentaiErrorDto;
use super::stream_watch::{emit_or_closed, normalize_watch_result};

#[derive(Debug, Clone)]
pub struct TagPagedNamesDto {
    pub items: Vec<String>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

#[derive(Debug, Clone)]
pub struct TagDictionaryImportResultDto {
    pub added: i32,
    pub skipped_existing: i32,
    pub skipped_filtered_or_empty_or_dedupe: i32,
}

impl From<TagDictionaryImportResult> for TagDictionaryImportResultDto {
    fn from(value: TagDictionaryImportResult) -> Self {
        Self {
            added: value.added as i32,
            skipped_existing: value.skipped_existing as i32,
            skipped_filtered_or_empty_or_dedupe: value.skipped_filtered_or_empty_or_dedupe as i32,
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn import_ehtag_dictionary_frb(json_bytes: Vec<u8>) -> Result<TagDictionaryImportResultDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_import_ehtag(&json_bytes))
        .map(TagDictionaryImportResultDto::from)
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn list_all_tags_frb() -> Result<Vec<String>, HentaiErrorDto> {
    hentai_core::runtime::block_on(list_all_tags()).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn fetch_tags_page_frb(request: PageRequestDto) -> Result<TagPagedNamesDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(async {
        let total = core_count().await?;
        let page_size = request.page_size.max(1);
        if total <= 0 {
            return Ok::<TagPagedNamesDto, hentai_core::HentaiError>(TagPagedNamesDto {
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
        Ok(TagPagedNamesDto {
            items,
            total_count: total,
            page,
            page_size,
        })
    })
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn add_tag_frb(name: String) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_add(&name)).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_tags_by_names_frb(names: Vec<String>) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(delete_tags_by_names(names)).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn rename_tag_frb(old_name: String, new_name: String) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_rename(&old_name, &new_name)).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn watch_tags_frb(sink: crate::frb_generated::StreamSink<Vec<String>>) -> Result<(), HentaiErrorDto> {
    normalize_watch_result(watch_tags(|items| emit_or_closed(&sink, items)).await)
}
