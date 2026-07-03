use sea_orm::{ColumnTrait, EntityTrait, QueryFilter};

use crate::db::{connection, map_db_err};
use crate::entity::{comic_thumbnails, prelude::*};
use crate::error::HentaiError;

#[derive(Debug, Clone)]
pub struct ComicThumbnailDto {
    pub thumbnail: Vec<u8>,
    pub source_modified_ms: i64,
    pub source_size: i64,
}

pub async fn find_thumbnail_by_comic_id(
    comic_id: &str,
) -> Result<Option<ComicThumbnailDto>, HentaiError> {
    let db = connection()?;
    let row = ComicThumbnails::find_by_id(comic_id)
        .one(&db)
        .await
        .map_err(map_db_err)?;
    Ok(row.map(|r| ComicThumbnailDto {
        thumbnail: r.thumbnail,
        source_modified_ms: r.source_modified_ms.unwrap_or(0),
        source_size: r.source_size.unwrap_or(0),
    }))
}

pub async fn delete_thumbnails_by_comic_ids(comic_ids: Vec<String>) -> Result<(), HentaiError> {
    if comic_ids.is_empty() {
        return Ok(());
    }
    let db = connection()?;
    ComicThumbnails::delete_many()
        .filter(comic_thumbnails::Column::ComicId.is_in(comic_ids))
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    Ok(())
}
