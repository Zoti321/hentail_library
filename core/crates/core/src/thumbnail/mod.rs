mod generate;
mod queue;

pub use generate::{
    encode_thumbnail_jpeg, generate_thumbnail_jpeg, store_thumbnail_for_comic,
    thumbnail_needs_generation,
};
pub use queue::{
    ensure_thumbnail, enqueue_thumbnails_low, watch_thumbnail_events, ThumbnailEvent,
    ThumbnailPriority, CRITICAL_WAIT_TIMEOUT,
};

use sea_orm::DatabaseConnection;

use crate::comic::ComicDto;
use crate::error::HentaiError;
use crate::sync::handle::SyncHandle;

pub struct ComicThumbnailDto {
    pub thumbnail: Vec<u8>,
    pub source_modified_ms: i64,
    pub source_size: i64,
    pub is_user_set: bool,
}

pub struct SeriesThumbnailDto {
    pub thumbnail: Vec<u8>,
    pub source_comic_id: String,
    pub source_page_index: i32,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SeriesCoverSource {
    CustomThumbnail { thumbnail: Vec<u8> },
    FallbackComic { comic_id: String },
    Missing,
}

pub struct ThumbnailBatchResult {
    pub failed_count: i32,
}

fn load_page_image_bytes(
    comic_id: &str,
    path: &str,
    resource_type: &str,
    page_index: i32,
) -> Result<Vec<u8>, HentaiError> {
    use crate::reader::{load_reader_page, ReaderPageDto};
    match load_reader_page(comic_id, path, resource_type, page_index)? {
        ReaderPageDto::FilePath { path: file_path } => {
            std::fs::read(&file_path).map_err(|e| HentaiError::validation(e.to_string()))
        }
        ReaderPageDto::Bytes { data } => Ok(data),
    }
}

fn now_ms() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0)
}

pub async fn find_thumbnail_by_comic_id(
    comic_id: &str,
) -> Result<Option<ComicThumbnailDto>, HentaiError> {
    use crate::db::{connection, map_db_err};
    use crate::entity::prelude::*;
    use sea_orm::EntityTrait;
    let db = connection()?;
    let row = ComicThumbnails::find_by_id(comic_id)
        .one(&db)
        .await
        .map_err(map_db_err)?;
    Ok(row.map(|r| ComicThumbnailDto {
        thumbnail: r.thumbnail,
        source_modified_ms: r.source_modified_ms.unwrap_or(0),
        source_size: r.source_size.unwrap_or(0),
        is_user_set: r.is_user_set,
    }))
}

/// 将漫画指定页（0-based）编码为缩略图并标记为用户设置封面。
pub async fn set_comic_thumbnail_from_page(
    comic_id: &str,
    path: &str,
    resource_type: &str,
    page_index: i32,
) -> Result<(), HentaiError> {
    use crate::db::{connection, map_db_err};
    use crate::entity::{comic_thumbnails, prelude::*};
    use crate::sync::parser::read_source_stat;
    use crate::thumbnail::generate::encode_thumbnail_jpeg;
    use sea_orm::{EntityTrait, Set};
    use std::path::Path;

    let source_bytes = load_page_image_bytes(comic_id, path, resource_type, page_index)?;
    let jpeg = encode_thumbnail_jpeg(&source_bytes)?
        .ok_or_else(|| HentaiError::validation("无法从当前页生成缩略图".to_string()))?;

    let (modified_ms, size) = read_source_stat(Path::new(path), resource_type)?.unwrap_or((0, 0));
    let db = connection()?;
    let active = comic_thumbnails::ActiveModel {
        comic_id: Set(comic_id.to_string()),
        thumbnail: Set(jpeg),
        updated_at: Set(now_ms()),
        source_modified_ms: Set(Some(modified_ms)),
        source_size: Set(Some(size)),
        is_user_set: Set(true),
    };
    ComicThumbnails::insert(active)
        .on_conflict(
            sea_orm::sea_query::OnConflict::column(comic_thumbnails::Column::ComicId)
                .update_columns([
                    comic_thumbnails::Column::Thumbnail,
                    comic_thumbnails::Column::UpdatedAt,
                    comic_thumbnails::Column::SourceModifiedMs,
                    comic_thumbnails::Column::SourceSize,
                    comic_thumbnails::Column::IsUserSet,
                ])
                .to_owned(),
        )
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    Ok(())
}

