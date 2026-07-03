pub mod history;
pub mod home;
pub mod comic;
pub mod comic_id;
pub mod db;
pub mod entity;
pub mod error;
pub mod formats;
pub mod migration;
pub mod reader;
pub mod runtime;
pub mod series;
pub mod sync;
pub mod util;

pub use comic::{
    ComicDto, ComicFilterDto, ComicSortOptionDto, PageRequestDto, PagedComicResultDto,
    count_all, fetch_comics_page, find_comic_by_id, read_data_version, search_by_keyword,
};
pub use comic_id::{comic_id_from_normalized_path, comic_id_from_path, normalize_path_for_key};
pub use db::{connection, db_config, init_db, init_db_at_path};
pub use error::{HentaiError, HentaiErrorCode};
pub use sync::{
    LibrarySyncCountsDto, SyncHandle, SyncLibraryPhaseDto, SyncLibraryProgressDto,
    SyncLibraryRouteDto, cancel_sync, create_sync_handle, sync_library,
};
pub use reader::{
    ReaderPageListDto, clear_reader_sessions, close_reader, load_page_bytes, load_page_list,
    open_reader,
};
pub use series::{infer_series, InferSeriesResultDto};
pub use history::{
    PagedReadingHistoryDto, PagedSeriesReadingHistoryDto, ReadingHistoryDto,
    SeriesReadingHistoryDto, clear_all_reading, delete_reading_by_comic_id,
    delete_reading_by_comic_ids, delete_series_reading_by_last_read_comic_ids,
    delete_series_reading_by_name, fetch_reading_page, fetch_series_reading_page,
    get_reading_by_comic_id, get_series_reading_by_name, list_all_reading,
    list_all_series_reading, record_reading, record_series_reading, watch_reading_histories,
    watch_series_reading_histories,
};
pub use home::{get_home_page_counts, watch_home_page_counts, HomePageCountsDto};
