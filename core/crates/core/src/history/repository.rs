use sea_orm::{
    ColumnTrait, EntityTrait, PaginatorTrait, QueryFilter, QueryOrder, Set,
};

use crate::comic::read_data_version;
use crate::db::{connection, map_db_err};
use crate::entity::{comic_reading_histories, prelude::*};
use crate::error::HentaiError;

use super::dto::{PagedReadingHistoryDto, ReadingHistoryDto};

pub async fn record_reading(dto: &ReadingHistoryDto) -> Result<(), HentaiError> {
    let db = connection()?;
    let model = comic_reading_histories::ActiveModel {
        comic_id: Set(dto.comic_id.clone()),
        title: Set(dto.title.clone()),
        last_read_time: Set(dto.last_read_time_ms),
        page_index: Set(dto.page_index),
        ..Default::default()
    };
    ComicReadingHistories::insert(model)
        .on_conflict(
            sea_orm::sea_query::OnConflict::column(comic_reading_histories::Column::ComicId)
                .update_columns([
                    comic_reading_histories::Column::Title,
                    comic_reading_histories::Column::LastReadTime,
                    comic_reading_histories::Column::PageIndex,
                ])
                .to_owned(),
        )
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    Ok(())
}

pub async fn get_reading_by_comic_id(comic_id: &str) -> Result<Option<ReadingHistoryDto>, HentaiError> {
    let db = connection()?;
    let row = ComicReadingHistories::find_by_id(comic_id)
        .one(&db)
        .await
        .map_err(map_db_err)?;
    Ok(row.map(map_reading_row))
}

pub async fn list_all_reading() -> Result<Vec<ReadingHistoryDto>, HentaiError> {
    let db = connection()?;
    let rows = ComicReadingHistories::find()
        .order_by_desc(comic_reading_histories::Column::LastReadTime)
        .all(&db)
        .await
        .map_err(map_db_err)?;
    Ok(rows.into_iter().map(map_reading_row).collect())
}

pub async fn fetch_reading_page(page: i32, page_size: i32) -> Result<PagedReadingHistoryDto, HentaiError> {
    let db = connection()?;
    if page_size <= 0 {
        return Ok(PagedReadingHistoryDto {
            items: vec![],
            total_count: 0,
        });
    }
    let paginator = ComicReadingHistories::find()
        .order_by_desc(comic_reading_histories::Column::LastReadTime)
        .paginate(&db, page_size as u64);
    let total_count = paginator.num_items().await.map_err(map_db_err)? as i64;
    let page_index = if page <= 0 { 1 } else { page } as u64;
    let rows = paginator
        .fetch_page(page_index - 1)
        .await
        .map_err(map_db_err)?;
    Ok(PagedReadingHistoryDto {
        items: rows.into_iter().map(map_reading_row).collect(),
        total_count,
    })
}

pub async fn delete_reading_by_comic_id(comic_id: &str) -> Result<i32, HentaiError> {
    let db = connection()?;
    let res = ComicReadingHistories::delete_by_id(comic_id)
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    Ok(res.rows_affected as i32)
}

pub async fn delete_reading_by_comic_ids(comic_ids: &[String]) -> Result<i32, HentaiError> {
    if comic_ids.is_empty() {
        return Ok(0);
    }
    let db = connection()?;
    let res = ComicReadingHistories::delete_many()
        .filter(comic_reading_histories::Column::ComicId.is_in(comic_ids.to_vec()))
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    Ok(res.rows_affected as i32)
}

pub async fn clear_all_reading() -> Result<i32, HentaiError> {
    let db = connection()?;
    let res = ComicReadingHistories::delete_many()
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    Ok(res.rows_affected as i32)
}

pub async fn watch_reading_histories(
    mut emit: impl FnMut(Vec<ReadingHistoryDto>) -> Result<(), HentaiError>,
) -> Result<(), HentaiError> {
    let mut last = read_data_version().await?;
    loop {
        tokio::time::sleep(std::time::Duration::from_millis(400)).await;
        let version = read_data_version().await?;
        if version != last {
            last = version;
            emit(list_all_reading().await?)?;
        }
    }
}

fn map_reading_row(row: comic_reading_histories::Model) -> ReadingHistoryDto {
    ReadingHistoryDto {
        comic_id: row.comic_id,
        title: row.title,
        last_read_time_ms: row.last_read_time,
        page_index: row.page_index,
    }
}