/// 将指定页设为系列自定义封面（每系列仅保留一张）。
pub async fn set_series_thumbnail_from_page(
    series_id: &str,
    comic_id: &str,
    path: &str,
    resource_type: &str,
    page_index: i32,
) -> Result<(), HentaiError> {
    use crate::db::{connection, map_db_err};
    use crate::entity::{prelude::*, series_thumbnails};
    use crate::thumbnail::generate::encode_thumbnail_jpeg;
    use sea_orm::{EntityTrait, Set};

    let source_bytes = load_page_image_bytes(comic_id, path, resource_type, page_index)?;
    let jpeg = encode_thumbnail_jpeg(&source_bytes)?
        .ok_or_else(|| HentaiError::validation("无法从当前页生成系列缩略图".to_string()))?;

    let db = connection()?;
    let active = series_thumbnails::ActiveModel {
        series_id: Set(series_id.to_string()),
        thumbnail: Set(jpeg),
        updated_at: Set(now_ms()),
        source_comic_id: Set(comic_id.to_string()),
        source_page_index: Set(page_index),
    };
    SeriesThumbnails::insert(active)
        .on_conflict(
            sea_orm::sea_query::OnConflict::column(series_thumbnails::Column::SeriesId)
                .update_columns([
                    series_thumbnails::Column::Thumbnail,
                    series_thumbnails::Column::UpdatedAt,
                    series_thumbnails::Column::SourceComicId,
                    series_thumbnails::Column::SourcePageIndex,
                ])
                .to_owned(),
        )
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    Ok(())
}

pub async fn find_series_thumbnail_by_series_id(
    series_id: &str,
) -> Result<Option<SeriesThumbnailDto>, HentaiError> {
    use crate::db::{connection, map_db_err};
    use crate::entity::prelude::*;
    use sea_orm::EntityTrait;

    let db = connection()?;
    let row = SeriesThumbnails::find_by_id(series_id)
        .one(&db)
        .await
        .map_err(map_db_err)?;
    Ok(row.map(|r| SeriesThumbnailDto {
        thumbnail: r.thumbnail,
        source_comic_id: r.source_comic_id,
        source_page_index: r.source_page_index,
    }))
}

/// 系列封面解析：自定义系列缩略图优先，否则回退到 sort_order 最大的成员漫画。
pub async fn resolve_series_cover(series_id: &str) -> Result<SeriesCoverSource, HentaiError> {
    if let Some(custom) = find_series_thumbnail_by_series_id(series_id).await? {
        return Ok(SeriesCoverSource::CustomThumbnail {
            thumbnail: custom.thumbnail,
        });
    }

    use crate::db::{connection, map_db_err};
    use crate::entity::series_items;
    use sea_orm::{ColumnTrait, EntityTrait, QueryFilter, QueryOrder};

    let db = connection()?;
    let items = series_items::Entity::find()
        .filter(series_items::Column::SeriesId.eq(series_id))
        .order_by_desc(series_items::Column::SortOrder)
        .order_by_asc(series_items::Column::ComicId)
        .all(&db)
        .await
        .map_err(map_db_err)?;

    let Some(best) = items.into_iter().next() else {
        return Ok(SeriesCoverSource::Missing);
    };
    Ok(SeriesCoverSource::FallbackComic {
        comic_id: best.comic_id,
    })
}

pub async fn delete_thumbnails_by_comic_ids(comic_ids: Vec<String>) -> Result<(), HentaiError> {
    use crate::db::{connection, map_db_err};
    use crate::entity::comic_thumbnails;
    use sea_orm::{ColumnTrait, EntityTrait, QueryFilter};
    if comic_ids.is_empty() {
        return Ok(());
    }
    let db = connection()?;
    comic_thumbnails::Entity::delete_many()
        .filter(comic_thumbnails::Column::ComicId.is_in(comic_ids))
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    Ok(())
}

pub async fn generate_thumbnails(
    db: &DatabaseConnection,
    targets: &[ComicDto],
    handle: &SyncHandle,
    mut on_progress: impl FnMut(i32, i32, Option<String>),
) -> Result<ThumbnailBatchResult, HentaiError> {
    let total = targets.len() as i32;
    let mut done = 0i32;
    let mut failed = 0i32;
    for comic in targets {
        if handle.is_cancelled() {
            break;
        }
        on_progress(done, total, Some(comic.path.clone()));
        match store_thumbnail_for_comic(db, comic).await {
            Ok(true) => {}
            Ok(false) => failed += 1,
            Err(_) => failed += 1,
        }
        done += 1;
        on_progress(done, total, Some(comic.path.clone()));
    }
    Ok(ThumbnailBatchResult {
        failed_count: failed,
    })
}
