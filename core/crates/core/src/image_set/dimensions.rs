//! Header-only pixel dimensions for Image set images (ADR-0066).

use std::fs::File;
use std::io::{BufReader, Cursor, Read};
use std::path::{Component, Path, PathBuf};

use image::ImageReader;
use zip::ZipArchive;

use crate::entity::image_set_images;
use crate::error::HentaiError;
use crate::formats::{map_archive_err, read_rar_entry, read_sevenz_entry};

/// Probe pixel width/height from encoded image bytes (header decode, not full raster).
pub(crate) fn probe_image_dimensions(bytes: &[u8]) -> Option<(u32, u32)> {
    let reader = ImageReader::new(Cursor::new(bytes))
        .with_guessed_format()
        .ok()?;
    let (width, height) = reader.into_dimensions().ok()?;
    (width > 0 && height > 0).then_some((width, height))
}

/// Fill `width`/`height` on newly inserted catalog rows by reading under the Library root.
pub(crate) fn enrich_insert_dimensions(root: &str, inserts: &mut [image_set_images::Model]) {
    for image in inserts {
        if image.width.is_some() && image.height.is_some() {
            continue;
        }
        match probe_row_dimensions(root, image) {
            Ok(Some((width, height))) => {
                image.width = i32::try_from(width).ok();
                image.height = i32::try_from(height).ok();
            }
            Ok(None) => {}
            Err(err) => {
                tracing::debug!(
                    carrier = %image.carrier_relative_path,
                    member = %image.member_path,
                    error = %err.message,
                    "image set dimension probe skipped"
                );
            }
        }
    }
}

fn probe_row_dimensions(
    root: &str,
    row: &image_set_images::Model,
) -> Result<Option<(u32, u32)>, HentaiError> {
    let carrier = resolve_carrier_path(root, &row.carrier_relative_path)?;
    match row.carrier_kind.as_str() {
        "loose" => Ok(probe_image_file(&carrier)),
        "zip" => Ok(probe_image_dimensions(&read_zip_member(
            &carrier,
            &row.member_path,
        )?)),
        "rar" => Ok(probe_image_dimensions(&read_rar_entry(
            &carrier,
            &row.member_path,
        )?)),
        "sevenz" => Ok(probe_image_dimensions(&read_sevenz_entry(
            &carrier,
            &row.member_path,
        )?)),
        other => Err(HentaiError::validation(format!("未知图集载体: {other}"))),
    }
}

/// Streamed header decode for a loose image file (does not load the whole file first).
pub(crate) fn probe_image_file(path: &Path) -> Option<(u32, u32)> {
    let reader = ImageReader::open(path).ok()?.with_guessed_format().ok()?;
    let (width, height) = reader.into_dimensions().ok()?;
    (width > 0 && height > 0).then_some((width, height))
}

fn resolve_carrier_path(root: &str, carrier_relative_path: &str) -> Result<PathBuf, HentaiError> {
    let relative = Path::new(carrier_relative_path);
    let safe = !carrier_relative_path.is_empty()
        && relative
            .components()
            .all(|component| matches!(component, Component::Normal(_)));
    if !safe {
        return Err(HentaiError::validation(format!(
            "图集载体路径无效: {carrier_relative_path}"
        )));
    }
    Ok(Path::new(root).join(relative))
}

fn read_zip_member(file: &Path, member_path: &str) -> Result<Vec<u8>, HentaiError> {
    let handle = File::open(file).map_err(|e| map_archive_err("zip 打开失败", e))?;
    let mut archive =
        ZipArchive::new(BufReader::new(handle)).map_err(|e| map_archive_err("zip 解析失败", e))?;
    let raw_name = archive
        .file_names()
        .find(|name| name.replace('\\', "/") == member_path)
        .map(str::to_string)
        .ok_or_else(|| HentaiError::validation(format!("压缩包内无条目: {member_path}")))?;
    let mut entry = archive
        .by_name(&raw_name)
        .map_err(|e| map_archive_err("zip 条目读取失败", e))?;
    let mut buf = Vec::new();
    entry
        .read_to_end(&mut buf)
        .map_err(|e| map_archive_err("zip 条目读取失败", e))?;
    Ok(buf)
}

#[cfg(test)]
mod tests {
    use super::*;
    use image::{ImageBuffer, Rgb};

    fn png_bytes(width: u32, height: u32) -> Vec<u8> {
        let img: ImageBuffer<Rgb<u8>, Vec<u8>> =
            ImageBuffer::from_pixel(width, height, Rgb([0, 0, 0]));
        let mut out = Vec::new();
        img.write_to(&mut Cursor::new(&mut out), image::ImageFormat::Png)
            .expect("encode png");
        out
    }

    #[test]
    fn probe_image_dimensions_reads_png_ihdr() {
        assert_eq!(probe_image_dimensions(&png_bytes(32, 48)), Some((32, 48)));
        assert_eq!(probe_image_dimensions(&png_bytes(200, 100)), Some((200, 100)));
        assert_eq!(probe_image_dimensions(b"not-an-image"), None);
    }
}
