//! Source metadata projection and automatic Local Resource writeback.

mod comic_info;
mod epub;
mod executor;
mod local;
mod pdf;
mod protocol;
mod query;
mod store;
mod xml;

pub use comic_info::{read_comic_info, update_comic_info};
pub use epub::container_package_path;
pub use epub::read_opf;
pub use executor::process_next;
pub use local::read_sevenz_metadata;
pub use pdf::read_pdf_metadata;
pub use protocol::{MetadataSnapshot, MetadataWriteIntent, EXTENSION_NAMESPACE, EXTENSION_VERSION};
pub use query::{query_media_overview, MediaOverview};
pub(crate) use store::reschedule_in;
pub(crate) use store::{capture_affected_in, record_affected_in};
pub(crate) use store::{capture_before_in, record_change_in};
pub use store::{is_enabled, set_enabled, status_for_comic, WritebackStatus};
