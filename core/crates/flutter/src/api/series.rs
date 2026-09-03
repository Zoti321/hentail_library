use hentai_core::{
    count_all_series, fetch_series_comics_metadata as core_fetch_series_comics_metadata,
    fetch_series_comics_page as core_fetch_series_comics_page,
    fetch_series_page as core_fetch_page, find_series_by_id as core_find,
    get_all_series, get_series_reading_context_by_comic_id as core_get_reading_context,
    load_home_series_comic_order_map, search_series_by_keyword,
    search_series_by_tag_expression,
    set_series_item_sort_order_locked as core_set_item_sort_locked,
    set_series_items_order as core_set_order,
    set_series_meta_locks as core_set_meta_locks,
    update_series_item_sort_order as core_update_item_sort_order,
    update_series_user_meta as core_update_meta, watch_all_series, watch_home_series_comic_order_map,
    PagedSeriesComicsResultDto as CorePagedSeriesComics,
    PagedSeriesResultDto as CorePagedSeries, SeriesComicsMetadataDto as CoreSeriesComicsMetadata,
    SeriesDto as CoreSeries, SeriesFilterDto as CoreSeriesFilter, SeriesItemDto as CoreItem,
    SeriesReadingContextDto as CoreSeriesReadingContext,
    SeriesSortFieldDto as CoreSeriesSortField, SeriesSortOptionDto as CoreSeriesSort,
    SetSeriesMetaLocksDto as CoreSetSeriesMetaLocks,
    UpdateSeriesUserMetaDto as CoreUpdateSeriesUserMeta,
};

use super::comic::{ComicDto, PageRequestDto};
use super::init::HentaiErrorDto;
use super::stream_watch::{emit_or_closed, normalize_watch_result};

/// FRB 层 DTO：字段与 `hentai_core::SeriesItemDto` 对齐，避免跨 crate opaque 绑定。
#[derive(Debug, Clone)]
pub struct SeriesItemDto {
    pub series_id: String,
    pub comic_id: String,
    pub sort_order: f64,
    pub sort_order_locked: bool,
}

#[derive(Debug, Clone, Default)]
pub struct SeriesMetaLocksDto {
    pub name: bool,
    pub serialization_status: bool,
    pub total_count: bool,
}

/// FRB 层 DTO：字段与 `hentai_core::SeriesDto` 对齐。
#[derive(Debug, Clone)]
pub struct SeriesDto {
    pub series_id: String,
    pub folder_path: String,
    pub name: String,
    pub serialization_status: String,
    pub total_count: Option<i32>,
    pub locks: SeriesMetaLocksDto,
    pub items: Vec<SeriesItemDto>,
}

