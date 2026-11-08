use std::collections::HashMap;

use sea_orm::sea_query::Expr;
use sea_orm::{
    ColumnTrait, ConnectionTrait, DatabaseConnection, EntityTrait, QueryFilter, QueryOrder,
    Statement, Value,
};

use crate::db::{connection, map_db_err, version_connection};
use crate::entity::{
    comic_characters, comic_meta, comic_parodies, comic_reading_histories, comic_tags, comics,
    prelude::*,
};
use crate::error::HentaiError;
use crate::history::reading_history_retention_cutoff_ms;

use super::dto::{
    now_ms, ComicBrowseItemDto, ComicDto, ComicFilterDto, ComicSortOptionDto, PageRequestDto,
    PagedComicBrowseResultDto, PagedComicResultDto,
};
use super::filter_predicate;
use super::grouping::ComicGrouping;
use super::page_query::{build_count_query, build_ids_page_query};
use super::pagination::paginate;
use super::visibility::visible_comic_sql;
use crate::metadata_lock::normalize_tag_expression_tokens;

pub async fn count_all() -> Result<i64, HentaiError> {
    let db = connection()?;
    let row = db
        .query_one(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "SELECT COUNT(*) AS c FROM comics c WHERE {}",
                visible_comic_sql("c")
            ),
        ))
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::db_query_failed("count_all 无结果", None))?;
    row.try_get_by_index::<i64>(0)
        .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
}

pub async fn fetch_comics_page(
    request: PageRequestDto,
    filter: ComicFilterDto,
    grouping: ComicGrouping,
    sort: ComicSortOptionDto,
) -> Result<PagedComicResultDto, HentaiError> {
    let page = fetch_comics_page_ids(request, filter, grouping, sort).await?;
    let db = connection()?;
    let items = load_comics_ordered(&db, page.comic_ids).await?;
    Ok(PagedComicResultDto {
        items,
        total_count: page.total_count,
        page: page.page,
        page_size: page.page_size,
    })
}

/// 库浏览列表：只返回卡面字段，跳过 authors/tags 等关系加载。
pub async fn fetch_comics_browse_page(
    request: PageRequestDto,
    filter: ComicFilterDto,
    grouping: ComicGrouping,
    sort: ComicSortOptionDto,
) -> Result<PagedComicBrowseResultDto, HentaiError> {
    let page = fetch_comics_page_ids(request, filter, grouping, sort).await?;
    let db = connection()?;
    let items = load_comics_browse_ordered(&db, page.comic_ids).await?;
    Ok(PagedComicBrowseResultDto {
        items,
        total_count: page.total_count,
        page: page.page,
        page_size: page.page_size,
    })
}

struct ComicsPageIds {
    comic_ids: Vec<String>,
    total_count: i64,
    page: i32,
    page_size: i32,
}

async fn fetch_comics_page_ids(
    request: PageRequestDto,
    filter: ComicFilterDto,
    grouping: ComicGrouping,
    sort: ComicSortOptionDto,
) -> Result<ComicsPageIds, HentaiError> {
    let db = connection()?;
    let mut filter = filter.normalized();
    filter.library_id = crate::library::resolve_browse_library_id(filter.library_id).await?;
    if filter.library_id.is_none() {
        return Ok(ComicsPageIds {
            comic_ids: vec![],
            total_count: 0,
            page: 1,
            page_size: request.page_size.max(1),
        });
    }
    let total_count = count_filtered(&db, &filter).await?;
    let window = paginate(request, total_count).clamped();
    if total_count <= 0 {
        return Ok(ComicsPageIds {
            comic_ids: vec![],
            total_count: 0,
            page: 1,
            page_size: window.page_size,
        });
    }
    let library_root_path = resolve_library_root_path(&filter, grouping).await?;
    let ids_query = build_ids_page_query(
        &filter,
        &sort,
        grouping,
        library_root_path.as_deref(),
        window.page_size,
        window.offset as i32,
    );
    let comic_ids = query_string_ids(&db, &ids_query).await?;
    Ok(ComicsPageIds {
        comic_ids,
        total_count,
        page: window.page,
        page_size: window.page_size,
    })
}

