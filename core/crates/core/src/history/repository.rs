use sea_orm::sea_query::{Expr, Func};
use sea_orm::{
    ActiveModelTrait, ColumnTrait, ConnectionTrait, EntityTrait, PaginatorTrait, QueryFilter,
    QueryOrder, Set, Statement, TransactionTrait,
};

use crate::comic::now_ms;
use crate::comic::visibility::comic_id_not_trashed_sql;
use crate::db::{connection, map_db_err};
use crate::entity::{comic_meta, comic_reading_histories, prelude::*};
use crate::error::HentaiError;
use crate::library_write::with_library_write;
use crate::util::decode_basic_html_entities;
use std::collections::HashMap;

use super::dto::{PagedReadingHistoryDto, ReadingHistoryDto, ReadingHistoryTimeSectionCountsDto};
use super::retention::reading_history_retention_cutoff_ms;
use super::retention::reading_history_within_retention;
use super::section_bounds::reading_history_section_bounds;

pub async fn record_reading(dto: &ReadingHistoryDto) -> Result<(), HentaiError> {
    let db = connection()?;
    let txn = db.begin().await.map_err(|e| map_db_err(&e))?;
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
        .exec(&txn)
        .await
        .map_err(|e| map_db_err(&e))?;
    purge_expired_reading_histories(&txn).await?;
    txn.commit().await.map_err(|e| map_db_err(&e))?;
    crate::revision::notify_committed();
    Ok(())
}

pub async fn purge_expired_reading_histories<C: ConnectionTrait>(
    db: &C,
) -> Result<u64, HentaiError> {
    let cutoff = reading_history_retention_cutoff_ms(now_ms());
    let res = ComicReadingHistories::delete_many()
        .filter(comic_reading_histories::Column::LastReadTime.lt(cutoff))
        .exec(db)
        .await
        .map_err(|e| map_db_err(&e))?;
    Ok(res.rows_affected)
}

fn within_retention_expr(now: i64) -> sea_orm::sea_query::SimpleExpr {
    Expr::col(comic_reading_histories::Column::LastReadTime)
        .gte(reading_history_retention_cutoff_ms(now))
}

/// Library sync 时幂等清洗历史标题快照中的 HTML 实体。
pub async fn normalize_reading_history_titles<C: ConnectionTrait>(
    db: &C,
) -> Result<usize, HentaiError> {
    let rows = ComicReadingHistories::find()
        .all(db)
        .await
        .map_err(|e| map_db_err(&e))?;
    let mut updated = 0usize;
    for row in rows {
        let decoded = decode_basic_html_entities(&row.title);
        if decoded == row.title {
            continue;
        }
        let mut active: comic_reading_histories::ActiveModel = row.into();
        active.title = Set(decoded);
        active.update(db).await.map_err(|e| map_db_err(&e))?;
        updated += 1;
    }
    Ok(updated)
}

pub async fn get_reading_by_comic_id(
    comic_id: &str,
) -> Result<Option<ReadingHistoryDto>, HentaiError> {
    let db = connection()?;
    let row = ComicReadingHistories::find_by_id(comic_id)
        .one(&db)
        .await
        .map_err(|e| map_db_err(&e))?;
    let Some(row) = row else {
        return Ok(None);
    };
    if !reading_history_within_retention(row.last_read_time, now_ms()) {
        return Ok(None);
    }
    let item = map_reading_row(row);
    let mut items = enrich_page_counts(&db, vec![item]).await?;
    Ok(items.pop())
}

/// 库浏览封面进度条：仅 `comic_id` + `page_index，不含标题` enrich。
pub async fn list_read_page_indexes() -> Result<Vec<super::dto::ReadPageIndexDto>, HentaiError> {
    let db = connection()?;
    let rows = ComicReadingHistories::find()
        .filter(not_trashed_history_expr())
        .filter(within_retention_expr(now_ms()))
        .filter(comic_reading_histories::Column::PageIndex.is_not_null())
        .all(&db)
        .await
        .map_err(|e| map_db_err(&e))?;
    Ok(rows
        .into_iter()
        .filter_map(|row| {
            row.page_index
                .map(|page_index| super::dto::ReadPageIndexDto {
                    comic_id: row.comic_id,
                    page_index,
                })
        })
        .collect())
}

