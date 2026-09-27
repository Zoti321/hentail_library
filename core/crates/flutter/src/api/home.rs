use hentai_core::{
    watch_continue_reading_top5 as core_watch_top5,
    watch_home_library_alerts as core_watch_alerts,
    watch_home_page_counts as core_watch_counts,
    watch_recently_added_on_home as core_watch_recently_added, HomeContinueReadingDto as CoreContinue,
    HomeLibraryAlertDto as CoreAlert, HomeLibraryAlertKindDto as CoreAlertKind,
    HomePageCountsDto as CoreCounts, HomeRecentlyAddedDto as CoreRecentlyAdded,
};

use super::init::HentaiErrorDto;
use super::stream_watch::{emit_or_closed, normalize_watch_result};

#[derive(Debug, Clone)]
pub struct HomePageCountsDto {
    pub comic_count: i32,
    pub tag_count: i32,
    pub series_count: i32,
    pub author_count: i32,
    pub library_count: i32,
}

#[derive(Debug, Clone)]
pub struct HomeContinueReadingDto {
    pub comic_id: String,
    pub title: String,
    pub last_read_time_ms: i64,
    pub page_index: Option<i32>,
}

#[derive(Debug, Clone)]
pub enum HomeLibraryAlertKindDto {
    RemoteUnreachable,
    SyncFailed,
    StaleSync,
    PendingResourcesDetected,
}

#[derive(Debug, Clone)]
pub struct HomeLibraryAlertDto {
    pub library_id: String,
    pub display_name: String,
    pub kind: HomeLibraryAlertKindDto,
    pub last_success_at_ms: Option<i64>,
    pub last_error_message: Option<String>,
    pub stale_days: Option<i32>,
    pub pending_resource_count: Option<i32>,
}

#[derive(Debug, Clone)]
pub struct HomeRecentlyAddedDto {
    pub comic_id: String,
    pub title: String,
    pub library_id: String,
    pub library_display_name: String,
    pub created_at_ms: i64,
}

impl From<CoreCounts> for HomePageCountsDto {
    fn from(v: CoreCounts) -> Self {
        Self {
            comic_count: v.comic_count,
            tag_count: v.tag_count,
            series_count: v.series_count,
            author_count: v.author_count,
            library_count: v.library_count,
        }
    }
}

impl From<CoreContinue> for HomeContinueReadingDto {
    fn from(v: CoreContinue) -> Self {
        Self {
            comic_id: v.comic_id,
            title: v.title,
            last_read_time_ms: v.last_read_time_ms,
            page_index: v.page_index,
        }
    }
}

impl From<CoreAlertKind> for HomeLibraryAlertKindDto {
    fn from(v: CoreAlertKind) -> Self {
        match v {
            CoreAlertKind::RemoteUnreachable => Self::RemoteUnreachable,
            CoreAlertKind::SyncFailed => Self::SyncFailed,
            CoreAlertKind::StaleSync => Self::StaleSync,
        }
    }
}

impl From<CoreAlert> for HomeLibraryAlertDto {
    fn from(v: CoreAlert) -> Self {
        Self {
            library_id: v.library_id,
            display_name: v.display_name,
            kind: v.kind.into(),
            last_success_at_ms: v.last_success_at_ms,
            last_error_message: v.last_error_message,
            stale_days: v.stale_days,
            pending_resource_count: None,
        }
    }
}

impl From<CoreRecentlyAdded> for HomeRecentlyAddedDto {
    fn from(v: CoreRecentlyAdded) -> Self {
        Self {
            comic_id: v.comic_id,
            title: v.title,
            library_id: v.library_id,
            library_display_name: v.library_display_name,
            created_at_ms: v.created_at_ms,
        }
    }
}

#[flutter_rust_bridge::frb]
pub async fn watch_home_page_counts_frb(
    exclude_r18: bool,
    sink: crate::frb_generated::StreamSink<HomePageCountsDto>,
) -> Result<(), HentaiErrorDto> {
    normalize_watch_result(
        core_watch_counts(exclude_r18, |counts| {
            emit_or_closed(&sink, HomePageCountsDto::from(counts))
        })
        .await,
    )
}

#[flutter_rust_bridge::frb]
pub async fn watch_continue_reading_top5_frb(
    exclude_r18: bool,
    sink: crate::frb_generated::StreamSink<Vec<HomeContinueReadingDto>>,
) -> Result<(), HentaiErrorDto> {
    normalize_watch_result(
        core_watch_top5(exclude_r18, |rows| {
            let mapped = rows.into_iter().map(HomeContinueReadingDto::from).collect();
            emit_or_closed(&sink, mapped)
        })
        .await,
    )
}

#[flutter_rust_bridge::frb]
pub async fn watch_home_library_alerts_frb(
    sink: crate::frb_generated::StreamSink<Vec<HomeLibraryAlertDto>>,
) -> Result<(), HentaiErrorDto> {
    normalize_watch_result(
        core_watch_alerts(|rows| {
            let mapped = rows.into_iter().map(HomeLibraryAlertDto::from).collect();
            emit_or_closed(&sink, mapped)
        })
        .await,
    )
}

#[flutter_rust_bridge::frb]
pub async fn watch_recently_added_on_home_frb(
    exclude_r18: bool,
    sink: crate::frb_generated::StreamSink<Vec<HomeRecentlyAddedDto>>,
) -> Result<(), HentaiErrorDto> {
    normalize_watch_result(
        core_watch_recently_added(exclude_r18, |rows| {
            let mapped = rows
                .into_iter()
                .map(HomeRecentlyAddedDto::from)
                .collect();
            emit_or_closed(&sink, mapped)
        })
        .await,
    )
}
