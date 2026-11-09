use hentai_core::{
    watch_reading_activity_stats as core_watch_reading_activity_stats,
    ReadingActivityStatsDto as CoreReadingActivityStats,
};

use super::init::HentaiErrorDto;
use super::stream_watch::{emit_or_closed, normalize_watch_result};

#[derive(Debug, Clone)]
pub struct ReadingActivityStatsDto {
    pub finished_count: i32,
    pub total_duration_ms: i64,
}

impl From<CoreReadingActivityStats> for ReadingActivityStatsDto {
    fn from(v: CoreReadingActivityStats) -> Self {
        Self {
            finished_count: v.finished_count,
            total_duration_ms: v.total_duration_ms,
        }
    }
}

#[flutter_rust_bridge::frb]
pub async fn watch_reading_activity_stats_frb(
    sink: crate::frb_generated::StreamSink<ReadingActivityStatsDto>,
) -> Result<(), HentaiErrorDto> {
    normalize_watch_result(
        core_watch_reading_activity_stats(|stats| {
            emit_or_closed(&sink, ReadingActivityStatsDto::from(stats))
        })
        .await,
    )
}