pub async fn list_all_reading() -> Result<Vec<ReadingHistoryDto>, HentaiError> {
    let db = connection()?;
    let rows = ComicReadingHistories::find()
        .filter(not_trashed_history_expr())
        .filter(within_retention_expr(now_ms()))
        .order_by_desc(comic_reading_histories::Column::LastReadTime)
        .all(&db)
        .await
        .map_err(|e| map_db_err(&e))?;
    let items: Vec<ReadingHistoryDto> = rows.into_iter().map(map_reading_row).collect();
    enrich_page_counts(&db, items).await
}

/// Count reading-history rows in each local-calendar time section.
///
/// # Errors
///
/// Returns database errors when the aggregate query fails.
pub async fn fetch_reading_history_section_counts(
    keyword: Option<String>,
    client_timezone_offset_minutes: i32,
) -> Result<ReadingHistoryTimeSectionCountsDto, HentaiError> {
    let db = connection()?;
    let now = now_ms();
    let bounds = reading_history_section_bounds(now, client_timezone_offset_minutes);
    let cutoff = reading_history_retention_cutoff_ms(now);
    let not_trashed = comic_id_not_trashed_sql("comic_reading_histories.comic_id");

    let mut sql = format!(
        "SELECT \
            SUM(CASE WHEN last_read_time >= ? THEN 1 ELSE 0 END), \
            SUM(CASE WHEN last_read_time >= ? AND last_read_time < ? THEN 1 ELSE 0 END), \
            SUM(CASE WHEN last_read_time >= ? AND last_read_time < ? THEN 1 ELSE 0 END), \
            SUM(CASE WHEN last_read_time >= ? AND last_read_time < ? THEN 1 ELSE 0 END), \
            SUM(CASE WHEN last_read_time >= ? AND last_read_time < ? THEN 1 ELSE 0 END) \
         FROM comic_reading_histories \
         WHERE last_read_time >= ? AND ({not_trashed})"
    );
    let mut values: Vec<sea_orm::Value> = vec![
        bounds.today_start_ms.into(),
        bounds.yesterday_start_ms.into(),
        bounds.today_start_ms.into(),
        bounds.week_start_ms.into(),
        bounds.yesterday_start_ms.into(),
        bounds.month_start_ms.into(),
        bounds.week_start_ms.into(),
        cutoff.into(),
        bounds.month_start_ms.into(),
        cutoff.into(),
    ];

    let normalized = keyword
        .as_deref()
        .map(str::trim)
        .filter(|value| !value.is_empty());
    if let Some(keyword) = normalized {
        sql.push_str(" AND LOWER(title) LIKE ?");
        values.push(format!("%{}%", keyword.to_lowercase()).into());
    }

    let row = db
        .query_one(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            sql,
            values,
        ))
        .await
        .map_err(|e| map_db_err(&e))?;

    let Some(row) = row else {
        return Ok(ReadingHistoryTimeSectionCountsDto::default());
    };

    let read_i64 = |index: usize| -> Result<i64, HentaiError> {
        row.try_get_by_index::<Option<i64>>(index)
            .map(|v| v.unwrap_or(0))
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
    };

    Ok(ReadingHistoryTimeSectionCountsDto {
        today: read_i64(0)?,
        yesterday: read_i64(1)?,
        this_week: read_i64(2)?,
        this_month: read_i64(3)?,
        earlier: read_i64(4)?,
    })
}

