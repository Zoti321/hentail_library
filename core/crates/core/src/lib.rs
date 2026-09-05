pub mod author;
pub mod character;
pub mod comic;
pub mod comic_id;
pub mod db;
pub mod entity;
pub mod error;
pub mod formats;
pub mod history;
pub mod home;
pub mod library;
pub mod metadata_lock;
pub mod migration;
pub mod named_facet;
pub mod path;
pub mod parody;
pub mod reader;
pub mod resource;
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
pub use character::{list_all_characters, list_distinct_characters};
pub use comic::{
    count_all, delete_comics_by_ids, fetch_comics_page, find_comic_by_id, read_data_version,
    search_by_keyword, search_by_keyword_page, search_by_tag_expression,
    search_by_tag_expression_page, set_comic_meta_locks, update_comic_user_meta,
    ComicDto, ComicFilterDto, ComicMetaLocks, ComicSortFieldDto, ComicSortOptionDto,
    PageRequestDto, PagedComicResultDto, SetComicMetaLocksDto, UpdateComicUserMetaDto,
};
pub use comic_id::{comic_id_from_normalized_path, comic_id_from_path, normalize_path_for_key};
pub use db::{connection, db_config, init_db, init_db_at_path};
pub use error::{HentaiError, HentaiErrorCode};
pub use history::{
    clear_all_reading, delete_reading_by_comic_id, delete_reading_by_comic_ids, fetch_reading_page,
    get_reading_by_comic_id, list_all_reading, record_reading, watch_reading_histories,
    PagedReadingHistoryDto, ReadingHistoryDto,
};
pub use home::{
    get_continue_reading_top5, get_home_page_counts, watch_continue_reading_top5,
    watch_home_page_counts, HomeContinueReadingDto, HomePageCountsDto,
};
pub use library::{
    clear_remote_library_credentials, create_local_library, create_remote_library, delete_library,
    get_current_library_id, library_id_from_root, library_id_from_webdav_root, list_libraries,
    normalize_webdav_root, parse_format_groups_json, parse_scan_interval, resolve_access_for_comic,
    resolve_browse_library_id, serialize_format_groups, set_all_libraries_scan_on_startup,
    set_current_library_id, set_remote_library_credentials, update_library_format_groups,
    update_library_settings, update_library_sidebar_layout, update_local_library_root,
    update_remote_library, LibraryDto, LibrarySidebarPlacement, RemoteLibraryCredential,
    ResolvedAccess, ScanInterval,
};
pub use named_facet::{
    list_all_named_facet_names, list_distinct_named_facet_names, list_named_facet_for_form,
    replace_comic_named_facet, JunctionNamedFacet, NamedFacetFormEntry,
};
pub use path::{add_path, list_all_paths, remove_path, watch_paths};
pub use parody::{list_all_parodies, list_distinct_parodies};
pub use reader::{
    clear_reader_page_cache, clear_reader_sessions, close_reader, load_page_bytes, load_page_list,
    load_reader_page, open_reader, open_reader_with, prefetch_reader_pages, writeback_after_open,
    writeback_with_access, ReaderPageDto, ReaderPageListDto,
};
pub use series::{
    count_all_series, fetch_series_comics_metadata, fetch_series_comics_page, fetch_series_page,
    find_series_by_id, get_all_series, get_series_reading_context_by_comic_id,
    load_home_series_comic_order_map, search_series_by_keyword, search_series_by_tag_expression,
    set_series_item_sort_order_locked, set_series_items_order, set_series_meta_locks,
    update_series_item_sort_order, update_series_user_meta, watch_all_series,
    watch_home_series_comic_order_map, PagedSeriesComicsResultDto, PagedSeriesResultDto,
    SeriesComicPageItemDto, SeriesComicsMetadataDto, SeriesDto, SeriesFilterDto, SeriesItemDto,
    SeriesMetaLocks, SeriesReadingContextDto, SeriesSortFieldDto, SeriesSortOptionDto,
    SetSeriesMetaLocksDto, UpdateSeriesUserMetaDto,
};
pub use series_id::{
    folder_path_from_comic_path, series_id_from_folder_path, series_name_from_folder_path,
};
pub use sync::{
    cancel_sync, comic_id_for_remote_location, create_sync_handle, refresh_comic_metadata,
    refresh_library_metadata, refresh_series_metadata, scan_remote_lightweight, sync_library,
    try_acquire_library_write_lock, FormatGroup, LibrarySyncCountsDto, RefreshLibraryResultDto,
    RefreshSeriesProgressDto, RefreshSeriesResultDto, RemoteScanOutcome, SyncHandle,
    SyncLibraryPhaseDto, SyncLibraryProgressDto, SyncLibraryRouteDto, SyncScanMode,
};
pub use tag::{
    add_tag, count_all_tags, delete_tags_by_names, fetch_tags_page, import_tag_dictionary,
    list_all_tags, rename_tag, watch_tags, TagDictionaryImportResult,
};
pub use thumbnail::{
    delete_thumbnails_by_comic_ids, enqueue_thumbnails_low, ensure_thumbnail,
    find_series_thumbnail_by_series_id, find_thumbnail_by_comic_id, resolve_series_cover,
    set_comic_thumbnail_from_page, set_series_thumbnail_from_page, watch_thumbnail_events,
    ComicThumbnailDto, SeriesCoverSource, SeriesThumbnailDto, ThumbnailEvent, ThumbnailPriority,
};
