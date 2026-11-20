//! Image set catalog for Image set libraries: discovery, persistence and manual sync (#584).
//!
//! Sync is reached from [`crate::sync::sync_library`] via `is_image_set_catalog`; it never
//! writes Comic or Series records.

mod archive_list;
mod catalog;
mod cover;
mod dimensions;
mod discovery;
mod dto;
mod gates;
mod ids;
mod meta;
mod orchestrator;
mod plan;
mod query;
mod managed_layout;
mod mutation;
mod submissions;
mod workspace;
mod writer;

pub use catalog::{list_image_set_images, list_image_set_workspace_images, list_image_sets};
pub use cover::{
    enqueue_image_set_covers_low, ensure_image_set_cover, find_image_set_cover,
    invalidate_image_set_cover, list_image_set_cover_targets, store_image_set_cover,
    watch_image_set_cover_events, ImageSetCoverDto, ImageSetCoverEvent,
};
pub use dto::{
    ImageSetAuthorGroupDto, ImageSetCarrierShapeDto, ImageSetCatalogItemDto, ImageSetDto,
    ImageSetFacetFilterDto, ImageSetFilterDto, ImageSetGroupingDto, ImageSetImageDto,
    ImageSetSortFieldDto, ImageSetSortOptionDto, PagedImageSetCatalogDto,
};
pub use gates::{
    get_image_set_library_gates, set_image_set_managed_layout, set_image_set_resource_mutation,
    ImageSetLibraryGatesDto,
};
pub use meta::{
    get_image_set_facets, set_image_set_meta_locks, update_image_set_facets,
    update_image_set_user_meta, ImageSetFacetsDto, SetImageSetMetaLocksDto,
    UpdateImageSetFacetsDto, UpdateImageSetUserMetaDto,
};
pub use managed_layout::take_over_image_set_managed_layout;
pub use mutation::{copy_images_into_image_set, delete_image_set_images_on_disk};
pub(crate) use orchestrator::sync_image_set_library;
pub use query::fetch_image_sets_page;
pub use submissions::{
    add_image_set_submission_members, create_image_set_submission, delete_image_set_submission,
    list_image_set_submissions, remove_image_set_submission_members, rename_image_set_submission,
    reorder_image_set_submission_members, ImageSetSubmissionDto,
};
pub use workspace::{reorder_image_set_images, set_image_set_images_excluded};