pub async fn fetch_reading_page(
    request: crate::comic::PageRequestDto,
    keyword: Option<String>,
) -> Result<PagedReadingHistoryDto, HentaiError> {
    use crate::comic::pagination::paginate;

    let db = connection()?;
    let query = reading_history_list_query(keyword.as_deref());
    let paginator = query
        .order_by_desc(comic_reading_histories::Column::LastReadTime)
        .paginate(&db, crate::util::i32_to_u64(request.page_size.max(1)));
    let total_count =
        crate::util::u64_to_i64(paginator.num_items().await.map_err(|e| map_db_err(&e))?);
    let window = paginate(&request, total_count).clamped();
    if total_count <= 0 {
        return Ok(PagedReadingHistoryDto {
            items: vec![],
            total_count: 0,
            page: 1,
            page_size: window.page_size,
        });
    }
    let rows = paginator
        .fetch_page(crate::util::i32_to_u64(window.page).saturating_sub(1))
        .await
        .map_err(|e| map_db_err(&e))?;
    let items: Vec<ReadingHistoryDto> = rows.into_iter().map(map_reading_row).collect();
    let items = enrich_page_counts(&db, items).await?;
    Ok(PagedReadingHistoryDto {
        items,
        total_count,
        page: window.page,
        page_size: window.page_size,
    })
}

fn reading_history_list_query(keyword: Option<&str>) -> sea_orm::Select<ComicReadingHistories> {
    let mut query = ComicReadingHistories::find()
        .filter(not_trashed_history_expr())
        .filter(within_retention_expr(now_ms()));
    let normalized = keyword.map(str::trim).filter(|value| !value.is_empty());
    if let Some(keyword) = normalized {
        let pattern = format!("%{}%", keyword.to_lowercase());
        query = query.filter(
            Expr::expr(Func::lower(Expr::col(
                comic_reading_histories::Column::Title,
            )))
            .like(pattern),
        );
    }
    query
}

fn not_trashed_history_expr() -> sea_orm::sea_query::SimpleExpr {
    Expr::cust(comic_id_not_trashed_sql("comic_reading_histories.comic_id"))
}

pub async fn delete_reading_by_comic_id(comic_id: &str) -> Result<i32, HentaiError> {
    let db = connection()?;
    let res = ComicReadingHistories::delete_by_id(comic_id)
        .exec(&db)
        .await
        .map_err(|e| map_db_err(&e))?;
    crate::revision::notify_committed();
    Ok(crate::util::u64_to_i32(res.rows_affected))
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
        .map_err(|e| map_db_err(&e))?;
    crate::revision::notify_committed();
    Ok(crate::util::u64_to_i32(res.rows_affected))
}

pub async fn clear_all_reading() -> Result<i32, HentaiError> {
    with_library_write(clear_all_reading_locked).await
}

async fn clear_all_reading_locked() -> Result<i32, HentaiError> {
    let db = connection()?;
    let res = ComicReadingHistories::delete_many()
        .filter(not_trashed_history_expr())
        .exec(&db)
        .await
        .map_err(|e| map_db_err(&e))?;
    crate::revision::notify_committed();
    Ok(crate::util::u64_to_i32(res.rows_affected))
}

/// 库 revision 变更通知；不拉全表（Dart 侧自行分页或轻量 list）。
pub async fn watch_reading_history_changes(
    mut emit: impl FnMut(()) -> Result<(), HentaiError>,
) -> Result<(), HentaiError> {
    let mut changes = crate::revision::subscribe();
    while changes.changed().await.is_ok() {
        emit(())?;
    }
    Ok(())
}

fn map_reading_row(row: comic_reading_histories::Model) -> ReadingHistoryDto {
    ReadingHistoryDto {
        comic_id: row.comic_id,
        title: row.title,
        last_read_time_ms: row.last_read_time,
        page_index: row.page_index,
        page_count: None,
    }
}

async fn enrich_page_counts<C: ConnectionTrait>(
    db: &C,
    items: Vec<ReadingHistoryDto>,
) -> Result<Vec<ReadingHistoryDto>, HentaiError> {
    if items.is_empty() {
        return Ok(items);
    }
    let comic_ids: Vec<String> = items.iter().map(|item| item.comic_id.clone()).collect();
    let metas = ComicMeta::find()
        .filter(comic_meta::Column::ComicId.is_in(comic_ids))
        .all(db)
        .await
        .map_err(|e| map_db_err(&e))?;
    let counts: HashMap<String, i32> = metas
        .into_iter()
        .map(|meta| (meta.comic_id, meta.page_count))
        .collect();
    Ok(items
        .into_iter()
        .map(|mut item| {
            item.page_count = counts.get(&item.comic_id).copied();
            item
        })
        .collect())
}
