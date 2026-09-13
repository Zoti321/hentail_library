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

/// 单个成员在批量重排里的先验状态（ADR-0006 / #121）。
#[derive(Debug, Clone)]
struct ReorderMember {
    comic_id: String,
    sort_order: f64,
    locked: bool,
}

/// 锚点 + 夹缝插值：给定「新完整顺序」下各成员的先验 `(sort_order, locked)`，
/// 计算落库用的新 `sort_order` 序列，尽量保留已锁成员的原数值。
///
/// 规则（#121）：
/// - 从左到右贪心选锚点：已锁且其原 `sort_order` 严格大于「上一个已保留锚点」的成员保留原值；
/// - 未锁成员、以及会破坏严格递增的已锁成员，改由锚点间夹缝线性插值重算；
/// - 首锚点之前 / 末锚点之后按 1.0 步长外推；
/// - 若无任何锚点，退化为 1..n 顺序编号。
///
/// 返回值与输入等长、严格递增。调用方负责把本次所有成员一律置为 `locked=true`。
fn interpolate_reordered_values(members: &[ReorderMember]) -> Vec<f64> {
    let n = members.len();
    let mut result = vec![0.0_f64; n];

    let mut anchor_indices: Vec<usize> = Vec::new();
    let mut last_anchor_value = f64::NEG_INFINITY;
    for (i, member) in members.iter().enumerate() {
        if member.locked && member.sort_order.is_finite() && member.sort_order > last_anchor_value {
            anchor_indices.push(i);
            last_anchor_value = member.sort_order;
            result[i] = member.sort_order;
        }
    }

    if anchor_indices.is_empty() {
        for (i, slot) in result.iter_mut().enumerate() {
            *slot = (i + 1) as f64;
        }
        return result;
    }

    // 首锚点之前：向下外推，保持 < 首锚点值且严格递增。
    let first = anchor_indices[0];
    let first_value = members[first].sort_order;
    for j in 0..first {
        result[j] = first_value - (first - j) as f64;
    }

    // 相邻锚点之间：线性夹缝插值。
    for window in anchor_indices.windows(2) {
        let left = window[0];
        let right = window[1];
        let left_value = members[left].sort_order;
        let right_value = members[right].sort_order;
        let count = right - left - 1;
        if count > 0 {
            let step = (right_value - left_value) / (count as f64 + 1.0);
            for t in 1..=count {
                result[left + t] = left_value + step * t as f64;
            }
        }
    }

    // 末锚点之后：向上外推。
    let last = *anchor_indices.last().expect("anchor_indices non-empty");
    let last_value = members[last].sort_order;
    for t in 1..=(n - 1 - last) {
        result[last + t] = last_value + t as f64;
    }

    result
}

/// 批量按 `ordered_comic_ids` 重排系列成员（Series reorder mode 落库路径，#121）。
///
/// 语义：写入完整新序的 `sort_order`（锚点 + 夹缝插值，尽量保留已锁成员原值），
/// 并将本次提交的所有成员一律置为 `sort_order_locked = true`，
/// 使后续 Library sync 不再按文件名覆盖该顺序。整批在单事务内提交。
pub async fn set_series_items_order(
    series_id: &str,
    ordered_comic_ids: Vec<String>,
) -> Result<(), HentaiError> {
    let series_id = series_id.trim();
    if series_id.is_empty() {
        return Err(HentaiError::validation("系列标识无效".to_string()));
    }
    let db = connection()?;

    let existing_rows = SeriesItems::find()
        .filter(series_items::Column::SeriesId.eq(series_id))
        .all(&db)
        .await
        .map_err(map_db_err)?;
    let state: HashMap<String, (f64, bool)> = existing_rows
        .into_iter()
        .map(|row| (row.comic_id, (row.sort_order, row.sort_order_locked)))
        .collect();

    let mut seen = HashSet::new();
    let mut members: Vec<ReorderMember> = Vec::new();
    for comic_id in ordered_comic_ids {
        let comic_id = comic_id.trim().to_string();
        if comic_id.is_empty() || !seen.insert(comic_id.clone()) {
            continue;
        }
        let Some(&(sort_order, locked)) = state.get(&comic_id) else {
            continue;
        };
        members.push(ReorderMember {
            comic_id,
            sort_order,
            locked,
        });
    }

    if members.is_empty() {
        return Ok(());
    }

    let values = interpolate_reordered_values(&members);

    let txn = db.begin().await.map_err(map_db_err)?;
    for (member, value) in members.iter().zip(values) {
        SeriesItems::update_many()
            .col_expr(
                series_items::Column::SortOrder,
                sea_orm::sea_query::Expr::value(value),
            )
            .col_expr(
                series_items::Column::SortOrderLocked,
                sea_orm::sea_query::Expr::value(true),
            )
            .filter(series_items::Column::SeriesId.eq(series_id))
            .filter(series_items::Column::ComicId.eq(&member.comic_id))
            .exec(&txn)
            .await
            .map_err(map_db_err)?;
    }
    txn.commit().await.map_err(map_db_err)?;
    Ok(())
}

#[cfg(test)]
mod reorder_interpolation_tests {
    use super::{interpolate_reordered_values, ReorderMember};

    fn member(comic_id: &str, sort_order: f64, locked: bool) -> ReorderMember {
        ReorderMember {
            comic_id: comic_id.to_string(),
            sort_order,
            locked,
        }
    }

    fn assert_strictly_increasing(values: &[f64]) {
        for pair in values.windows(2) {
            assert!(
                pair[1] > pair[0],
                "expected strictly increasing, got {pair:?}"
            );
        }
    }

    #[test]
    fn all_unlocked_gets_baseline_numbering() {
        let members = vec![
            member("c1", 5.0, false),
            member("c2", 9.0, false),
            member("c3", 2.0, false),
        ];
        let values = interpolate_reordered_values(&members);
        assert_eq!(values, vec![1.0, 2.0, 3.0]);
    }

    #[test]
    fn keeps_locked_anchor_values_when_order_unchanged() {
        // c1 locked@1.0, c3 locked@3.0 stay; unlocked c2 interpolates between.
        let members = vec![
            member("c1", 1.0, true),
            member("c2", 7.0, false),
            member("c3", 3.0, true),
        ];
        let values = interpolate_reordered_values(&members);
        assert_eq!(values[0], 1.0);
        assert_eq!(values[2], 3.0);
        assert!(values[1] > 1.0 && values[1] < 3.0);
        assert_strictly_increasing(&values);
    }

    #[test]
    fn locked_relative_reorder_reassigns_incompatible_anchor() {
        // New order puts higher-valued locked member first; the second locked
        // member is incompatible and must be reassigned above it.
        let members = vec![member("b", 2.0, true), member("a", 1.0, true)];
        let values = interpolate_reordered_values(&members);
        assert_eq!(values[0], 2.0);
        assert!(values[1] > 2.0);
        assert_strictly_increasing(&values);
    }

    #[test]
    fn unlocked_before_first_anchor_extrapolates_below() {
        let members = vec![
            member("c1", 0.0, false),
            member("c2", 0.0, false),
            member("c3", 5.0, true),
        ];
        let values = interpolate_reordered_values(&members);
        assert_eq!(values[2], 5.0);
        assert!(values[0] < 5.0 && values[1] < 5.0);
        assert_strictly_increasing(&values);
    }
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
