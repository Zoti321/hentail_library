use sea_orm::{
    ActiveModelTrait, ColumnTrait, ConnectionTrait, EntityTrait, PaginatorTrait, QueryFilter,
    QueryOrder, Set,
};
use sea_orm::sea_query::{Expr, Func};

use crate::comic::read_data_version;
use crate::db::{connection, map_db_err};
use crate::entity::{comic_reading_histories, prelude::*, series_reading_histories};
use crate::error::HentaiError;
use crate::util::decode_basic_html_entities;

use super::dto::{PagedReadingHistoryDto, ReadingHistoryDto, SeriesReadingHistoryDto};

pub async fn record_reading(dto: &ReadingHistoryDto) -> Result<(), HentaiError> {
    let db = connection()?;
    let model = comic_reading_histories::ActiveModel {
        comic_id: Set(dto.comic_id.clone()),
        title: Set(decode_basic_html_entities(&dto.title)),
        last_read_time: Set(dto.last_read_time_ms),
        page_index: Set(dto.page_index),
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

/// Library sync 时幂等清洗历史标题快照中的 HTML 实体。
pub async fn normalize_reading_history_titles<C: ConnectionTrait>(
    db: &C,
) -> Result<usize, HentaiError> {
    let rows = ComicReadingHistories::find()
        .all(db)
        .await
        .map_err(map_db_err)?;
    let mut updated = 0usize;
    for row in rows {
        let decoded = decode_basic_html_entities(&row.title);
        if decoded == row.title {
            continue;
        }
        let mut active: comic_reading_histories::ActiveModel = row.into();
        active.title = Set(decoded);
        active.update(db).await.map_err(map_db_err)?;
        updated += 1;
    }
    Ok(updated)
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

pub async fn fetch_reading_page(
    page: i32,
    page_size: i32,
    keyword: Option<String>,
) -> Result<PagedReadingHistoryDto, HentaiError> {
    let db = connection()?;
    if page_size <= 0 {
        return Ok(PagedReadingHistoryDto {
            items: vec![],
            total_count: 0,
        });
    }
    let query = reading_history_list_query(keyword.as_deref());
    let paginator = query
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

fn reading_history_list_query(
    keyword: Option<&str>,
) -> sea_orm::Select<ComicReadingHistories> {
    let mut query = ComicReadingHistories::find();
    let normalized = keyword.map(str::trim).filter(|value| !value.is_empty());
    if let Some(keyword) = normalized {
        let pattern = format!("%{}%", keyword.to_lowercase());
        query = query.filter(
            Expr::expr(Func::lower(Expr::col(comic_reading_histories::Column::Title)))
                .like(pattern),
        );
    }
    query
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

pub async fn record_series_reading(dto: &SeriesReadingHistoryDto) -> Result<(), HentaiError> {
    let db = connection()?;
    let model = series_reading_histories::ActiveModel {
        series_id: Set(dto.series_id.clone()),
        last_read_comic_id: Set(dto.last_read_comic_id.clone()),
        last_read_time: Set(dto.last_read_time_ms),
        page_index: Set(dto.page_index),
    };
    SeriesReadingHistories::insert(model)
        .on_conflict(
            sea_orm::sea_query::OnConflict::column(series_reading_histories::Column::SeriesId)
                .update_columns([
                    series_reading_histories::Column::LastReadComicId,
                    series_reading_histories::Column::LastReadTime,
                    series_reading_histories::Column::PageIndex,
                ])
                .to_owned(),
        )
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    Ok(())
}

pub async fn get_series_reading_by_series_id(
    series_id: &str,
) -> Result<Option<SeriesReadingHistoryDto>, HentaiError> {
    let db = connection()?;
    let row = SeriesReadingHistories::find_by_id(series_id)
        .one(&db)
        .await
        .map_err(map_db_err)?;
    Ok(row.map(map_series_reading_row))
}

pub async fn delete_series_reading_by_series_id(series_id: &str) -> Result<i32, HentaiError> {
    let db = connection()?;
    let res = SeriesReadingHistories::delete_by_id(series_id)
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

fn map_series_reading_row(row: series_reading_histories::Model) -> SeriesReadingHistoryDto {
    SeriesReadingHistoryDto {
        series_id: row.series_id,
        last_read_comic_id: row.last_read_comic_id,
        last_read_time_ms: row.last_read_time,
        page_index: row.page_index,
    }
}
