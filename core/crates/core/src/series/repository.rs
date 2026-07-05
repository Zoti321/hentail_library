use std::collections::HashMap;

use sea_orm::{
    ColumnTrait, ConnectionTrait, DatabaseConnection, EntityTrait, PaginatorTrait, QueryFilter,
    QueryOrder, Set, Statement, TransactionTrait,
};

use crate::comic::{read_data_version, search_comic_ids_by_tag_expression, PageRequestDto};
use crate::db::{connection, map_db_err};
use crate::entity::{prelude::*, series, series_items};
use crate::error::HentaiError;

use super::dto::{SeriesFilterDto, SeriesSortOptionDto};
use super::page_query::{build_count_query, build_ids_page_query};

#[derive(Debug, Clone)]
pub struct SeriesItemDto {
    pub series_id: String,
    pub comic_id: String,
    pub sort_order: i32,
}

#[derive(Debug, Clone)]
pub struct SeriesDto {
    pub series_id: String,
    pub folder_path: String,
    pub name: String,
    pub serialization_status: String,
    pub total_count: Option<i32>,
    pub items: Vec<SeriesItemDto>,
}

#[derive(Debug, Clone)]
pub struct PagedSeriesResultDto {
    pub items: Vec<SeriesDto>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

pub async fn watch_all_series(
    mut emit: impl FnMut(Vec<SeriesDto>) -> Result<(), HentaiError>,
) -> Result<(), HentaiError> {
    let mut last = read_data_version().await?;
    emit(get_all_series().await?)?;
    loop {
        tokio::time::sleep(std::time::Duration::from_millis(400)).await;
        let version = read_data_version().await?;
        if version != last {
            last = version;
            emit(get_all_series().await?)?;
        }
    }
}

pub async fn get_all_series() -> Result<Vec<SeriesDto>, HentaiError> {
    let db = connection()?;
    load_all_series(&db).await
}

pub async fn count_all_series() -> Result<i64, HentaiError> {
    let db = connection()?;
    Series::find()
        .count(&db)
        .await
        .map_err(map_db_err)
        .map(|c| c as i64)
}

pub async fn fetch_series_page(
    request: PageRequestDto,
    filter: SeriesFilterDto,
    sort: SeriesSortOptionDto,
) -> Result<PagedSeriesResultDto, HentaiError> {
    let db = connection()?;
    let filter = filter.normalized();
    let page_size = request.page_size.max(1);
    let total_count = count_filtered_series(&db, &filter).await?;
    let total_pages = if total_count <= 0 {
        0
    } else {
        (total_count + page_size as i64 - 1) / page_size as i64
    };
    let mut effective_page = request.page.max(1);
    if total_pages > 0 && effective_page as i64 > total_pages {
        effective_page = total_pages as i32;
    }
    if total_count <= 0 {
        return Ok(PagedSeriesResultDto {
            items: vec![],
            total_count: 0,
            page: 1,
            page_size,
        });
    }
    let offset = (effective_page - 1) * page_size;
    let ids_query = build_ids_page_query(&filter, sort.descending, page_size, offset);
    let series_ids = query_series_ids(&db, &ids_query).await?;
    let items = load_series_by_ids(&db, series_ids).await?;
    Ok(PagedSeriesResultDto {
        items,
        total_count,
        page: effective_page,
        page_size,
    })
}

async fn count_filtered_series(
    db: &DatabaseConnection,
    filter: &SeriesFilterDto,
) -> Result<i64, HentaiError> {
    let query = build_count_query(filter);
    let stmt = Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        query.sql,
        query.values,
    );
    let row = db
        .query_one(stmt)
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::db_query_failed("series count 无结果", None))?;
    row.try_get_by_index::<i64>(0)
        .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
}

async fn query_series_ids(
    db: &DatabaseConnection,
    query: &super::page_query::PageSqlQuery,
) -> Result<Vec<String>, HentaiError> {
    let stmt = Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        query.sql.clone(),
        query.values.clone(),
    );
    let rows = db.query_all(stmt).await.map_err(map_db_err)?;
    rows.into_iter()
        .map(|row| {
            row.try_get_by_index::<String>(0)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
        })
        .collect()
}

pub async fn find_series_by_id(series_id: &str) -> Result<Option<SeriesDto>, HentaiError> {
    let db = connection()?;
    let exists = Series::find_by_id(series_id)
        .one(&db)
        .await
        .map_err(map_db_err)?;
    if exists.is_none() {
        return Ok(None);
    }
    let mut list = load_series_by_ids(&db, vec![series_id.to_string()]).await?;
    Ok(list.pop())
}

