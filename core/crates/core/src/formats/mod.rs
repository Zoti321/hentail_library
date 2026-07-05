mod pdf;
mod rar;
mod sevenz;

pub use pdf::{count_pdf_pages, open_pdf_backend, read_pdf_embedded_meta, read_pdf_page, PdfBackend};
pub use rar::{count_rar_images, open_rar_backend, read_rar_cover_bytes, read_rar_page, RarBackend};
pub use sevenz::{count_sevenz_images, open_sevenz_backend, read_sevenz_page, SevenZBackend};

use std::path::Path;

use crate::error::HentaiError;
use crate::sync::parser::{basename, is_comic_image_extension};
use crate::util::natural_sort::compare_filename_natural;

pub(crate) fn is_comic_image_name(name: &str) -> bool {
    let normalized = name.replace('\\', "/");
    let file_name = basename(Path::new(&normalized));
    if file_name.is_empty() {
        return false;
    }
    let ext = Path::new(&file_name)
        .extension()
        .and_then(|e| e.to_str())
        .map(|e| format!(".{}", e.to_lowercase()))
        .unwrap_or_default();
    is_comic_image_extension(&ext)
}

pub(crate) fn sort_archive_entry_names(mut names: Vec<String>) -> Vec<String> {
    names.sort_by(|a, b| {
        compare_filename_natural(
            &basename(Path::new(a)),
            &basename(Path::new(b)),
        )
    });
    names
}

pub(crate) fn map_archive_err(context: &str, err: impl std::fmt::Display) -> HentaiError {
    HentaiError::validation(format!("{context}: {err}"))
}

pub(crate) fn map_reader_err(context: &str, err: impl std::fmt::Display) -> HentaiError {
    HentaiError::reader_invalid_content(format!("{context}: {err}"))
}
