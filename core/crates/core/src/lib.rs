pub mod comic;
pub mod comic_id;
pub mod db;
pub mod entity;
pub mod error;
pub mod migration;
pub mod runtime;
pub mod sync;

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