async fn resolve_library_root_path(
    filter: &ComicFilterDto,
    grouping: ComicGrouping,
) -> Result<Option<String>, HentaiError> {
    if !grouping.needs_library_root() {
        return Ok(None);
    }
    let Some(library_id) = filter.library_id.as_deref() else {
        return Ok(None);
    };
    let Some(library) = crate::library::find_library_by_id(library_id).await? else {
        return Ok(None);
    };
    Ok(Some(crate::comic_id::normalize_path_for_key(
        &library.root_path,
    )))
}

pub async fn find_comic_by_id(comic_id: &str) -> Result<Option<ComicDto>, HentaiError> {
    let db = connection()?;
    let comics = load_comics_ordered(&db, vec![comic_id.to_string()]).await?;
    Ok(comics.into_iter().next())
}

/// Load full Comic records for the given ids, preserving request order among found rows.
/// Missing ids are omitted (callers keep truncated-id title fallbacks).
pub async fn find_comics_by_ids(comic_ids: Vec<String>) -> Result<Vec<ComicDto>, HentaiError> {
    if comic_ids.is_empty() {
        return Ok(vec![]);
    }
    let db = connection()?;
    load_comics_ordered(&db, comic_ids).await
}

pub async fn search_by_keyword(
    keyword: &str,
    library_id: Option<String>,
) -> Result<Vec<ComicDto>, HentaiError> {
    let page = search_by_keyword_page(
        keyword,
        PageRequestDto {
            page: 1,
            page_size: i32::MAX,
        },
        library_id,
    )
    .await?;
    Ok(page.items)
}

pub async fn search_by_keyword_page(
    keyword: &str,
    request: PageRequestDto,
    library_id: Option<String>,
) -> Result<PagedComicResultDto, HentaiError> {
    let q = keyword.trim().to_lowercase();
    if q.is_empty() {
        let window = paginate(request, 0);
        return Ok(PagedComicResultDto {
            items: vec![],
            total_count: 0,
            page: window.page,
            page_size: window.page_size,
        });
    }
    let Some(library_id) = crate::library::resolve_browse_library_id(library_id).await? else {
        let window = paginate(request, 0);
        return Ok(PagedComicResultDto {
            items: vec![],
            total_count: 0,
            page: window.page,
            page_size: window.page_size,
        });
    };
    let db = connection()?;
    let count_stmt = Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!(
            "SELECT COUNT(*) FROM comics c \
             INNER JOIN comic_meta m ON m.comic_id = c.comic_id \
             WHERE c.library_id = ? AND {} AND lower(m.title) LIKE ?",
            visible_comic_sql("c")
        ),
        vec![
            Value::String(Some(Box::new(library_id.clone()))),
            Value::String(Some(Box::new(format!("%{q}%")))),
        ],
    );
    let total_count = db
        .query_one(count_stmt)
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::db_query_failed("search count 无结果", None))?
        .try_get_by_index::<i64>(0)
        .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
    // 越界页保持原样：本路径是顺序翻页（由 `has_next` 驱动），不钳到末页。
    let window = paginate(request, total_count);
    let offset = window.offset;
    let page = window.page;
    let page_size = window.page_size;
    let ids_stmt = Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!(
            "SELECT c.comic_id FROM comics c \
             INNER JOIN comic_meta m ON m.comic_id = c.comic_id \
             WHERE c.library_id = ? AND {} AND lower(m.title) LIKE ? \
             ORDER BY lower(m.title) ASC \
             LIMIT ? OFFSET ?",
            visible_comic_sql("c")
        ),
        vec![
            Value::String(Some(Box::new(library_id))),
            Value::String(Some(Box::new(format!("%{q}%")))),
            Value::BigInt(Some(page_size as i64)),
            Value::BigInt(Some(offset)),
        ],
    );
    let comic_ids = query_ids_from_stmt(&db, ids_stmt).await?;
    let items = load_comics_ordered(&db, comic_ids).await?;
    Ok(PagedComicResultDto {
        items,
        total_count,
        page,
        page_size,
    })
}

struct MetadataExpressionTerms {
    library_id: String,
    must_include: Vec<String>,
    optional_or: Vec<String>,
    must_exclude: Vec<String>,
}

