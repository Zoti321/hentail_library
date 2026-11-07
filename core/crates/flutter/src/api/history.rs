use hentai_core::{
    self, clear_all_reading as core_clear_all, delete_reading_by_comic_id as core_delete_reading,
    delete_reading_by_comic_ids as core_delete_readings,
    fetch_reading_page as core_fetch_reading_page, get_reading_by_comic_id as core_get_reading,
    list_read_page_indexes as core_list_read_page_indexes, record_reading as core_record_reading,
    PagedReadingHistoryDto as CorePagedReading, ReadPageIndexDto as CoreReadPageIndex,
    ReadingHistoryDto as CoreReading,
};

use super::comic::PageRequestDto;
use super::init::HentaiErrorDto;

#[derive(Debug, Clone)]
pub struct ReadingHistoryDto {
    pub comic_id: String,
    pub title: String,
    pub last_read_time_ms: i64,
    pub page_index: Option<i32>,
    pub page_count: Option<i32>,
}

#[derive(Debug, Clone)]
pub struct ReadPageIndexDto {
    pub comic_id: String,
    pub page_index: i32,
}

#[derive(Debug, Clone)]
pub struct PagedReadingHistoryDto {
    pub items: Vec<ReadingHistoryDto>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

impl From<CoreReading> for ReadingHistoryDto {
    fn from(v: CoreReading) -> Self {
        Self {
            comic_id: v.comic_id,
            title: v.title,
            last_read_time_ms: v.last_read_time_ms,
            page_index: v.page_index,
            page_count: v.page_count,
        }
    }
}

impl From<CoreReadPageIndex> for ReadPageIndexDto {
    fn from(v: CoreReadPageIndex) -> Self {
        Self {
            comic_id: v.comic_id,
            page_index: v.page_index,
        }
    }
}

impl From<CorePagedReading> for PagedReadingHistoryDto {
    fn from(v: CorePagedReading) -> Self {
        Self {
            items: v.items.into_iter().map(ReadingHistoryDto::from).collect(),
            total_count: v.total_count,
            page: v.page,
            page_size: v.page_size,
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
            page_count: None,
        }
    }
}

#[flutter_rust_bridge::frb]
pub async fn record_reading_frb(history: ReadingHistoryDto) -> Result<(), HentaiErrorDto> {
    core_record_reading(&(&history).into())
        .await
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn get_reading_by_comic_id_frb(
    comic_id: String,
) -> Result<Option<ReadingHistoryDto>, HentaiErrorDto> {
    core_get_reading(&comic_id)
        .await
        .map(|opt| opt.map(ReadingHistoryDto::from))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn fetch_reading_page_frb(
    request: PageRequestDto,
    keyword: Option<String>,
) -> Result<PagedReadingHistoryDto, HentaiErrorDto> {
    core_fetch_reading_page(request.into(), keyword)
        .await
        .map(PagedReadingHistoryDto::from)
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn list_read_page_indexes_frb() -> Result<Vec<ReadPageIndexDto>, HentaiErrorDto> {
    core_list_read_page_indexes()
        .await
        .map(|rows| rows.into_iter().map(ReadPageIndexDto::from).collect())
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
pub async fn watch_reading_history_changes_frb(
    sink: crate::frb_generated::StreamSink<i32>,
) -> Result<(), HentaiErrorDto> {
    let mut changes = hentai_core::revision::subscribe();
    while changes.changed().await.is_ok() {
        let generation = *changes.borrow_and_update();
        if sink.add((generation & 0x7fff_ffff) as i32).is_err() {
            break;
        }
    }
    Ok(())
}
