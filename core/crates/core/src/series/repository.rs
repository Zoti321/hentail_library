use std::collections::{HashMap, HashSet};

use sea_orm::{
    ColumnTrait, ConnectionTrait, DatabaseConnection, EntityTrait, PaginatorTrait, QueryFilter,
    QueryOrder, Statement, TransactionTrait,
};

use crate::comic::{
    load_comics_ordered, read_data_version, search_comic_ids_by_tag_expression, ComicDto,
    PageRequestDto,
};
use crate::db::{connection, map_db_err};
use crate::entity::{prelude::*, series, series_items};
use crate::error::HentaiError;

use super::dto::{SeriesFilterDto, SeriesSortOptionDto};
use super::page_query::{build_count_query, build_ids_page_query};
use crate::comic_id::normalize_path_for_key;

#[derive(Debug, Clone)]
pub struct SeriesItemDto {
    pub series_id: String,
    pub comic_id: String,
    pub sort_order: f64,
    pub sort_order_locked: bool,
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SeriesMetaLocks {
    pub name: bool,
    pub serialization_status: bool,
    pub total_count: bool,
}

#[derive(Debug, Clone)]
pub struct SeriesDto {
    pub series_id: String,
    pub folder_path: String,
    pub name: String,
    pub serialization_status: String,
    pub total_count: Option<i32>,
    pub locks: SeriesMetaLocks,
    pub items: Vec<SeriesItemDto>,
}

#[derive(Debug, Clone)]
pub struct PagedSeriesResultDto {
    pub items: Vec<SeriesDto>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SeriesComicsMetadataDto {
    pub authors: Vec<String>,
    pub tags: Vec<String>,
    pub has_r18: bool,
    /// Member order + first-seen dedupe (flattened across member Language lists).
    pub languages: Vec<String>,
    /// Member order + first-seen dedupe (within each member: alphabetical like Comic DTO).
    pub parodies: Vec<String>,
    /// Member order + first-seen dedupe (within each member: alphabetical like Comic DTO).
    pub characters: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct SeriesComicPageItemDto {
    pub comic: ComicDto,
    pub sort_order: f64,
    pub sort_order_locked: bool,
}

#[derive(Debug, Clone)]
pub struct PagedSeriesComicsResultDto {
    pub items: Vec<SeriesComicPageItemDto>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

/// 由 comicId 派生的阅读器用系列上下文（ADR-0005）。
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SeriesReadingContextDto {
    pub series_id: String,
    pub series_name: String,
    pub ordered_comic_ids: Vec<String>,
    pub current_index: i32,
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
    let mut filter = filter.normalized();
    filter.library_id = crate::library::resolve_browse_library_id(filter.library_id).await?;
    if filter.library_id.is_none() {
        return Ok(PagedSeriesResultDto {
            items: vec![],
            total_count: 0,
            page: 1,
            page_size: request.page_size.max(1),
        });
    }
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
    let prefer_root_folder_path = resolve_prefer_root_folder_path(&filter).await?;
    let ids_query = build_ids_page_query(
        &filter,
        &sort,
        prefer_root_folder_path.as_deref(),
        page_size,
        offset,
    );
    let series_ids = query_series_ids(&db, &ids_query).await?;
    let items = load_series_by_ids(&db, series_ids).await?;
    Ok(PagedSeriesResultDto {
        items,
        total_count,
        page: effective_page,
        page_size,
    })
}

async fn resolve_prefer_root_folder_path(
    filter: &SeriesFilterDto,
) -> Result<Option<String>, HentaiError> {
    if !filter.prefer_library_root_series {
        return Ok(None);
    }
    let Some(library_id) = filter.library_id.as_deref() else {
        return Ok(None);
    };
    let Some(library) = crate::library::find_library_by_id(library_id).await? else {
        return Ok(None);
    };
    Ok(Some(normalize_path_for_key(&library.root_path)))
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

pub async fn fetch_series_comics_page(
    series_id: &str,
    request: PageRequestDto,
) -> Result<PagedSeriesComicsResultDto, HentaiError> {
    let db = connection()?;
    if !series_exists(&db, series_id).await? {
        return Ok(PagedSeriesComicsResultDto {
            items: vec![],
            total_count: 0,
            page: 1,
            page_size: request.page_size.max(1),
        });
    }
    let page_size = request.page_size.max(1);
    let total_count = count_series_items(&db, series_id).await?;
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
        return Ok(PagedSeriesComicsResultDto {
            items: vec![],
            total_count: 0,
            page: 1,
            page_size,
        });
    }
    let offset = (effective_page - 1) * page_size;
    let id_orders =
        query_series_comic_id_orders_page(&db, series_id, page_size, offset).await?;
    let comic_ids: Vec<String> = id_orders.iter().map(|(id, _, _)| id.clone()).collect();
    let order_by_id: HashMap<String, (f64, bool)> = id_orders
        .into_iter()
        .map(|(id, sort_order, locked)| (id, (sort_order, locked)))
        .collect();
    let comics = load_comics_ordered(&db, comic_ids).await?;
    let items = comics
        .into_iter()
        .map(|comic| {
            let (sort_order, sort_order_locked) = order_by_id
                .get(&comic.comic_id)
                .copied()
                .unwrap_or((0.0, false));
            SeriesComicPageItemDto {
                comic,
                sort_order,
                sort_order_locked,
            }
        })
        .collect();
    Ok(PagedSeriesComicsResultDto {
        items,
        total_count,
        page: effective_page,
        page_size,
    })
}

pub async fn fetch_series_comics_metadata(
    series_id: &str,
) -> Result<SeriesComicsMetadataDto, HentaiError> {
    let db = connection()?;
    if !series_exists(&db, series_id).await? {
        return Ok(SeriesComicsMetadataDto::default());
    }
    let (languages, parodies, characters) =
        query_series_language_parody_character(&db, series_id).await?;
    Ok(SeriesComicsMetadataDto {
        authors: query_series_author_names(&db, series_id).await?,
        tags: query_series_tag_names(&db, series_id).await?,
        has_r18: query_series_has_r18(&db, series_id).await?,
        languages,
        parodies,
        characters,
    })
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

pub async fn get_series_reading_context_by_comic_id(
    comic_id: &str,
) -> Result<Option<SeriesReadingContextDto>, HentaiError> {
    let comic_id = comic_id.trim();
    if comic_id.is_empty() {
        return Ok(None);
    }
    let db = connection()?;
    let membership = SeriesItems::find()
        .filter(series_items::Column::ComicId.eq(comic_id))
        .one(&db)
        .await
        .map_err(map_db_err)?;
    let Some(membership) = membership else {
        return Ok(None);
    };
    let series = Series::find_by_id(membership.series_id.clone())
        .one(&db)
        .await
        .map_err(map_db_err)?;
    let Some(series) = series else {
        return Ok(None);
    };
    let ordered_comic_ids = query_all_series_comic_ids(&db, &series.series_id).await?;
    let current_index = ordered_comic_ids
        .iter()
        .position(|id| id == comic_id)
        .map(|i| i as i32)
        .unwrap_or(0);
    Ok(Some(SeriesReadingContextDto {
        series_id: series.series_id,
        series_name: series.name,
        ordered_comic_ids,
        current_index,
    }))
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
                sea_orm::sea_query::Expr::value(index as f64),
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
    let Some(library_id) = crate::library::resolve_browse_library_id(None).await? else {
        return Ok(vec![]);
    };
    let db = connection()?;
    let stmt = Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "SELECT series_id FROM series \
         WHERE library_id = ? AND (lower(name) LIKE ? OR lower(folder_path) LIKE ?)",
        vec![
            sea_orm::Value::String(Some(Box::new(library_id))),
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

async fn series_exists(db: &DatabaseConnection, series_id: &str) -> Result<bool, HentaiError> {
    Series::find_by_id(series_id)
        .one(db)
        .await
        .map_err(map_db_err)
        .map(|row| row.is_some())
}

async fn count_series_items(
    db: &DatabaseConnection,
    series_id: &str,
) -> Result<i64, HentaiError> {
    let stmt = Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "SELECT COUNT(*) FROM series_items WHERE series_id = ?",
        vec![sea_orm::Value::String(Some(Box::new(series_id.to_string())))],
    );
    let row = db
        .query_one(stmt)
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::db_query_failed("series item count 无结果", None))?;
    row.try_get_by_index::<i64>(0)
        .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
}

async fn query_all_series_comic_ids(
    db: &DatabaseConnection,
    series_id: &str,
) -> Result<Vec<String>, HentaiError> {
    let stmt = Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "SELECT comic_id FROM series_items \
         WHERE series_id = ? \
         ORDER BY sort_order ASC, comic_id ASC",
        vec![sea_orm::Value::String(Some(Box::new(series_id.to_string())))],
    );
    let rows = db.query_all(stmt).await.map_err(map_db_err)?;
    rows.into_iter()
        .map(|row| {
            row.try_get_by_index::<String>(0)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
        })
        .collect()
}

async fn query_series_comic_id_orders_page(
    db: &DatabaseConnection,
    series_id: &str,
    page_size: i32,
    offset: i32,
) -> Result<Vec<(String, f64, bool)>, HentaiError> {
    let stmt = Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "SELECT comic_id, sort_order, sort_order_locked FROM series_items \
         WHERE series_id = ? \
         ORDER BY sort_order ASC, comic_id ASC \
         LIMIT ? OFFSET ?",
        vec![
            sea_orm::Value::String(Some(Box::new(series_id.to_string()))),
            sea_orm::Value::Int(Some(page_size)),
            sea_orm::Value::Int(Some(offset)),
        ],
    );
    let rows = db.query_all(stmt).await.map_err(map_db_err)?;
    rows.into_iter()
        .map(|row| {
            let comic_id = row
                .try_get_by_index::<String>(0)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
            let sort_order = row
                .try_get_by_index::<f64>(1)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
            let locked_i64 = row
                .try_get_by_index::<i64>(2)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
            Ok((comic_id, sort_order, locked_i64 != 0))
        })
        .collect()
}

/// Walk Series members in `sort_order` / `comic_id` order; flatten Language / Parody /
/// Character lists with first-seen dedupe (US-21 / #75).
async fn query_series_language_parody_character(
    db: &DatabaseConnection,
    series_id: &str,
) -> Result<(Vec<String>, Vec<String>, Vec<String>), HentaiError> {
    let comic_ids = query_all_series_comic_ids(db, series_id).await?;
    if comic_ids.is_empty() {
        return Ok((vec![], vec![], vec![]));
    }
    let comics = load_comics_ordered(db, comic_ids).await?;
    let mut languages = Vec::new();
    let mut parodies = Vec::new();
    let mut characters = Vec::new();
    let mut seen_languages = HashSet::new();
    let mut seen_parodies = HashSet::new();
    let mut seen_characters = HashSet::new();
    for comic in comics {
        append_first_seen(&mut languages, &mut seen_languages, &comic.languages);
        append_first_seen(&mut parodies, &mut seen_parodies, &comic.parodies);
        append_first_seen(&mut characters, &mut seen_characters, &comic.characters);
    }
    Ok((languages, parodies, characters))
}

fn append_first_seen(out: &mut Vec<String>, seen: &mut HashSet<String>, values: &[String]) {
    for value in values {
        if seen.insert(value.clone()) {
            out.push(value.clone());
        }
    }
}

async fn query_series_author_names(
    db: &DatabaseConnection,
    series_id: &str,
) -> Result<Vec<String>, HentaiError> {
    let stmt = Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "SELECT DISTINCT ca.author_name \
         FROM series_items si \
         INNER JOIN comic_authors ca ON ca.comic_id = si.comic_id \
         WHERE si.series_id = ? \
         ORDER BY ca.author_name ASC",
        vec![sea_orm::Value::String(Some(Box::new(series_id.to_string())))],
    );
    query_string_column(db, stmt).await
}

async fn query_series_tag_names(
    db: &DatabaseConnection,
    series_id: &str,
) -> Result<Vec<String>, HentaiError> {
    let stmt = Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "SELECT DISTINCT ct.tag_name \
         FROM series_items si \
         INNER JOIN comic_tags ct ON ct.comic_id = si.comic_id \
         WHERE si.series_id = ? \
         ORDER BY ct.tag_name ASC",
        vec![sea_orm::Value::String(Some(Box::new(series_id.to_string())))],
    );
    query_string_column(db, stmt).await
}

async fn query_series_has_r18(
    db: &DatabaseConnection,
    series_id: &str,
) -> Result<bool, HentaiError> {
    let stmt = Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "SELECT EXISTS( \
           SELECT 1 \
           FROM series_items si \
           INNER JOIN comic_meta cm ON cm.comic_id = si.comic_id \
           WHERE si.series_id = ? AND cm.content_rating = 'r18' \
         )",
        vec![sea_orm::Value::String(Some(Box::new(series_id.to_string())))],
    );
    let row = db
        .query_one(stmt)
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::db_query_failed("series has_r18 无结果", None))?;
    row.try_get_by_index::<i64>(0)
        .map(|value| value != 0)
        .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
}

