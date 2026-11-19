use std::path::Path;

use image::codecs::jpeg::JpegEncoder;
use pdfium_render::prelude::*;

use crate::error::HentaiError;

use super::map_archive_err;

pub struct PdfBackend {
    pub path: String,
    pub page_count: i32,
    /// Keeps a temp file alive when the PDF was materialized from Remote access.
    pub(crate) remote_temp: Option<tempfile::NamedTempFile>,
}

fn bind_pdfium() -> Result<Pdfium, HentaiError> {
    #[cfg(miri)]
    {
        return Err(HentaiError::validation("pdfium unavailable under miri"));
    }
    #[cfg(not(miri))]
    {
        #[cfg(target_os = "android")]
        {
            // Packaged next to libhentai_flutter.so in jniLibs (also NEEDED).
            // Do not fall back to system libpdfium — it is older / inaccessible on many APIs.
            let bindings = Pdfium::bind_to_library("libpdfium.so")
                .map_err(|e| map_archive_err("pdfium 绑定失败", e))?;
            return Ok(Pdfium::new(bindings));
        }
        #[cfg(target_os = "ios")]
        {
            return bind_pdfium_ios();
        }
        #[cfg(not(any(target_os = "android", target_os = "ios")))]
        {
            // build.rs sets this; option_env keeps `cargo miri` / skipped build scripts from
            // failing at compile time when the not(miri) arm is still type-checked.
            let lib_dir = option_env!("HENTAI_PDFIUM_LIB_DIR").ok_or_else(|| {
                HentaiError::validation("HENTAI_PDFIUM_LIB_DIR unset (run core/vendor/fetch-native-deps.sh)")
            })?;
            let lib_path = Pdfium::pdfium_platform_library_name_at_path(lib_dir);
            let bindings = Pdfium::bind_to_library(lib_path)
                .map_err(|e| map_archive_err("pdfium 绑定失败", e))?;
            Ok(Pdfium::new(bindings))
        }
    }
}

/// iOS：libpdfium.dylib 由 `embed_pdfium.sh` 复制到 App bundle 的 `Frameworks/`
/// （见 `app/ios/Podfile`）。dlopen 无法可靠地
/// 按 leaf 名解析 @rpath，故优先按可执行文件旁的 bundle 路径绑定，最后回退 leaf 名
/// （若已随 Runner 链接，dyld 会命中已加载镜像）。
#[cfg(target_os = "ios")]
fn bind_pdfium_ios() -> Result<Pdfium, HentaiError> {
    use std::path::PathBuf;

    let mut candidates: Vec<PathBuf> = Vec::new();
    if let Ok(exe) = std::env::current_exe() {
        if let Some(dir) = exe.parent() {
            candidates.push(dir.join("Frameworks/libpdfium.dylib"));
            candidates.push(dir.join("libpdfium.dylib"));
        }
    }

    let mut last_err: Option<PdfiumError> = None;
    for path in &candidates {
        match Pdfium::bind_to_library(path) {
            Ok(bindings) => return Ok(Pdfium::new(bindings)),
            Err(e) => last_err = Some(e),
        }
    }

    // Fallback: leaf name resolved by dyld among already-loaded images.
    match Pdfium::bind_to_library("libpdfium.dylib") {
        Ok(bindings) => Ok(Pdfium::new(bindings)),
        Err(e) => Err(map_archive_err("pdfium 绑定失败", last_err.unwrap_or(e))),
    }
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
    Ok(Some(i32::from(count)))
}

type PdfEmbeddedMeta = (Option<String>, Vec<String>, Option<String>, Option<i64>);

