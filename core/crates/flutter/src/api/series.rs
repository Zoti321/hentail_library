use hentai_core::{
    assign_comic_exclusive as core_assign, count_all_series as core_count, create_series as core_create,
    delete_series as core_delete, fetch_series_page as core_fetch_page, find_series_by_name as core_find,
    get_all_series, infer_series as core_infer_series, load_home_series_comic_order_map,
    remove_comic_from_series as core_remove_comic, remove_comics_from_series as core_remove_comics,
    remove_orphan_series_items_public, rename_series as core_rename, search_series_by_keyword,
    search_series_by_tag_expression, set_series_items_order as core_set_order, watch_all_series,
    watch_home_series_comic_order_map, InferSeriesResultDto as CoreInferResult, SeriesDto as CoreSeries,
    SeriesItemDto as CoreItem,
};

use super::comic::PageRequestDto;
use super::init::HentaiErrorDto;
use super::stream_watch::{emit_or_closed, normalize_watch_result};

#[derive(Debug, Clone)]
pub struct InferSeriesResultDto {
    pub groups_applied: i32,
    pub comics_assigned: i32,
    pub new_series_created: i32,
}

#[derive(Debug, Clone)]
pub struct SeriesItemDto {
    pub series_name: String,
    pub comic_id: String,
    pub sort_order: i32,
}

#[derive(Debug, Clone)]
pub struct SeriesDto {
    pub name: String,
    pub items: Vec<SeriesItemDto>,
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

impl From<CoreInferResult> for InferSeriesResultDto {
    fn from(value: CoreInferResult) -> Self {
        Self {
            groups_applied: value.groups_applied,
            comics_assigned: value.comics_assigned,
            new_series_created: value.new_series_created,
        }
    }
}

impl From<CoreItem> for SeriesItemDto {
    fn from(v: CoreItem) -> Self {
        Self {
            series_name: v.series_name,
            comic_id: v.comic_id,
            sort_order: v.sort_order,
        }
    }
}

impl From<CoreSeries> for SeriesDto {
    fn from(v: CoreSeries) -> Self {
        Self {
            name: v.name,
            items: v.items.into_iter().map(SeriesItemDto::from).collect(),
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn infer_series_frb() -> Result<InferSeriesResultDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_infer_series())
        .map(InferSeriesResultDto::from)
        .map_err(HentaiErrorDto::from)
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
pub fn fetch_series_page_frb(request: PageRequestDto) -> Result<PagedSeriesResultDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(async {
        let total = core_count().await?;
        let page_size = request.page_size.max(1);
        if total <= 0 {
            return Ok::<PagedSeriesResultDto, hentai_core::HentaiError>(PagedSeriesResultDto {
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
        let items = core_fetch_page(page_size, offset)
            .await?
            .into_iter()
            .map(SeriesDto::from)
            .collect();
        Ok(PagedSeriesResultDto {
            items,
            total_count: total,
            page,
            page_size,
        })
    })
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn find_series_by_name_frb(name: String) -> Result<Option<SeriesDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_find(&name))
        .map(|opt| opt.map(SeriesDto::from))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_series_frb(name: String) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_create(&name)).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn rename_series_frb(name: String, new_name: String) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_rename(&name, &new_name)).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_series_frb(name: String) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_delete(&name)).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn assign_comic_exclusive_frb(
    comic_id: String,
    target_series_name: String,
    sort_order: i32,
) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_assign(&comic_id, &target_series_name, sort_order))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn remove_comic_from_series_frb(comic_id: String) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_remove_comic(&comic_id)).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn remove_comics_from_series_frb(comic_ids: Vec<String>) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_remove_comics(comic_ids)).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn remove_orphan_series_items_frb() -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(remove_orphan_series_items_public()).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_series_items_order_frb(
    series_name: String,
    ordered_comic_ids: Vec<String>,
) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_set_order(&series_name, ordered_comic_ids))
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
