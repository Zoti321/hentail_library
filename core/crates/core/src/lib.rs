pub mod author;
pub mod history;
pub mod home;
pub mod comic;
pub mod comic_id;
pub mod db;
pub mod entity;
pub mod error;
pub mod formats;
pub mod migration;
pub mod path;
pub mod reader;
pub mod runtime;
pub mod series;
pub mod series_id;
pub mod sync;
pub mod tag;
pub mod thumbnail;
pub mod util;

pub use author::{
    add_author, count_all_authors, delete_authors_by_names, fetch_authors_page, list_all_authors,
    rename_author, watch_authors,
};
pub use comic::{
    ComicDto, ComicFilterDto, ComicSortOptionDto, PageRequestDto, PagedComicResultDto,
    count_all, delete_comics_by_ids, fetch_comics_page, find_comic_by_id, read_data_version,
    search_by_keyword, search_by_tag_expression, update_comic_user_meta, UpdateComicUserMetaDto,
};
pub use comic_id::{comic_id_from_normalized_path, comic_id_from_path, normalize_path_for_key};
pub use db::{connection, db_config, init_db, init_db_at_path};
pub use error::{HentaiError, HentaiErrorCode};
pub use path::{add_path, list_all_paths, remove_path, watch_paths};
pub use sync::{
    LibrarySyncCountsDto, SyncHandle, SyncLibraryPhaseDto, SyncLibraryProgressDto,
    SyncLibraryRouteDto, cancel_sync, create_sync_handle, sync_library,
};
pub use reader::{
    ReaderPageDto, ReaderPageListDto, clear_reader_page_cache, clear_reader_sessions,
    close_reader, load_page_bytes, load_page_list, load_reader_page, open_reader,
    prefetch_reader_pages,
};
pub use series_id::{
    folder_path_from_comic_path, series_id_from_folder_path, series_name_from_folder_path,
};
pub use series::{
    count_all_series, fetch_series_page, find_series_by_id, get_all_series,
    load_home_series_comic_order_map, search_series_by_keyword, search_series_by_tag_expression,
    set_series_items_order, update_series_user_meta, watch_all_series,
    watch_home_series_comic_order_map, PagedSeriesResultDto, SeriesDto, SeriesFilterDto,
    SeriesItemDto, SeriesSortOptionDto, UpdateSeriesUserMetaDto,
};
pub use history::{
    PagedReadingHistoryDto, ReadingHistoryDto, SeriesReadingHistoryDto, clear_all_reading,
    delete_reading_by_comic_id, delete_reading_by_comic_ids, delete_series_reading_by_series_id,
    fetch_reading_page, get_reading_by_comic_id, get_series_reading_by_series_id, list_all_reading,
    record_reading, record_series_reading, watch_reading_histories,
};
pub use home::{
    get_continue_reading_top5, get_home_page_counts, watch_continue_reading_top5,
    watch_home_page_counts, HomeContinueReadingDto, HomePageCountsDto,
};
pub use tag::{
    add_tag, count_all_tags, delete_tags_by_names, fetch_tags_page, list_all_tags, rename_tag,
    watch_tags,
};
pub use thumbnail::{
    delete_thumbnails_by_comic_ids, ensure_thumbnail, enqueue_thumbnails_low,
    find_thumbnail_by_comic_id, watch_thumbnail_events, ComicThumbnailDto, ThumbnailEvent,
    ThumbnailPriority,
};
