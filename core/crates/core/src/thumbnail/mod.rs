mod generate;
mod queue;

pub use generate::{generate_thumbnail_jpeg, store_thumbnail_for_comic, thumbnail_needs_generation};
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
}

pub struct ThumbnailBatchResult {
    pub failed_count: i32,
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
    }))
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