async fn query_string_column(
    db: &DatabaseConnection,
    stmt: Statement,
) -> Result<Vec<String>, HentaiError> {
    let rows = db.query_all(stmt).await.map_err(map_db_err)?;
    rows.into_iter()
        .map(|row| {
            row.try_get_by_index::<String>(0)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
        })
        .collect()
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
                sort_order_locked: item.sort_order_locked,
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
                locks: SeriesMetaLocks {
                    name: row.name_locked,
                    serialization_status: row.serialization_status_locked,
                    total_count: row.total_count_locked,
                },
                items: items_by_series
                    .remove(&row.series_id)
                    .unwrap_or_default(),
            },
        );
    }
    Ok(ids
        .into_iter()
        .filter_map(|id| by_id.remove(&id))
        .collect())
}

pub async fn load_home_series_comic_order_map() -> Result<HashMap<String, f64>, HentaiError> {
    let db = connection()?;
    let rows = SeriesItems::find().all(&db).await.map_err(map_db_err)?;
    let mut map = HashMap::new();
    for row in rows {
        map.insert(format!("{}|{}", row.series_id, row.comic_id), row.sort_order);
    }
    Ok(map)
}

pub async fn watch_home_series_comic_order_map(
    mut emit: impl FnMut(HashMap<String, f64>) -> Result<(), HentaiError>,
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
