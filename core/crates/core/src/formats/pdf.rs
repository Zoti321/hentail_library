use std::path::Path;

use image::codecs::jpeg::JpegEncoder;
use pdfium_render::prelude::*;

use crate::error::HentaiError;

use super::map_archive_err;

pub struct PdfBackend {
    pub path: String,
    pub page_count: i32,
}

fn bind_pdfium() -> Result<Pdfium, HentaiError> {
    let lib_dir = env!("HENTAI_PDFIUM_LIB_DIR");
    let lib_path = Pdfium::pdfium_platform_library_name_at_path(lib_dir);
    let bindings = Pdfium::bind_to_library(lib_path)
        .map_err(|e| map_archive_err("pdfium 绑定失败", e))?;
    Ok(Pdfium::new(bindings))
}

pub fn count_pdf_pages(file: &Path) -> Result<Option<i32>, HentaiError> {
    let pdfium = bind_pdfium()?;
    let document = pdfium
        .load_pdf_from_file(file, None)
        .map_err(|e| map_archive_err("pdf 打开失败", e))?;
    let count = document.pages().len();
    if count == 0 {
        return Ok(None);
    }
    Ok(Some(count as i32))
}

pub fn open_pdf_backend(file: &Path) -> Result<PdfBackend, HentaiError> {
    let page_count = count_pdf_pages(file)?.unwrap_or(0);
    if page_count == 0 {
        return Err(HentaiError::reader_invalid_content(format!(
            "PDF 无页面: {}",
            file.display()
        )));
    }
    Ok(PdfBackend {
        path: file.to_string_lossy().to_string(),
        page_count,
    })
}

pub fn read_pdf_page(backend: &PdfBackend, page_index: usize) -> Result<Vec<u8>, HentaiError> {
    if page_index >= backend.page_count as usize {
        return Err(HentaiError::reader_invalid_content(format!(
            "页索引越界: index={page_index} count={}",
            backend.page_count
        )));
    }
    let pdfium = bind_pdfium()?;
    let document = pdfium
        .load_pdf_from_file(&backend.path, None)
        .map_err(|e| HentaiError::reader_invalid_content(format!("pdf 打开失败: {e}")))?;
    let page = document
        .pages()
        .get(page_index as u16)
        .map_err(|e| HentaiError::reader_invalid_content(format!("pdf 页读取失败: {e}")))?;
    let render_config = PdfRenderConfig::new()
        .set_target_width(1600)
        .rotate_if_landscape(PdfPageRenderRotation::None, true);
    let bitmap = page
        .render_with_config(&render_config)
        .map_err(|e| HentaiError::reader_invalid_content(format!("pdf 渲染失败: {e}")))?;
    let image = bitmap.as_image();
    let mut buffer = Vec::new();
    let mut encoder = JpegEncoder::new_with_quality(&mut buffer, 90);
    encoder
        .encode_image(&image)
        .map_err(|e| HentaiError::reader_invalid_content(format!("pdf 编码 JPEG 失败: {e}")))?;
    Ok(buffer)
}
