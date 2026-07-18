use hentai_core::{
    delete_thumbnails_by_comic_ids, ensure_thumbnail, find_series_thumbnail_by_series_id,
    find_thumbnail_by_comic_id, resolve_series_cover, set_comic_thumbnail_from_page,
    set_series_thumbnail_from_page, watch_thumbnail_events, ComicThumbnailDto as CoreThumb,
    SeriesCoverSource as CoreSeriesCover, SeriesThumbnailDto as CoreSeriesThumb,
    ThumbnailEvent as CoreEvent, ThumbnailPriority as CorePriority,
};

use super::init::HentaiErrorDto;
use super::stream_watch::{emit_or_closed, normalize_watch_result};

#[derive(Debug, Clone)]
pub struct ComicThumbnailDto {
    pub thumbnail: Vec<u8>,
    pub source_modified_ms: i64,
    pub source_size: i64,
    pub is_user_set: bool,
}

impl From<CoreThumb> for ComicThumbnailDto {
    fn from(v: CoreThumb) -> Self {
        Self {
            thumbnail: v.thumbnail,
            source_modified_ms: v.source_modified_ms,
            source_size: v.source_size,
            is_user_set: v.is_user_set,
        }
    }
}

#[derive(Debug, Clone)]
pub struct SeriesThumbnailDto {
    pub thumbnail: Vec<u8>,
    pub source_comic_id: String,
    pub source_page_index: i32,
}

impl From<CoreSeriesThumb> for SeriesThumbnailDto {
    fn from(v: CoreSeriesThumb) -> Self {
        Self {
            thumbnail: v.thumbnail,
            source_comic_id: v.source_comic_id,
            source_page_index: v.source_page_index,
        }
    }
}

#[derive(Debug, Clone)]
pub enum SeriesCoverSourceDto {
    CustomThumbnail { thumbnail: Vec<u8> },
    FallbackComic { comic_id: String },
    Missing,
}

impl From<CoreSeriesCover> for SeriesCoverSourceDto {
    fn from(value: CoreSeriesCover) -> Self {
        match value {
            CoreSeriesCover::CustomThumbnail { thumbnail } => {
                SeriesCoverSourceDto::CustomThumbnail { thumbnail }
            }
            CoreSeriesCover::FallbackComic { comic_id } => {
                SeriesCoverSourceDto::FallbackComic { comic_id }
            }
            CoreSeriesCover::Missing => SeriesCoverSourceDto::Missing,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ThumbnailPriorityDto {
    Critical,
    High,
    Low,
}

#[derive(Debug, Clone)]
pub enum ThumbnailEventDto {
    Ready { comic_id: String },
    Progress {
        done: i32,
        total: i32,
        failed: i32,
    },
}

fn map_priority(priority: ThumbnailPriorityDto) -> CorePriority {
    match priority {
        ThumbnailPriorityDto::Critical => CorePriority::Critical,
        ThumbnailPriorityDto::High => CorePriority::High,
        ThumbnailPriorityDto::Low => CorePriority::Low,
    }
}

fn map_event(event: CoreEvent) -> ThumbnailEventDto {
    match event {
        CoreEvent::Ready { comic_id } => ThumbnailEventDto::Ready { comic_id },
        CoreEvent::Progress { done, total, failed } => ThumbnailEventDto::Progress {
            done,
            total,
            failed,
        },
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn find_thumbnail_by_comic_id_frb(
    comic_id: String,
) -> Result<Option<ComicThumbnailDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(find_thumbnail_by_comic_id(&comic_id))
        .map(|opt| opt.map(ComicThumbnailDto::from))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn ensure_thumbnail_by_comic_id_frb(
    comic_id: String,
    priority: ThumbnailPriorityDto,
) -> Result<Option<ComicThumbnailDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(ensure_thumbnail(
        &comic_id,
        map_priority(priority),
    ))
    .map(|opt| opt.map(ComicThumbnailDto::from))
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_thumbnails_by_comic_ids_frb(comic_ids: Vec<String>) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(delete_thumbnails_by_comic_ids(comic_ids))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_comic_thumbnail_from_page_frb(
    comic_id: String,
    path: String,
    resource_type: String,
    page_index: i32,
) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(set_comic_thumbnail_from_page(
        &comic_id,
        &path,
        &resource_type,
        page_index,
    ))
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_series_thumbnail_from_page_frb(
    series_id: String,
    comic_id: String,
    path: String,
    resource_type: String,
    page_index: i32,
) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(set_series_thumbnail_from_page(
        &series_id,
        &comic_id,
        &path,
        &resource_type,
        page_index,
    ))
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn find_series_thumbnail_by_series_id_frb(
    series_id: String,
) -> Result<Option<SeriesThumbnailDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(find_series_thumbnail_by_series_id(&series_id))
        .map(|opt| opt.map(SeriesThumbnailDto::from))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn resolve_series_cover_frb(
    series_id: String,
) -> Result<SeriesCoverSourceDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(resolve_series_cover(&series_id))
        .map(SeriesCoverSourceDto::from)
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn watch_thumbnail_events_frb(
    sink: crate::frb_generated::StreamSink<ThumbnailEventDto>,
) -> Result<(), HentaiErrorDto> {
    normalize_watch_result(
        watch_thumbnail_events(|event| emit_or_closed(&sink, map_event(event))).await,
    )
}
