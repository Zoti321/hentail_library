use std::fs::File;
use std::io::{BufReader, Read};
use std::path::Path;

use image::imageops::FilterType;
use image::{DynamicImage, GenericImageView, Rgba};
use sea_orm::{DatabaseConnection, EntityTrait, Set};
use zip::ZipArchive;

use crate::comic::ComicDto;
use crate::db::map_db_err;
use crate::entity::{comic_thumbnails, prelude::*};
use crate::error::HentaiError;
use crate::formats::read_rar_cover_bytes;
use crate::sync::parser::{
    basename, basename_without_extension, can_generate_thumbnail, extension_lower,
    is_comic_image_extension, read_source_stat,
};

const MAX_LONG_EDGE: u32 = 512;
const JPEG_QUALITY: u8 = 85;

pub async fn thumbnail_needs_generation(
    db: &DatabaseConnection,
    comic: &ComicDto,
) -> Result<bool, HentaiError> {
    if !can_generate_thumbnail(&comic.resource_type) {
        return Ok(false);
    }
    let path = Path::new(&comic.path);
    let Some((modified_ms, size)) = read_source_stat(path, &comic.resource_type)? else {
        return Ok(false);
    };
    let cached = ComicThumbnails::find_by_id(comic.comic_id.clone())
        .one(db)
        .await
        .map_err(map_db_err)?;
    let Some(cached) = cached else {
        return Ok(true);
    };
    Ok(cached.source_modified_ms != Some(modified_ms)
        || cached.source_size != Some(size))
}

pub async fn store_thumbnail_for_comic(
    db: &DatabaseConnection,
    comic: &ComicDto,
) -> Result<bool, HentaiError> {
    let path = Path::new(&comic.path);
    let Some((modified_ms, size)) = read_source_stat(path, &comic.resource_type)? else {
        return Ok(false);
    };
    let jpeg = tokio::task::spawn_blocking({
        let path = path.to_path_buf();
        let resource_type = comic.resource_type.clone();
        move || generate_thumbnail_jpeg(&path, &resource_type)
    })
    .await
    .map_err(|e| HentaiError::validation(e.to_string()))??;
    let Some(jpeg) = jpeg else {
        return Ok(false);
    };
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0);
    let active = comic_thumbnails::ActiveModel {
        comic_id: Set(comic.comic_id.clone()),
        thumbnail: Set(jpeg),
        updated_at: Set(now),
        source_modified_ms: Set(Some(modified_ms)),
        source_size: Set(Some(size)),
    };
    ComicThumbnails::insert(active)
        .on_conflict(
            sea_orm::sea_query::OnConflict::column(comic_thumbnails::Column::ComicId)
                .update_columns([
                    comic_thumbnails::Column::Thumbnail,
                    comic_thumbnails::Column::UpdatedAt,
                    comic_thumbnails::Column::SourceModifiedMs,
                    comic_thumbnails::Column::SourceSize,
                ])
                .to_owned(),
        )
        .exec(db)
        .await
        .map_err(map_db_err)?;
    Ok(true)
}

pub fn generate_thumbnail_jpeg(path: &Path, resource_type: &str) -> Result<Option<Vec<u8>>, HentaiError> {
    let source = load_cover_bytes(path, resource_type)?;
    let Some(bytes) = source else {
        return Ok(None);
    };
    encode_thumbnail_jpeg(&bytes)
}

fn encode_thumbnail_jpeg(source_bytes: &[u8]) -> Result<Option<Vec<u8>>, HentaiError> {
    let img = image::load_from_memory(source_bytes).map_err(|e| HentaiError::validation(e.to_string()))?;
    let flattened = flatten_alpha_on_white(&img);
    let resized = resize_to_max_long_edge(&flattened, MAX_LONG_EDGE);
    let mut buf = Vec::new();
    let mut encoder = image::codecs::jpeg::JpegEncoder::new_with_quality(&mut buf, JPEG_QUALITY);
    encoder
        .encode_image(&resized)
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    Ok(Some(buf))
}

fn flatten_alpha_on_white(img: &DynamicImage) -> DynamicImage {
    if !img.color().has_alpha() {
        return img.clone();
    }
    let rgba = img.to_rgba8();
    let (w, h) = rgba.dimensions();
    let mut canvas = image::RgbaImage::from_pixel(w, h, Rgba([255, 255, 255, 255]));
    image::imageops::overlay(&mut canvas, &rgba, 0, 0);
    DynamicImage::ImageRgba8(canvas)
}

fn resize_to_max_long_edge(img: &DynamicImage, max_long_edge: u32) -> DynamicImage {
    let (w, h) = img.dimensions();
    let long_edge = w.max(h);
    if long_edge <= max_long_edge {
        return img.clone();
    }
    if w >= h {
        img.resize(max_long_edge, (h * max_long_edge) / w, FilterType::Lanczos3)
    } else {
        img.resize((w * max_long_edge) / h, max_long_edge, FilterType::Lanczos3)
    }
}

