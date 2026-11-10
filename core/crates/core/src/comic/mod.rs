pub mod bulk_patch;
mod dto;
mod filter_predicate;
mod grouping;
mod page_query;
pub mod pagination;
pub mod repository;
mod trash;
pub(crate) mod visibility;
pub mod write;

pub use bulk_patch::{
    apply_comic_metadata_bulk_patch, BulkPatchResultDto, ComicMetadataBulkPatch, MultiValueOp,
    MultiValuePatch, PublishedAtPatch, ScalarPatch, BULK_PATCH_MAX_IDS,
};
pub use dto::{
    author_refs_from_names, now_ms, parse_languages_json, serialize_languages, ComicAuthorDto,
    ComicBrowseItemDto, ComicDto, ComicFilterDto, ComicMetaLocks, ComicSortFieldDto,
    ComicSortOptionDto, PageRequestDto, PagedComicBrowseResultDto, PagedComicResultDto,
};
pub use grouping::ComicGrouping;
pub use pagination::{paginate, PageWindow};
pub use repository::{
    count_all, fetch_comics_browse_page, fetch_comics_page, find_comic_by_id, find_comics_by_ids,
    load_comics_ordered, search_by_keyword, search_by_keyword_page, search_by_tag_expression,
    search_by_tag_expression_page, search_comic_ids_by_tag_expression,
};
pub use trash::{
    count_trashed_comics, fetch_trashed_comics_page, is_comic_trashed, list_trashed_comic_ids,
    purge_comics, restore_comics, trash_comics, ComicPurgeResultDto, PagedTrashedComicResultDto,
    TrashedComicCountsDto, TrashedComicDto,
};
pub use write::{
    set_comic_meta_locks, update_comic_user_meta, SetComicMetaLocksDto, UpdateComicUserMetaDto,
};