pub async fn set_series_items_order(
    series_id: &str,
    ordered_comic_ids: Vec<String>,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let txn = db.begin().await.map_err(map_db_err)?;
    for (index, comic_id) in ordered_comic_ids.iter().enumerate() {
        SeriesItems::update_many()
            .col_expr(
                series_items::Column::SortOrder,
                sea_orm::sea_query::Expr::value(index as i32),
            )
            .filter(series_items::Column::SeriesId.eq(series_id))
            .filter(series_items::Column::ComicId.eq(comic_id))
            .exec(&txn)
            .await
            .map_err(map_db_err)?;
    }
    txn.commit().await.map_err(map_db_err)?;
    Ok(())
}

pub async fn search_series_by_keyword(keyword: &str) -> Result<Vec<SeriesDto>, HentaiError> {
    let q = keyword.trim().to_lowercase();
    if q.is_empty() {
        return Ok(vec![]);
    }
    let db = connection()?;
    let stmt = Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "SELECT series_id FROM series WHERE lower(name) LIKE ? OR lower(folder_path) LIKE ?",
        vec![
            sea_orm::Value::String(Some(Box::new(format!("%{q}%")))),
            sea_orm::Value::String(Some(Box::new(format!("%{q}%")))),
        ],
    );
    let rows = db.query_all(stmt).await.map_err(map_db_err)?;
    let ids: Vec<String> = rows
        .into_iter()
        .filter_map(|row| row.try_get_by_index::<String>(0).ok())
        .collect();
    load_series_by_ids(&db, ids).await
}

pub async fn search_series_by_tag_expression(
    must_include: Vec<String>,
    optional_or: Vec<String>,
    must_exclude: Vec<String>,
) -> Result<Vec<SeriesDto>, HentaiError> {
    let comic_ids =
        search_comic_ids_by_tag_expression(must_include, optional_or, must_exclude).await?;
    if comic_ids.is_empty() {
        return Ok(vec![]);
    }
    let db = connection()?;
    let rows = SeriesItems::find()
        .filter(series_items::Column::ComicId.is_in(comic_ids))
        .all(&db)
        .await
        .map_err(map_db_err)?;
    let mut ids = std::collections::BTreeSet::new();
    for row in rows {
        ids.insert(row.series_id);
    }
    load_series_by_ids(&db, ids.into_iter().collect()).await
}

async fn load_all_series(db: &DatabaseConnection) -> Result<Vec<SeriesDto>, HentaiError> {
    let rows = Series::find()
        .order_by_asc(series::Column::Name)
        .all(db)
        .await
        .map_err(map_db_err)?;
    let ids: Vec<String> = rows.into_iter().map(|r| r.series_id).collect();
    load_series_by_ids(db, ids).await
}

async fn load_series_by_ids(
    db: &DatabaseConnection,
    ids: Vec<String>,
) -> Result<Vec<SeriesDto>, HentaiError> {
    if ids.is_empty() {
        return Ok(vec![]);
    }
    let series_rows = Series::find()
        .filter(series::Column::SeriesId.is_in(ids.clone()))
        .all(db)
        .await
        .map_err(map_db_err)?;
    let item_rows = SeriesItems::find()
        .filter(series_items::Column::SeriesId.is_in(ids.clone()))
        .order_by_asc(series_items::Column::SeriesId)
        .order_by_asc(series_items::Column::SortOrder)
        .all(db)
        .await
        .map_err(map_db_err)?;
    let mut items_by_series: HashMap<String, Vec<SeriesItemDto>> = HashMap::new();
    for item in item_rows {
        items_by_series
            .entry(item.series_id.clone())
            .or_default()
            .push(SeriesItemDto {
                series_id: item.series_id,
                comic_id: item.comic_id,
                sort_order: item.sort_order,
            });
    }
    let mut by_id: HashMap<String, SeriesDto> = HashMap::new();
    for row in series_rows {
        let series_id = row.series_id.clone();
        by_id.insert(
            series_id.clone(),
            SeriesDto {
                series_id,
                folder_path: row.folder_path,
                name: row.name,
                serialization_status: row.serialization_status,
                total_count: row.total_count,
                items: items_by_series.remove(&row.series_id).unwrap_or_default(),
            },
        );
    }
    Ok(ids
        .into_iter()
        .filter_map(|id| by_id.remove(&id))
        .collect())
}

pub async fn load_home_series_comic_order_map() -> Result<HashMap<String, i32>, HentaiError> {
    let db = connection()?;
    let rows = SeriesItems::find().all(&db).await.map_err(map_db_err)?;
    let mut map = HashMap::new();
    for row in rows {
        map.insert(format!("{}|{}", row.series_id, row.comic_id), row.sort_order);
    }
    Ok(map)
}

pub async fn watch_home_series_comic_order_map(
    mut emit: impl FnMut(HashMap<String, i32>) -> Result<(), HentaiError>,
) -> Result<(), HentaiError> {
    let mut last = read_data_version().await?;
    emit(load_home_series_comic_order_map().await?)?;
    loop {
        tokio::time::sleep(std::time::Duration::from_millis(400)).await;
        let version = read_data_version().await?;
        if version != last {
            last = version;
            emit(load_home_series_comic_order_map().await?)?;
        }
    }
}