pub fn read_pdf_embedded_meta(file: &Path) -> Result<PdfEmbeddedMeta, HentaiError> {
    let pdfium = bind_pdfium()?;
    let document = pdfium
        .load_pdf_from_file(file, None)
        .map_err(|e| map_archive_err("pdf 打开失败", e))?;
    let metadata = document.metadata();
    let title = metadata
        .get(PdfDocumentMetadataTagType::Title)
        .map(|tag| metadata_tag_text(&tag))
        .filter(|s| !s.is_empty());
    let authors = metadata
        .get(PdfDocumentMetadataTagType::Author)
        .map(|tag| metadata_tag_text(&tag))
        .map_or_else(Vec::new, |raw| split_pdf_authors(&raw));
    let description = metadata
        .get(PdfDocumentMetadataTagType::Subject)
        .map(|tag| metadata_tag_text(&tag))
        .filter(|s| !s.is_empty());
    let published_at = metadata
        .get(PdfDocumentMetadataTagType::CreationDate)
        .map(|tag| metadata_tag_text(&tag))
        .as_deref()
        .and_then(parse_pdf_date_to_ms);
    Ok((title, authors, description, published_at))
}

fn metadata_tag_text(tag: &PdfDocumentMetadataTag) -> String {
    tag.value().trim().to_string()
}

fn split_pdf_authors(raw: &str) -> Vec<String> {
    raw.split([',', ';'])
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(ToString::to_string)
        .collect()
}

fn parse_pdf_date_to_ms(raw: &str) -> Option<i64> {
    let trimmed = raw.trim().trim_start_matches("D:");
    if trimmed.len() < 8 {
        return None;
    }
    let digits: String = trimmed
        .chars()
        .take(14)
        .filter(char::is_ascii_digit)
        .collect();
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
    let secs =
        i64::from(days_from_ce) * 86_400 + i64::from(hour) * 3600 + i64::from(minute) * 60 + i64::from(second);
    SystemTime::UNIX_EPOCH
        .checked_add(Duration::from_secs(crate::util::i64_to_u64_nonnegative(secs.max(0))))
        .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
        .map(|d| crate::util::milliseconds_to_i64(d.as_millis()))
}

/// Algorithm from <http://howardhinnant.github.io/date_algorithms.html>
fn days_from_civil(year: i32, month: u32, day: u32) -> Option<u32> {
    if !(1..=12).contains(&month) || !(1..=31).contains(&day) {
        return None;
    }
    let y = crate::util::i32_to_u32(if month <= 2 { year - 1 } else { year });
    let era = y / 400;
    let yoe = y - era * 400;
    let doy = (153 * (if month > 2 { month - 3 } else { month + 9 }) + 2) / 5 + day - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    Some(era * 146_097 + doe - 719_468)
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
        remote_temp: None,
    })
}

pub fn open_pdf_backend_kept(
    file: &Path,
    keep: tempfile::NamedTempFile,
) -> Result<PdfBackend, HentaiError> {
    let mut backend = open_pdf_backend(file)?;
    backend.remote_temp = Some(keep);
    Ok(backend)
}

pub fn read_pdf_page(backend: &PdfBackend, page_index: usize) -> Result<Vec<u8>, HentaiError> {
    if page_index >= crate::util::i32_to_usize(backend.page_count) {
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
        .get(crate::util::usize_to_u16(page_index))
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

#[cfg(test)]
mod tests {
    use super::{date_to_utc_ms, parse_pdf_date_to_ms};

    #[test]
    fn parse_pdf_date_reads_standard_prefix() {
        let ms = parse_pdf_date_to_ms("D:20240615120000").expect("date");
        assert_eq!(ms, date_to_utc_ms(2024, 6, 15, 12, 0, 0).unwrap());
    }

    #[test]
    fn parse_pdf_date_reads_date_only() {
        let ms = parse_pdf_date_to_ms("D:20240101").expect("date");
        assert_eq!(ms, date_to_utc_ms(2024, 1, 1, 0, 0, 0).unwrap());
    }

    #[test]
    fn parse_pdf_date_ignores_timezone_suffix() {
        let ms = parse_pdf_date_to_ms("D:20240615120000+08'00'").expect("date");
        assert_eq!(ms, date_to_utc_ms(2024, 6, 15, 12, 0, 0).unwrap());
    }

    #[test]
    fn parse_pdf_date_rejects_too_short() {
        assert!(parse_pdf_date_to_ms("D:2024").is_none());
    }
}
