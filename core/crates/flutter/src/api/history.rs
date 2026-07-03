use hentai_core::{
    self, clear_all_reading as core_clear_all, delete_reading_by_comic_id as core_delete_reading,
    delete_reading_by_comic_ids as core_delete_readings, delete_series_reading_by_last_read_comic_ids,
    delete_series_reading_by_name, fetch_reading_page as core_fetch_reading_page,
    fetch_series_reading_page as core_fetch_series_page, get_reading_by_comic_id as core_get_reading,
    get_series_reading_by_name as core_get_series_reading, list_all_reading, list_all_series_reading,
    record_reading as core_record_reading, record_series_reading as core_record_series_reading,
    watch_reading_histories as core_watch_reading, watch_series_reading_histories as core_watch_series,
    PagedReadingHistoryDto as CorePagedReading, PagedSeriesReadingHistoryDto as CorePagedSeries,
    ReadingHistoryDto as CoreReading, SeriesReadingHistoryDto as CoreSeriesReading,
};

use super::init::HentaiErrorDto;

#[derive(Debug, Clone)]
pub struct ReadingHistoryDto {
    pub comic_id: String,
    pub title: String,
    pub last_read_time_ms: i64,
    pub page_index: Option<i32>,
}

#[derive(Debug, Clone)]
pub struct SeriesReadingHistoryDto {
    pub series_name: String,
    pub last_read_comic_id: String,
    pub last_read_time_ms: i64,
    pub page_index: Option<i32>,
}

#[derive(Debug, Clone)]
pub struct PagedReadingHistoryDto {
    pub items: Vec<ReadingHistoryDto>,
    pub total_count: i64,
}

#[derive(Debug, Clone)]
pub struct PagedSeriesReadingHistoryDto {
    pub items: Vec<SeriesReadingHistoryDto>,
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

impl From<CoreSeriesReading> for SeriesReadingHistoryDto {
    fn from(v: CoreSeriesReading) -> Self {
        Self {
            series_name: v.series_name,
            last_read_comic_id: v.last_read_comic_id,
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

impl From<CorePagedSeries> for PagedSeriesReadingHistoryDto {
    fn from(v: CorePagedSeries) -> Self {
        Self {
            items: v
                .items
                .into_iter()
                .map(SeriesReadingHistoryDto::from)
                .collect(),
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

impl From<&SeriesReadingHistoryDto> for CoreSeriesReading {
    fn from(v: &SeriesReadingHistoryDto) -> Self {
        Self {
            series_name: v.series_name.clone(),
            last_read_comic_id: v.last_read_comic_id.clone(),
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
pub fn record_series_reading_frb(history: SeriesReadingHistoryDto) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_record_series_reading(&(&history).into()))
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
pub fn get_series_reading_by_name_frb(
    series_name: String,
) -> Result<Option<SeriesReadingHistoryDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_get_series_reading(&series_name))
        .map(|opt| opt.map(SeriesReadingHistoryDto::from))
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
pub fn fetch_series_reading_page_frb(
    page: i32,
    page_size: i32,
) -> Result<PagedSeriesReadingHistoryDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_fetch_series_page(page, page_size))
        .map(PagedSeriesReadingHistoryDto::from)
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
pub fn delete_series_reading_by_name_frb(series_name: String) -> Result<i32, HentaiErrorDto> {
    hentai_core::runtime::block_on(delete_series_reading_by_name(&series_name))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_series_reading_by_last_read_comic_ids_frb(
    comic_ids: Vec<String>,
) -> Result<i32, HentaiErrorDto> {
    hentai_core::runtime::block_on(delete_series_reading_by_last_read_comic_ids(&comic_ids))
        .map_err(HentaiErrorDto::from)
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
    if sink.add(initial).is_err() {
        return Ok(());
    }
    core_watch_reading(|items| {
        let mapped: Vec<ReadingHistoryDto> = items.into_iter().map(ReadingHistoryDto::from).collect();
        sink.add(mapped)
            .map_err(|_| hentai_core::HentaiError::validation("stream closed"))
    })
    .await
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn watch_series_reading_histories_frb(
    sink: crate::frb_generated::StreamSink<Vec<SeriesReadingHistoryDto>>,
) -> Result<(), HentaiErrorDto> {
    let initial = list_all_series_reading()
        .await
        .map_err(HentaiErrorDto::from)?
        .into_iter()
        .map(SeriesReadingHistoryDto::from)
        .collect();
    if sink.add(initial).is_err() {
        return Ok(());
    }
    core_watch_series(|items| {
        let mapped: Vec<SeriesReadingHistoryDto> =
            items.into_iter().map(SeriesReadingHistoryDto::from).collect();
        sink.add(mapped)
            .map_err(|_| hentai_core::HentaiError::validation("stream closed"))
    })
    .await
    .map_err(HentaiErrorDto::from)
}
