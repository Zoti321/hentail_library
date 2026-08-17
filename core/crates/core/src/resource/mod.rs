//! Resource discovery & parse — Resource → [ParsedResource].
//!
//! I/O goes through [access] (Local FS today; Fake for tests; WebDAV later).
//! Library sync / Metadata refresh consume parse. formats / reader /
//! thumbnail use [media] helpers and [access] (no dependency on sync).

pub mod access;
mod media;
mod parse;
mod stat;

pub use access::{
    local_access, FakeResourceAccess, LocalResourceAccess, ResourceAccess, ResourceEntry,
    ResourceKind, ResourceStat, ResourceStream, WebDavResourceAccess,
};
pub use media::{
    basename, basename_without_extension, can_generate_thumbnail, extension_lower,
    is_comic_image_extension,
};
pub use parse::{
    comic_id_for_path, normalize_roots, parse_directory, parse_directory_with, parse_epub,
    parse_epub_with, parse_file, parse_file_with, parse_pdf, parse_rar_archive,
    parse_sevenz_archive, parse_zip_archive, parse_zip_archive_with, parsed_to_comic,
    ParsedResource,
};
pub use stat::{
    read_resource_size, read_resource_size_with, read_source_stat, read_source_stat_with,
};
