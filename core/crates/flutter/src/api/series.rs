use hentai_core::{
    fetch_series_page as core_fetch_page, find_series_by_id as core_find, get_all_series,
    load_home_series_comic_order_map, search_series_by_keyword, search_series_by_tag_expression,
    set_series_items_order as core_set_order, update_series_user_meta as core_update_meta,
    watch_all_series, watch_home_series_comic_order_map, PagedSeriesResultDto as CorePagedSeries,
    SeriesDto as CoreSeries, SeriesFilterDto as CoreSeriesFilter, SeriesItemDto as CoreItem,
    SeriesSortOptionDto as CoreSeriesSort, UpdateSeriesUserMetaDto as CoreUpdateSeriesUserMeta,
};

use super::comic::PageRequestDto;
use super::init::HentaiErrorDto;
use super::stream_watch::{emit_or_closed, normalize_watch_result};

#[derive(Debug, Clone)]
pub struct SeriesItemDto {
    pub series_id: String,
    pub comic_id: String,
    pub sort_order: i32,
}

#[derive(Debug, Clone)]
pub struct SeriesDto {
    pub series_id: String,
    pub folder_path: String,
    pub name: String,
    pub serialization_status: String,
    pub total_count: Option<i32>,
    pub items: Vec<SeriesItemDto>,
}

#[derive(Debug, Clone)]
pub struct SeriesFilterDto {
    pub show_r18: bool,
    pub r18_only: bool,
    pub query: Option<String>,
    pub require_items: bool,
}

#[derive(Debug, Clone)]
pub struct SeriesSortOptionDto {
    pub descending: bool,
}

#[derive(Debug, Clone)]
pub struct PagedSeriesResultDto {
    pub items: Vec<SeriesDto>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

#[derive(Debug, Clone)]
pub struct SeriesComicOrderEntryDto {
    pub key: String,
    pub sort_order: i32,
}

#[derive(Debug, Clone, Default)]
pub struct UpdateSeriesUserMetaFrbDto {
    pub name: Option<String>,
    pub serialization_status: Option<String>,
    pub total_count: Option<i32>,
    pub clear_total_count: bool,
}

impl From<CoreItem> for SeriesItemDto {
    fn from(v: CoreItem) -> Self {
        Self {
            series_id: v.series_id,
            comic_id: v.comic_id,
            sort_order: v.sort_order,
        }
    }
}

impl From<CorePagedSeries> for PagedSeriesResultDto {
    fn from(value: CorePagedSeries) -> Self {
        Self {
            items: value.items.into_iter().map(SeriesDto::from).collect(),
            total_count: value.total_count,
            page: value.page,
            page_size: value.page_size,
        }
    }
}

impl From<SeriesFilterDto> for CoreSeriesFilter {
    fn from(value: SeriesFilterDto) -> Self {
        CoreSeriesFilter {
            show_r18: value.show_r18,
            r18_only: value.r18_only,
            query: value.query,
            require_items: value.require_items,
        }
    }
}

impl From<SeriesSortOptionDto> for CoreSeriesSort {
    fn from(value: SeriesSortOptionDto) -> Self {
        CoreSeriesSort {
            descending: value.descending,
        }
    }
}

impl From<CoreSeries> for SeriesDto {
    fn from(v: CoreSeries) -> Self {
        Self {
            series_id: v.series_id,
            folder_path: v.folder_path,
            name: v.name,
            serialization_status: v.serialization_status,
            total_count: v.total_count,
            items: v.items.into_iter().map(SeriesItemDto::from).collect(),
        }
    }
}

#[flutter_rust_bridge::frb]
pub async fn watch_all_series_frb(
    sink: crate::frb_generated::StreamSink<Vec<SeriesDto>>,
) -> Result<(), HentaiErrorDto> {
    normalize_watch_result(
        watch_all_series(|items| {
            let mapped = items.into_iter().map(SeriesDto::from).collect();
            emit_or_closed(&sink, mapped)
        })
        .await,
    )
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_all_series_frb() -> Result<Vec<SeriesDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(get_all_series())
        .map(|rows| rows.into_iter().map(SeriesDto::from).collect())
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn fetch_series_page_frb(
    request: PageRequestDto,
    filter: SeriesFilterDto,
    sort: SeriesSortOptionDto,
) -> Result<PagedSeriesResultDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_fetch_page(request.into(), filter.into(), sort.into()))
        .map(PagedSeriesResultDto::from)
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn find_series_by_id_frb(series_id: String) -> Result<Option<SeriesDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_find(&series_id))
        .map(|opt| opt.map(SeriesDto::from))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_series_user_meta_frb(
    series_id: String,
    meta: UpdateSeriesUserMetaFrbDto,
) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_update_meta(
        &series_id,
        CoreUpdateSeriesUserMeta {
            name: meta.name,
            serialization_status: meta.serialization_status,
            total_count: meta.total_count,
            clear_total_count: meta.clear_total_count,
        },
    ))
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_series_items_order_frb(
    series_id: String,
    ordered_comic_ids: Vec<String>,
) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_set_order(&series_id, ordered_comic_ids))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn search_series_by_keyword_frb(keyword: String) -> Result<Vec<SeriesDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(search_series_by_keyword(&keyword))
        .map(|rows| rows.into_iter().map(SeriesDto::from).collect())
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn search_series_by_tag_expression_frb(
    must_include: Vec<String>,
    optional_or: Vec<String>,
    must_exclude: Vec<String>,
) -> Result<Vec<SeriesDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(search_series_by_tag_expression(
        must_include,
        optional_or,
        must_exclude,
    ))
    .map(|rows| rows.into_iter().map(SeriesDto::from).collect())
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn load_home_series_comic_order_map_frb() -> Result<Vec<SeriesComicOrderEntryDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(load_home_series_comic_order_map())
        .map(|map| {
            map.into_iter()
                .map(|(key, sort_order)| SeriesComicOrderEntryDto { key, sort_order })
                .collect()
        })
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn watch_home_series_comic_order_map_frb(
    sink: crate::frb_generated::StreamSink<Vec<SeriesComicOrderEntryDto>>,
) -> Result<(), HentaiErrorDto> {
    normalize_watch_result(
        watch_home_series_comic_order_map(|map| {
            let items = map
                .into_iter()
                .map(|(key, sort_order)| SeriesComicOrderEntryDto { key, sort_order })
                .collect();
            emit_or_closed(&sink, items)
        })
        .await,
    )
}
