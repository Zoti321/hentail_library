mod dto;
mod repository;
mod retention;

pub use dto::{PagedReadingHistoryDto, ReadPageIndexDto, ReadingHistoryDto};
pub use repository::{
    clear_all_reading, delete_reading_by_comic_id, delete_reading_by_comic_ids, fetch_reading_page,
    get_reading_by_comic_id, list_all_reading, list_read_page_indexes,
    normalize_reading_history_titles, purge_expired_reading_histories, record_reading,
    watch_reading_history_changes,
};
pub use retention::{
    reading_history_retention_cutoff_ms, reading_history_within_retention,
    READING_HISTORY_RETENTION_DAYS,
};
