//! Image set catalog for Image set libraries: discovery, persistence and manual sync (#584).
//!
//! Sync is reached from [crate::sync::sync_library] via `is_image_set_catalog`; it never
//! writes Comic or Series records.

mod archive_list;
mod catalog;
mod discovery;
mod dto;
mod ids;
mod meta;
mod orchestrator;
mod plan;
mod writer;

pub use catalog::{list_image_set_images, list_image_sets};
pub use dto::{ImageSetDto, ImageSetImageDto};
pub use meta::{
    set_image_set_meta_locks, update_image_set_user_meta, SetImageSetMetaLocksDto,
    UpdateImageSetUserMetaDto,
};
pub(crate) use orchestrator::sync_image_set_library;