async fn resolve_metadata_expression_terms(
    must_include: Vec<String>,
    optional_or: Vec<String>,
    must_exclude: Vec<String>,
    library_id: Option<String>,
) -> Result<Option<MetadataExpressionTerms>, HentaiError> {
    let must_include = normalize_tag_expression_tokens(&must_include);
    let optional_or = normalize_tag_expression_tokens(&optional_or);
    let must_exclude = normalize_tag_expression_tokens(&must_exclude);
    if must_include.is_empty() && optional_or.is_empty() && must_exclude.is_empty() {
        return Ok(None);
    }
    let Some(library_id) = crate::library::resolve_browse_library_id(library_id).await? else {
        return Ok(None);
    };
    Ok(Some(MetadataExpressionTerms {
        library_id,
        must_include,
        optional_or,
        must_exclude,
    }))
}

fn append_metadata_expression_from(
    sql: &mut String,
    values: &mut Vec<Value>,
    terms: &MetadataExpressionTerms,
) {
    sql.push_str(
        " FROM comics c INNER JOIN comic_meta m ON m.comic_id = c.comic_id \
         WHERE c.library_id = ? AND ",
    );
    values.push(Value::String(Some(Box::new(terms.library_id.clone()))));
    sql.push_str(&visible_comic_sql("c"));
    filter_predicate::append_metadata_expression_predicates(
        sql,
        values,
        &terms.must_include,
        &terms.optional_or,
        &terms.must_exclude,
    );
}

async fn count_metadata_expression_comics(
    db: &DatabaseConnection,
    terms: &MetadataExpressionTerms,
) -> Result<i64, HentaiError> {
    let mut sql = String::from("SELECT COUNT(*)");
    let mut values = Vec::new();
    append_metadata_expression_from(&mut sql, &mut values, terms);
    let row = db
        .query_one(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            sql,
            values,
        ))
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::db_query_failed("metadata expression count 无结果", None))?;
    row.try_get_by_index::<i64>(0)
        .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
}

async fn query_metadata_expression_comic_ids(
    db: &DatabaseConnection,
    terms: &MetadataExpressionTerms,
    limit: Option<i64>,
    offset: i64,
) -> Result<Vec<String>, HentaiError> {
    let mut sql = String::from("SELECT c.comic_id");
    let mut values = Vec::new();
    append_metadata_expression_from(&mut sql, &mut values, terms);
    sql.push_str(" ORDER BY lower(m.title) ASC");
    if let Some(limit) = limit {
        sql.push_str(" LIMIT ? OFFSET ?");
        values.push(Value::BigInt(Some(limit)));
        values.push(Value::BigInt(Some(offset)));
    }
    query_ids_from_stmt(
        db,
        Statement::from_sql_and_values(sea_orm::DatabaseBackend::Sqlite, sql, values),
    )
    .await
}

pub async fn search_comic_ids_by_tag_expression(
    must_include: Vec<String>,
    optional_or: Vec<String>,
    must_exclude: Vec<String>,
    library_id: Option<String>,
) -> Result<Vec<String>, HentaiError> {
    let Some(terms) =
        resolve_metadata_expression_terms(must_include, optional_or, must_exclude, library_id)
            .await?
    else {
        return Ok(vec![]);
    };
    let db = connection()?;
    query_metadata_expression_comic_ids(&db, &terms, None, 0).await
}

pub async fn search_by_tag_expression(
    must_include: Vec<String>,
    optional_or: Vec<String>,
    must_exclude: Vec<String>,
    library_id: Option<String>,
) -> Result<Vec<ComicDto>, HentaiError> {
    let page = search_by_tag_expression_page(
        must_include,
        optional_or,
        must_exclude,
        PageRequestDto {
            page: 1,
            page_size: i32::MAX,
        },
        library_id,
    )
    .await?;
    Ok(page.items)
}

pub async fn search_by_tag_expression_page(
    must_include: Vec<String>,
    optional_or: Vec<String>,
    must_exclude: Vec<String>,
    request: PageRequestDto,
    library_id: Option<String>,
) -> Result<PagedComicResultDto, HentaiError> {
    let Some(terms) =
        resolve_metadata_expression_terms(must_include, optional_or, must_exclude, library_id)
            .await?
    else {
        let window = paginate(request, 0);
        return Ok(PagedComicResultDto {
            items: vec![],
            total_count: 0,
            page: window.page,
            page_size: window.page_size,
        });
    };
    let db = connection()?;
    let total_count = count_metadata_expression_comics(&db, &terms).await?;
    if total_count <= 0 {
        let window = paginate(request, 0);
        return Ok(PagedComicResultDto {
            items: vec![],
            total_count: 0,
            page: window.page,
            page_size: window.page_size,
        });
    }
    // 越界页保持原样，只把窗口按总行数截断（与关键字搜索同属顺序翻页路径）。
    let window = paginate(request, total_count);
    let comic_ids = query_metadata_expression_comic_ids(
        &db,
        &terms,
        Some(window.page_size as i64),
        window.offset,
    )
    .await?;
    let items = load_comics_ordered(&db, comic_ids).await?;
    Ok(PagedComicResultDto {
        items,
        total_count,
        page: window.page,
        page_size: window.page_size,
    })
}

