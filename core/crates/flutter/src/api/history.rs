use hentai_core::{
    self, clear_all_reading as core_clear_all, delete_reading_by_comic_id as core_delete_reading,
    delete_reading_by_comic_ids as core_delete_readings, fetch_reading_page as core_fetch_reading_page,
    get_reading_by_comic_id as core_get_reading, list_all_reading, record_reading as core_record_reading,
    watch_reading_histories as core_watch_reading, PagedReadingHistoryDto as CorePagedReading,
    ReadingHistoryDto as CoreReading,
};

use super::init::HentaiErrorDto;
use super::stream_watch::{emit_or_closed, normalize_watch_result};

#[derive(Debug, Clone)]
pub struct ReadingHistoryDto {
    pub comic_id: String,
    pub title: String,
    pub last_read_time_ms: i64,
    pub page_index: Option<i32>,
}

#[derive(Debug, Clone)]
pub struct PagedReadingHistoryDto {
    pub items: Vec<ReadingHistoryDto>,
    pub total_count: i64,
}

impl From<CoreReading> for ReadingHistoryDto {
    fn from(v: CoreReading) -> Self {
        Self {
            comic_id: v.comic_id,
            title: v.title,
            last_read_time_ms: v.last_read_time_ms,
            page_index: v.page_index,
        }
    }
}

impl From<CorePagedReading> for PagedReadingHistoryDto {
    fn from(v: CorePagedReading) -> Self {
        Self {
            items: v.items.into_iter().map(ReadingHistoryDto::from).collect(),
            total_count: v.total_count,
        }
    }
}

impl From<&ReadingHistoryDto> for CoreReading {
    fn from(v: &ReadingHistoryDto) -> Self {
        Self {
            comic_id: v.comic_id.clone(),
            title: v.title.clone(),
            last_read_time_ms: v.last_read_time_ms,
            page_index: v.page_index,
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn record_reading_frb(history: ReadingHistoryDto) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_record_reading(&(&history).into()))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_reading_by_comic_id_frb(
    comic_id: String,
) -> Result<Option<ReadingHistoryDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_get_reading(&comic_id))
        .map(|opt| opt.map(ReadingHistoryDto::from))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn fetch_reading_page_frb(
    page: i32,
    page_size: i32,
) -> Result<PagedReadingHistoryDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_fetch_reading_page(page, page_size))
        .map(PagedReadingHistoryDto::from)
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_reading_by_comic_id_frb(comic_id: String) -> Result<i32, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_delete_reading(&comic_id)).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_reading_by_comic_ids_frb(comic_ids: Vec<String>) -> Result<i32, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_delete_readings(&comic_ids)).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn clear_all_reading_frb() -> Result<i32, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_clear_all()).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn watch_reading_histories_frb(
    sink: crate::frb_generated::StreamSink<Vec<ReadingHistoryDto>>,
) -> Result<(), HentaiErrorDto> {
    let initial = list_all_reading()
        .await
        .map_err(HentaiErrorDto::from)?
        .into_iter()
        .map(ReadingHistoryDto::from)
        .collect();
    if emit_or_closed(&sink, initial).is_err() {
        return Ok(());
    }
    normalize_watch_result(
        core_watch_reading(|items| {
            let mapped: Vec<ReadingHistoryDto> =
                items.into_iter().map(ReadingHistoryDto::from).collect();
            emit_or_closed(&sink, mapped)
        })
        .await,
    )
}
