//! Image set catalog cover: SQLite JPEG ≤512 from the default workspace first image (ADR-0067).

mod queue;

use std::path::{Component, Path, PathBuf};

use sea_orm::{EntityTrait, QuerySelect, Set};

use crate::db::{connection, map_db_err};
use crate::entity::{image_set_thumbnails, prelude::*};
use crate::error::HentaiError;
use crate::library::find_library_by_id;
use crate::resource::{local_access, read_source_stat_with};
use crate::thumbnail::encode_thumbnail_jpeg;

use super::catalog::list_image_set_images;
use super::dto::ImageSetImageDto;
use crate::reader::load_image_set_page_bytes;

pub use queue::{
    enqueue_image_set_covers_low, ensure_image_set_cover, watch_image_set_cover_events,
    ImageSetCoverEvent,
};

#[derive(Debug, Clone)]
pub struct ImageSetCoverDto {
    pub thumbnail: Vec<u8>,
    pub source_image_set_image_id: String,
    pub source_modified_ms: i64,
    pub source_size: i64,
}

fn now_ms() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map_or(0, |d| crate::util::milliseconds_to_i64(d.as_millis()))
}

pub async fn find_image_set_cover(
    image_set_id: &str,
) -> Result<Option<ImageSetCoverDto>, HentaiError> {
    let db = connection()?;
    let row = ImageSetThumbnails::find_by_id(image_set_id)
        .one(&db)
        .await
        .map_err(|e| map_db_err(&e))?;
    Ok(row.map(|r| ImageSetCoverDto {
        thumbnail: r.thumbnail,
        source_image_set_image_id: r.source_image_set_image_id,
        source_modified_ms: r.source_modified_ms,
        source_size: r.source_size,
    }))
}

/// Fingerprint / source-id check only — never load the thumbnail BLOB.
pub async fn image_set_cover_needs_generation(
    library_id: &str,
    image_set_id: &str,
) -> Result<bool, HentaiError> {
    let Some(first) = first_cover_image(library_id, image_set_id).await? else {
        return Ok(false);
    };
    let Some((modified_ms, size)) = carrier_fingerprint(library_id, &first).await? else {
        return Ok(false);
    };
    let db = connection()?;
    let cached: Option<(String, i64, i64)> = ImageSetThumbnails::find_by_id(image_set_id)
        .select_only()
        .column(image_set_thumbnails::Column::SourceImageSetImageId)
        .column(image_set_thumbnails::Column::SourceModifiedMs)
        .column(image_set_thumbnails::Column::SourceSize)
        .into_tuple()
        .one(&db)
        .await
        .map_err(|e| map_db_err(&e))?;
    let Some((source_id, cached_ms, cached_size)) = cached else {
        return Ok(true);
    };
    Ok(source_id != first.image_set_image_id
        || cached_ms != modified_ms
        || cached_size != size)
}

/// Stores cover JPEG. On success returns written bytes (command projection).
pub async fn store_image_set_cover(
    library_id: &str,
    image_set_id: &str,
) -> Result<Option<Vec<u8>>, HentaiError> {
    let Some(first) = first_cover_image(library_id, image_set_id).await? else {
        return Ok(None);
    };
    let Some((modified_ms, size)) = carrier_fingerprint(library_id, &first).await? else {
        return Ok(None);
    };
    let source = load_image_set_page_bytes(library_id, &first).await?;
    let jpeg = encode_thumbnail_jpeg(&source)?
        .ok_or_else(|| HentaiError::validation("无法从图集首图生成封面".to_string()))?;
    let db = connection()?;
    let active = image_set_thumbnails::ActiveModel {
        image_set_id: Set(image_set_id.to_string()),
        thumbnail: Set(jpeg.clone()),
        source_image_set_image_id: Set(first.image_set_image_id.clone()),
        source_modified_ms: Set(modified_ms),
        source_size: Set(size),
        updated_at: Set(now_ms()),
    };
    ImageSetThumbnails::insert(active)
        .on_conflict(
            sea_orm::sea_query::OnConflict::column(image_set_thumbnails::Column::ImageSetId)
                .update_columns([
                    image_set_thumbnails::Column::Thumbnail,
                    image_set_thumbnails::Column::SourceImageSetImageId,
                    image_set_thumbnails::Column::SourceModifiedMs,
                    image_set_thumbnails::Column::SourceSize,
                    image_set_thumbnails::Column::UpdatedAt,
                ])
                .to_owned(),
        )
        .exec(&db)
        .await
        .map_err(|e| map_db_err(&e))?;
    Ok(Some(jpeg))
}

/// Drops the cached cover so the next ensure regenerates (workspace first-image change).
pub async fn invalidate_image_set_cover(image_set_id: &str) -> Result<(), HentaiError> {
    let db = connection()?;
    ImageSetThumbnails::delete_by_id(image_set_id)
        .exec(&db)
        .await
        .map_err(|e| map_db_err(&e))?;
    Ok(())
}

/// Image set ids in a library whose cover is missing or stale (projection only).
pub async fn list_image_set_cover_targets(
    library_id: &str,
) -> Result<Vec<String>, HentaiError> {
    let sets = super::catalog::list_image_sets(library_id).await?;
    let mut out = Vec::new();
    for set in sets {
        if image_set_cover_needs_generation(library_id, &set.image_set_id).await? {
            out.push(set.image_set_id);
        }
    }
    Ok(out)
}

async fn first_cover_image(
    library_id: &str,
    image_set_id: &str,
) -> Result<Option<ImageSetImageDto>, HentaiError> {
    let images = list_image_set_images(library_id, image_set_id).await?;
    Ok(images.into_iter().next())
}

async fn carrier_fingerprint(
    library_id: &str,
    image: &ImageSetImageDto,
) -> Result<Option<(i64, i64)>, HentaiError> {
    let library = find_library_by_id(library_id)
        .await?
        .ok_or_else(|| HentaiError::validation(format!("图集库不存在: {library_id}")))?;
    let carrier = resolve_carrier_path(&library.root_path, &image.carrier_relative_path)?;
    let resource_type = carrier_resource_type(&image.carrier_kind);
    read_source_stat_with(
        local_access(),
        &carrier.to_string_lossy(),
        resource_type,
    )
}

fn carrier_resource_type(carrier_kind: &str) -> &'static str {
    match carrier_kind {
        "zip" => "zip",
        "rar" => "rar",
        "sevenz" => "7z",
        _ => "jpg",
    }
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