pub async fn read_data_version() -> Result<i32, HentaiError> {
    let db = version_connection()?;
    let row = db
        .query_one(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "PRAGMA data_version".to_string(),
        ))
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::db_query_failed("data_version 无结果", None))?;
    row.try_get_by_index::<i32>(0)
        .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
}

async fn count_filtered(
    db: &DatabaseConnection,
    filter: &ComicFilterDto,
) -> Result<i64, HentaiError> {
    let query = build_count_query(filter);
    let stmt =
        Statement::from_sql_and_values(sea_orm::DatabaseBackend::Sqlite, query.sql, query.values);
    let row = db
        .query_one(stmt)
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::db_query_failed("count 无结果", None))?;
    row.try_get_by_index::<i64>(0)
        .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
}

async fn query_string_ids(
    db: &DatabaseConnection,
    query: &super::page_query::PageSqlQuery,
) -> Result<Vec<String>, HentaiError> {
    let stmt = Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        query.sql.clone(),
        query.values.clone(),
    );
    query_ids_from_stmt(db, stmt).await
}

async fn query_ids_from_stmt(
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

pub async fn load_comics_ordered(
    db: &DatabaseConnection,
    comic_ids: Vec<String>,
) -> Result<Vec<ComicDto>, HentaiError> {
    if comic_ids.is_empty() {
        return Ok(vec![]);
    }
    let models = Comics::find()
        .filter(Expr::col(comics::Column::ComicId).is_in(comic_ids.clone()))
        .all(db)
        .await
        .map_err(map_db_err)?;
    let meta_models = ComicMeta::find()
        .filter(Expr::col(comic_meta::Column::ComicId).is_in(comic_ids.clone()))
        .all(db)
        .await
        .map_err(map_db_err)?;
    let mut by_id: HashMap<String, comics::Model> = models
        .into_iter()
        .map(|m| (m.comic_id.clone(), m))
        .collect();
    let meta_by_id: HashMap<String, comic_meta::Model> = meta_models
        .into_iter()
        .map(|m| (m.comic_id.clone(), m))
        .collect();
    let tag_map = load_tag_names(db, &comic_ids).await?;
    let author_map = crate::author::load_author_names_for_comics(db, &comic_ids).await?;
    let parody_map = load_parody_names(db, &comic_ids).await?;
    let character_map = load_character_names(db, &comic_ids).await?;
    let last_read_map = load_last_read_times(db, &comic_ids).await?;
    let mut result = Vec::with_capacity(comic_ids.len());
    for id in comic_ids {
        let Some(model) = by_id.remove(&id) else {
            continue;
        };
        let Some(meta) = meta_by_id.get(&model.comic_id) else {
            continue;
        };
        result.push(ComicDto {
            comic_id: model.comic_id.clone(),
            path: model.path,
            resource_type: model.resource_type,
            resource_size: model.resource_size,
            created_at: model.created_at,
            last_updated_at: model.last_updated_at,
            title: meta.title.clone(),
            content_rating: meta.content_rating.clone(),
            page_count: meta.page_count,
            description: meta.description.clone(),
            published_at: meta.published_at,
            last_read_time_ms: last_read_map.get(&model.comic_id).copied(),
            authors: author_map.get(&model.comic_id).cloned().unwrap_or_default(),
            tags: tag_map.get(&model.comic_id).cloned().unwrap_or_default(),
            languages: crate::comic::parse_languages_json(&meta.languages),
            parodies: parody_map.get(&model.comic_id).cloned().unwrap_or_default(),
            characters: character_map
                .get(&model.comic_id)
                .cloned()
                .unwrap_or_default(),
            locks: crate::comic::ComicMetaLocks {
                title: meta.title_locked,
                description: meta.description_locked,
                published_at: meta.published_at_locked,
                content_rating: meta.content_rating_locked,
                authors: meta.authors_locked,
                tags: meta.tags_locked,
                languages: meta.languages_locked,
                parodies: meta.parodies_locked,
                characters: meta.characters_locked,
            },
            library_id: model.library_id,
        });
    }
    Ok(result)
}

/// 浏览列表瘦加载：仅 comics + comic_meta 的标题/页数，不拉关系表。
async fn load_comics_browse_ordered(
    db: &DatabaseConnection,
    comic_ids: Vec<String>,
) -> Result<Vec<ComicBrowseItemDto>, HentaiError> {
    if comic_ids.is_empty() {
        return Ok(vec![]);
    }
    let models = Comics::find()
        .filter(Expr::col(comics::Column::ComicId).is_in(comic_ids.clone()))
        .all(db)
        .await
        .map_err(map_db_err)?;
    let meta_models = ComicMeta::find()
        .filter(Expr::col(comic_meta::Column::ComicId).is_in(comic_ids.clone()))
        .all(db)
        .await
        .map_err(map_db_err)?;
    let mut by_id: HashMap<String, comics::Model> = models
        .into_iter()
        .map(|m| (m.comic_id.clone(), m))
        .collect();
    let meta_by_id: HashMap<String, comic_meta::Model> = meta_models
        .into_iter()
        .map(|m| (m.comic_id.clone(), m))
        .collect();
    let mut result = Vec::with_capacity(comic_ids.len());
    for id in comic_ids {
        let Some(model) = by_id.remove(&id) else {
            continue;
        };
        let Some(meta) = meta_by_id.get(&model.comic_id) else {
            continue;
        };
        result.push(ComicBrowseItemDto {
            comic_id: model.comic_id,
            path: model.path,
            title: meta.title.clone(),
            page_count: meta.page_count,
        });
    }
    Ok(result)
}

async fn load_last_read_times(
    db: &DatabaseConnection,
    comic_ids: &[String],
) -> Result<HashMap<String, i64>, HentaiError> {
    if comic_ids.is_empty() {
        return Ok(HashMap::new());
    }
    let cutoff = reading_history_retention_cutoff_ms(now_ms());
    let rows = ComicReadingHistories::find()
        .filter(Expr::col(comic_reading_histories::Column::ComicId).is_in(comic_ids.to_vec()))
        .filter(comic_reading_histories::Column::LastReadTime.gte(cutoff))
        .all(db)
        .await
        .map_err(map_db_err)?;
    Ok(rows
        .into_iter()
        .map(|row| (row.comic_id, row.last_read_time))
        .collect())
}

async fn load_tag_names(
    db: &DatabaseConnection,
    comic_ids: &[String],
) -> Result<HashMap<String, Vec<String>>, HentaiError> {
    let rows = ComicTags::find()
        .filter(Expr::col(comic_tags::Column::ComicId).is_in(comic_ids.to_vec()))
        .order_by_asc(comic_tags::Column::TagName)
        .all(db)
        .await
        .map_err(map_db_err)?;
    let mut map: HashMap<String, Vec<String>> = HashMap::new();
    for row in rows {
        map.entry(row.comic_id).or_default().push(row.tag_name);
    }
    Ok(map)
}

async fn load_parody_names(
    db: &DatabaseConnection,
    comic_ids: &[String],
) -> Result<HashMap<String, Vec<String>>, HentaiError> {
    let rows = ComicParodies::find()
        .filter(Expr::col(comic_parodies::Column::ComicId).is_in(comic_ids.to_vec()))
        .order_by_asc(comic_parodies::Column::ParodyName)
        .all(db)
        .await
        .map_err(map_db_err)?;
    let mut map: HashMap<String, Vec<String>> = HashMap::new();
    for row in rows {
        map.entry(row.comic_id).or_default().push(row.parody_name);
    }
    Ok(map)
}

async fn load_character_names(
    db: &DatabaseConnection,
    comic_ids: &[String],
) -> Result<HashMap<String, Vec<String>>, HentaiError> {
    let rows = ComicCharacters::find()
        .filter(Expr::col(comic_characters::Column::ComicId).is_in(comic_ids.to_vec()))
        .order_by_asc(comic_characters::Column::CharacterName)
        .all(db)
        .await
        .map_err(map_db_err)?;
    let mut map: HashMap<String, Vec<String>> = HashMap::new();
    for row in rows {
        map.entry(row.comic_id)
            .or_default()
            .push(row.character_name);
    }
    Ok(map)
}
