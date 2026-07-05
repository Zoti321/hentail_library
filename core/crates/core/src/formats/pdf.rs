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

pub fn read_pdf_embedded_meta(file: &Path) -> Result<(Option<String>, Option<i64>), HentaiError> {
    let pdfium = bind_pdfium()?;
    let document = pdfium
        .load_pdf_from_file(file, None)
        .map_err(|e| map_archive_err("pdf 打开失败", e))?;
    let metadata = document.metadata();
    let description = metadata
        .get(PdfDocumentMetadataTagType::Subject)
        .map(metadata_tag_text)
        .filter(|s| !s.is_empty());
    let published_at = metadata
        .get(PdfDocumentMetadataTagType::CreationDate)
        .map(|tag| metadata_tag_text(tag))
        .and_then(|raw| parse_pdf_date_to_ms(&raw));
    Ok((description, published_at))
}

fn metadata_tag_text(tag: PdfDocumentMetadataTag) -> String {
    tag.value().trim().to_string()
}

fn parse_pdf_date_to_ms(raw: &str) -> Option<i64> {
    let trimmed = raw.trim().trim_start_matches("D:");
    if trimmed.len() < 8 {
        return None;
    }
    let digits: String = trimmed.chars().take(14).filter(|c| c.is_ascii_digit()).collect();
    if digits.len() < 8 {
        return None;
    }
    let year: i32 = digits[0..4].parse().ok()?;
    let month: u32 = digits[4..6].parse().ok()?;
    let day: u32 = digits[6..8].parse().ok()?;
    let hour = digits.get(8..10).and_then(|s| s.parse().ok()).unwrap_or(0);
    let minute = digits.get(10..12).and_then(|s| s.parse().ok()).unwrap_or(0);
    let second = digits.get(12..14).and_then(|s| s.parse().ok()).unwrap_or(0);
    date_to_utc_ms(year, month, day, hour, minute, second)
}

fn date_to_utc_ms(
    year: i32,
    month: u32,
    day: u32,
    hour: u32,
    minute: u32,
    second: u32,
) -> Option<i64> {
    use std::time::{Duration, SystemTime, UNIX_EPOCH};
    let days_from_ce = days_from_civil(year, month, day)?;
    let secs = days_from_ce as i64 * 86_400
        + hour as i64 * 3600
        + minute as i64 * 60
        + second as i64;
    SystemTime::    UNIX_EPOCH
        .checked_add(Duration::from_secs(secs.max(0) as u64))
        .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
        .map(|d| d.as_millis() as i64)
}

/// Algorithm from http://howardhinnant.github.io/date_algorithms.html
fn days_from_civil(year: i32, month: u32, day: u32) -> Option<u32> {
    if !(1..=12).contains(&month) || !(1..=31).contains(&day) {
        return None;
    }
    let y = if month <= 2 { year - 1 } else { year } as u32;
    let era = y / 400;
    let yoe = y - era * 400;
    let doy = (153 * (if month > 2 { month - 3 } else { month + 9 }) + 2) / 5 + day - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    Some(era * 146097 + doe - 719468)
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