fn load_cover_bytes(path: &Path, resource_type: &str) -> Result<Option<Vec<u8>>, HentaiError> {
    match resource_type {
        "dir" => load_dir_cover(path),
        "zip" | "cbz" => load_zip_cover(path),
        "rar" | "cbr" => read_rar_cover_bytes(path),
        "epub" => load_epub_cover(path),
        _ => Ok(None),
    }
}

fn load_dir_cover(dir: &Path) -> Result<Option<Vec<u8>>, HentaiError> {
    let mut image_files = Vec::new();
    for entry in std::fs::read_dir(dir).map_err(|e| HentaiError::validation(e.to_string()))? {
        let entry = entry.map_err(|e| HentaiError::validation(e.to_string()))?;
        let p = entry.path();
        if p.is_file() && is_comic_image_extension(&extension_lower(&p)) {
            image_files.push(p);
        }
    }
    if image_files.is_empty() {
        return Ok(None);
    }
    image_files.sort_by(|a, b| compare_filename_natural(&basename(a), &basename(b)));
    let mut chosen = &image_files[0];
    for f in &image_files {
        if basename_without_extension(f).eq_ignore_ascii_case("cover") {
            chosen = f;
            break;
        }
    }
    std::fs::read(chosen)
        .map(Some)
        .map_err(|e| HentaiError::validation(e.to_string()))
}

fn load_zip_cover(file: &Path) -> Result<Option<Vec<u8>>, HentaiError> {
    let f = File::open(file).map_err(|e| HentaiError::validation(e.to_string()))?;
    let mut archive = ZipArchive::new(BufReader::new(f))
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    let mut entries: Vec<(String, usize)> = Vec::new();
    for i in 0..archive.len() {
        let entry = archive
            .by_index(i)
            .map_err(|e| HentaiError::validation(e.to_string()))?;
        let name = entry.name().replace('\\', "/");
        if entry.is_dir() || name.ends_with('/') {
            continue;
        }
        let ext = Path::new(&name)
            .extension()
            .and_then(|e| e.to_str())
            .map(|e| format!(".{}", e.to_lowercase()))
            .unwrap_or_default();
        if is_comic_image_extension(&ext) {
            entries.push((name, i));
        }
    }
    if entries.is_empty() {
        return Ok(None);
    }
    entries.sort_by(|a, b| compare_filename_natural(&basename(Path::new(&a.0)), &basename(Path::new(&b.0))));
    let mut chosen_idx = entries[0].1;
    for (name, idx) in &entries {
        if basename_without_extension(Path::new(name)).eq_ignore_ascii_case("cover") {
            chosen_idx = *idx;
            break;
        }
    }
    let mut file = archive
        .by_index(chosen_idx)
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    let mut buf = Vec::new();
    file.read_to_end(&mut buf)
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    Ok(Some(buf))
}

fn load_epub_cover(file: &Path) -> Result<Option<Vec<u8>>, HentaiError> {
    let f = File::open(file).map_err(|e| HentaiError::validation(e.to_string()))?;
    let mut archive = ZipArchive::new(BufReader::new(f))
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    let mut images: Vec<(String, usize)> = Vec::new();
    for i in 0..archive.len() {
        let entry = archive
            .by_index(i)
            .map_err(|e| HentaiError::validation(e.to_string()))?;
        let name = entry.name().replace('\\', "/");
        if entry.is_dir() || name.ends_with('/') {
            continue;
        }
        let ext = Path::new(&name)
            .extension()
            .and_then(|e| e.to_str())
            .map(|e| format!(".{}", e.to_lowercase()))
            .unwrap_or_default();
        if is_comic_image_extension(&ext) {
            images.push((name, i));
        }
    }
    if images.is_empty() {
        return Ok(None);
    }
    let mut chosen_idx = images[0].1;
    for (name, idx) in &images {
        if basename(Path::new(name)).to_lowercase().contains("cover") {
            chosen_idx = *idx;
            break;
        }
    }
    let mut file = archive
        .by_index(chosen_idx)
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    let mut buf = Vec::new();
    file.read_to_end(&mut buf)
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    Ok(Some(buf))
}

fn compare_filename_natural(a: &str, b: &str) -> std::cmp::Ordering {
    let a_parts = split_natural(a);
    let b_parts = split_natural(b);
    for (ap, bp) in a_parts.iter().zip(b_parts.iter()) {
        match (ap.parse::<u64>(), bp.parse::<u64>()) {
            (Ok(na), Ok(nb)) => match na.cmp(&nb) {
                std::cmp::Ordering::Equal => continue,
                other => return other,
            },
            _ => match ap.cmp(bp) {
                std::cmp::Ordering::Equal => continue,
                other => return other,
            },
        }
    }
    a_parts.len().cmp(&b_parts.len())
}

fn split_natural(s: &str) -> Vec<String> {
    let mut parts = Vec::new();
    let mut current = String::new();
    let mut was_digit = false;
    for ch in s.chars() {
        let is_digit = ch.is_ascii_digit();
        if !current.is_empty() && is_digit != was_digit {
            parts.push(current.clone());
            current.clear();
        }
        current.push(ch);
        was_digit = is_digit;
    }
    if !current.is_empty() {
        parts.push(current);
    }
    parts
}
