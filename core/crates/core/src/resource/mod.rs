//! Resource discovery & parse — disk Resource → [ParsedResource].
//!
//! Library sync / Metadata refresh consume this module. formats / reader /
//! thumbnail use [media] helpers only (no dependency on sync).

mod media;
mod parse;
mod stat;

pub use media::{
    basename, basename_without_extension, can_generate_thumbnail, extension_lower,
    is_comic_image_extension,
};
pub use parse::{
    comic_id_for_path, normalize_roots, parse_directory, parse_epub, parse_file, parse_pdf,
    parse_rar_archive, parse_sevenz_archive, parse_zip_archive, parsed_to_comic, ParsedResource,
};
pub use stat::{read_resource_size, read_source_stat};