#[derive(Debug, Clone)]
pub struct SeriesFilterDto {
    pub show_r18: bool,
    pub r18_only: bool,
    pub query: Option<String>,
    pub require_items: bool,
    pub serialization_status: Option<String>,
    pub library_id: Option<String>,
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub enum SeriesSortFieldDto {
    #[default]
    Name,
    ComicCount,
    Random,
}

#[derive(Debug, Clone, Default)]
pub struct SeriesSortOptionDto {
    pub field: SeriesSortFieldDto,
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
    pub sort_order: f64,
}

#[derive(Debug, Clone)]
pub struct SeriesComicPageItemDto {
    pub comic: ComicDto,
    pub sort_order: f64,
    pub sort_order_locked: bool,
}

#[derive(Debug, Clone)]
pub struct PagedSeriesComicsResultDto {
    pub items: Vec<SeriesComicPageItemDto>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SeriesComicsMetadataDto {
    pub authors: Vec<String>,
    pub tags: Vec<String>,
    pub has_r18: bool,
    pub languages: Vec<String>,
    pub parodies: Vec<String>,
    pub characters: Vec<String>,
}

/// ADR-0005：由 comicId 派生的阅读器用系列上下文。
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SeriesReadingContextDto {
    pub series_id: String,
    pub series_name: String,
    pub ordered_comic_ids: Vec<String>,
    pub current_index: i32,
}

/// 与 core `UpdateSeriesUserMetaDto` 同名，减少 Dart/Rust 双命名。
#[derive(Debug, Clone, Default)]
pub struct UpdateSeriesUserMetaDto {
    pub name: Option<String>,
    pub serialization_status: Option<String>,
    pub total_count: Option<i32>,
    pub clear_total_count: bool,
}

#[derive(Debug, Clone, Default)]
pub struct SetSeriesMetaLocksDto {
    pub name: Option<bool>,
    pub serialization_status: Option<bool>,
    pub total_count: Option<bool>,
}

macro_rules! map_series_dto {
    ($core:expr) => {{
        let v = $core;
        SeriesDto {
            series_id: v.series_id,
            folder_path: v.folder_path,
            name: v.name,
            serialization_status: v.serialization_status,
            total_count: v.total_count,
            locks: SeriesMetaLocksDto {
                name: v.locks.name,
                serialization_status: v.locks.serialization_status,
                total_count: v.locks.total_count,
            },
            items: v
                .items
                .into_iter()
                .map(|i| SeriesItemDto {
                    series_id: i.series_id,
                    comic_id: i.comic_id,
                    sort_order: i.sort_order,
                    sort_order_locked: i.sort_order_locked,
                })
                .collect(),
        }
    }};
}

impl From<CoreItem> for SeriesItemDto {
    fn from(v: CoreItem) -> Self {
        Self {
            series_id: v.series_id,
            comic_id: v.comic_id,
            sort_order: v.sort_order,
            sort_order_locked: v.sort_order_locked,
        }
    }
}

impl From<CorePagedSeriesComics> for PagedSeriesComicsResultDto {
    fn from(value: CorePagedSeriesComics) -> Self {
        Self {
            items: value
                .items
                .into_iter()
                .map(|item| SeriesComicPageItemDto {
                    comic: ComicDto::from(item.comic),
                    sort_order: item.sort_order,
                    sort_order_locked: item.sort_order_locked,
                })
                .collect(),
            total_count: value.total_count,
            page: value.page,
            page_size: value.page_size,
        }
    }
}

impl From<CoreSeries> for SeriesDto {
    fn from(v: CoreSeries) -> Self {
        map_series_dto!(v)
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

impl From<CoreSeriesComicsMetadata> for SeriesComicsMetadataDto {
    fn from(value: CoreSeriesComicsMetadata) -> Self {
        Self {
            authors: value.authors,
            tags: value.tags,
            has_r18: value.has_r18,
            languages: value.languages,
            parodies: value.parodies,
            characters: value.characters,
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
            serialization_status: value.serialization_status,
            library_id: value.library_id,
        }
    }
}

impl From<SeriesSortOptionDto> for CoreSeriesSort {
    fn from(value: SeriesSortOptionDto) -> Self {
        CoreSeriesSort {
            field: match value.field {
                SeriesSortFieldDto::Name => CoreSeriesSortField::Name,
                SeriesSortFieldDto::ComicCount => CoreSeriesSortField::ComicCount,
                SeriesSortFieldDto::Random => CoreSeriesSortField::Random,
            },
            descending: value.descending,
        }
    }
}

impl From<UpdateSeriesUserMetaDto> for CoreUpdateSeriesUserMeta {
    fn from(value: UpdateSeriesUserMetaDto) -> Self {
        CoreUpdateSeriesUserMeta {
            name: value.name,
            serialization_status: value.serialization_status,
            total_count: value.total_count,
            clear_total_count: value.clear_total_count,
        }
    }
}

fn map_series_list(rows: Vec<CoreSeries>) -> Vec<SeriesDto> {
    rows.into_iter().map(SeriesDto::from).collect()
}

#[flutter_rust_bridge::frb]
pub async fn watch_all_series_frb(
    sink: crate::frb_generated::StreamSink<Vec<SeriesDto>>,
) -> Result<(), HentaiErrorDto> {
    normalize_watch_result(
        watch_all_series(|items| {
            emit_or_closed(&sink, map_series_list(items))
        })
        .await,
    )
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_all_series_frb() -> Result<Vec<SeriesDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(get_all_series())
        .map(map_series_list)
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn count_all_series_frb() -> Result<i64, HentaiErrorDto> {
    hentai_core::runtime::block_on(count_all_series()).map_err(HentaiErrorDto::from)
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
pub fn get_series_reading_context_by_comic_id_frb(
    comic_id: String,
) -> Result<Option<SeriesReadingContextDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_get_reading_context(&comic_id))
        .map(|opt| {
            opt.map(|v: CoreSeriesReadingContext| SeriesReadingContextDto {
                series_id: v.series_id,
                series_name: v.series_name,
                ordered_comic_ids: v.ordered_comic_ids,
                current_index: v.current_index,
            })
        })
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn fetch_series_comics_page_frb(
    series_id: String,
    request: PageRequestDto,
) -> Result<PagedSeriesComicsResultDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_fetch_series_comics_page(&series_id, request.into()))
        .map(PagedSeriesComicsResultDto::from)
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn fetch_series_comics_metadata_frb(
    series_id: String,
) -> Result<SeriesComicsMetadataDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_fetch_series_comics_metadata(&series_id))
        .map(SeriesComicsMetadataDto::from)
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_series_user_meta_frb(
    series_id: String,
    meta: UpdateSeriesUserMetaDto,
) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_update_meta(&series_id, meta.into()))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_series_meta_locks_frb(
    series_id: String,
    locks: SetSeriesMetaLocksDto,
) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_set_meta_locks(
        &series_id,
        CoreSetSeriesMetaLocks {
            name: locks.name,
            serialization_status: locks.serialization_status,
            total_count: locks.total_count,
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
pub fn update_series_item_sort_order_frb(
    series_id: String,
    comic_id: String,
    sort_order: f64,
) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_update_item_sort_order(
        &series_id,
        &comic_id,
        sort_order,
    ))
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_series_item_sort_order_locked_frb(
    series_id: String,
    comic_id: String,
    locked: bool,
) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_set_item_sort_locked(
        &series_id,
        &comic_id,
        locked,
    ))
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn search_series_by_keyword_frb(keyword: String) -> Result<Vec<SeriesDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(search_series_by_keyword(&keyword))
        .map(map_series_list)
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
    .map(map_series_list)
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

#[derive(Debug, Clone)]
pub struct RefreshSeriesResultFrbDto {
    pub succeeded: i32,
    pub failed: i32,
    pub cancelled: bool,
}

#[derive(Debug, Clone)]
pub struct RefreshLibraryResultFrbDto {
    pub succeeded: i32,
    pub failed: i32,
    pub cancelled: bool,
    pub skipped: bool,
    pub skip_message: Option<String>,
}

#[flutter_rust_bridge::frb]
pub async fn refresh_series_metadata_frb(
    series_id: String,
    handle: super::sync::SyncHandleDto,
) -> Result<RefreshSeriesResultFrbDto, HentaiErrorDto> {
    let result = hentai_core::refresh_series_metadata(&series_id, &handle.inner, |_| {})
        .await
        .map_err(HentaiErrorDto::from)?;
    Ok(RefreshSeriesResultFrbDto {
        succeeded: result.succeeded,
        failed: result.failed,
        cancelled: result.cancelled,
    })
}

#[flutter_rust_bridge::frb]
pub async fn refresh_library_metadata_frb(
    library_id: String,
    handle: super::sync::SyncHandleDto,
) -> Result<RefreshLibraryResultFrbDto, HentaiErrorDto> {
    let result = hentai_core::refresh_library_metadata(&library_id, &handle.inner, |_| {})
        .await
        .map_err(HentaiErrorDto::from)?;
    Ok(RefreshLibraryResultFrbDto {
        succeeded: result.succeeded,
        failed: result.failed,
        cancelled: result.cancelled,
        skipped: result.skipped,
        skip_message: result.skip_message,
    })
}
