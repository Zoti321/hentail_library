use hentai_core::{
    delete_thumbnails_by_comic_ids, ensure_thumbnail, find_thumbnail_by_comic_id,
    watch_thumbnail_events, ComicThumbnailDto as CoreThumb, ThumbnailEvent as CoreEvent,
    ThumbnailPriority as CorePriority,
};

use super::init::HentaiErrorDto;
use super::stream_watch::{emit_or_closed, normalize_watch_result};

#[derive(Debug, Clone)]
pub struct ComicThumbnailDto {
    pub thumbnail: Vec<u8>,
    pub source_modified_ms: i64,
    pub source_size: i64,
}

impl From<CoreThumb> for ComicThumbnailDto {
    fn from(v: CoreThumb) -> Self {
        Self {
            thumbnail: v.thumbnail,
            source_modified_ms: v.source_modified_ms,
            source_size: v.source_size,
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

#[flutter_rust_bridge::frb]
pub async fn watch_thumbnail_events_frb(
    sink: crate::frb_generated::StreamSink<ThumbnailEventDto>,
) -> Result<(), HentaiErrorDto> {
    normalize_watch_result(
        watch_thumbnail_events(|event| emit_or_closed(&sink, map_event(event))).await,
    )
}
