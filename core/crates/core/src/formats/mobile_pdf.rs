use std::path::Path;

use crate::error::HentaiError;

pub struct PdfBackend {
    pub path: String,
    pub page_count: i32,
}

fn unsupported() -> HentaiError {
    HentaiError::validation("当前平台不支持 PDF 格式")
}

pub fn count_pdf_pages(_file: &Path) -> Result<Option<i32>, HentaiError> {
    Ok(None)
}

pub fn read_pdf_embedded_meta(_file: &Path) -> Result<(Option<String>, Option<i64>), HentaiError> {
    Ok((None, None))
}

pub fn open_pdf_backend(_file: &Path) -> Result<PdfBackend, HentaiError> {
    Err(unsupported())
}

pub fn read_pdf_page(_backend: &PdfBackend, _page_index: usize) -> Result<Vec<u8>, HentaiError> {
    Err(unsupported())
}
