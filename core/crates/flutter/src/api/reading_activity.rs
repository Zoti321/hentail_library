use hentai_core::{
    backfill_finished_comics_from_history as core_backfill_finished_comics_from_history,
    record_reading_activity as core_record_reading_activity,
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

#[flutter_rust_bridge::frb]
pub async fn record_reading_activity_frb(
    comic_id: String,
    add_duration_ms: Option<i64>,
    mark_finished: bool,
) -> Result<(), HentaiErrorDto> {
    core_record_reading_activity(&comic_id, add_duration_ms, mark_finished)
        .await
        .map_err(HentaiErrorDto::from)
}

/// 从 Reading history 幂等回填 Finished comic；不发明时长。返回候选写入行数。
#[flutter_rust_bridge::frb]
pub async fn backfill_finished_comics_from_history_frb() -> Result<i32, HentaiErrorDto> {
    core_backfill_finished_comics_from_history()
        .await
        .map_err(HentaiErrorDto::from)
}
