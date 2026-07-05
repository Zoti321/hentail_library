use std::collections::HashMap;

use sea_orm::{
    ConnectionTrait, DatabaseConnection, EntityTrait, QueryFilter, QueryOrder, Statement,
    Value,
};
use sea_orm::sea_query::Expr;

use crate::db::{connection, map_db_err};
use crate::entity::{comic_authors, comic_meta, comic_tags, comics, prelude::*};
use crate::error::HentaiError;

use super::dto::{
    ComicDto, ComicFilterDto, ComicSortOptionDto, PageRequestDto, PagedComicResultDto,
};
use super::page_query::{build_count_query, build_ids_page_query};

pub async fn count_all() -> Result<i64, HentaiError> {
    let db = connection()?;
    let row = db
        .query_one(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT COUNT(*) AS c FROM comics".to_string(),
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
    sort: ComicSortOptionDto,
) -> Result<PagedComicResultDto, HentaiError> {
    let db = connection()?;
    let filter = filter.normalized();
    let page_size = request.page_size.max(1);
    let total_count = count_filtered(&db, &filter).await?;
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
        return Ok(PagedComicResultDto {
            items: vec![],
            total_count: 0,
            page: 1,
            page_size,
        });
    }
    let offset = (effective_page - 1) * page_size;
    let ids_query = build_ids_page_query(&filter, sort.descending, page_size, offset);
    let comic_ids = query_string_ids(&db, &ids_query).await?;
    let items = load_comics_ordered(&db, comic_ids).await?;
    Ok(PagedComicResultDto {
        items,
        total_count,
        page: effective_page,
        page_size,
    })
}

pub async fn find_comic_by_id(comic_id: &str) -> Result<Option<ComicDto>, HentaiError> {
    let db = connection()?;
    let comics = load_comics_ordered(&db, vec![comic_id.to_string()]).await?;
    Ok(comics.into_iter().next())
}

pub async fn search_by_keyword(keyword: &str) -> Result<Vec<ComicDto>, HentaiError> {
    let q = keyword.trim().to_lowercase();
    if q.is_empty() {
        return Ok(vec![]);
    }
    let db = connection()?;
    let stmt = Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "SELECT c.comic_id FROM comics c \
         INNER JOIN comic_meta m ON m.comic_id = c.comic_id \
         WHERE lower(m.title) LIKE ?",
        vec![Value::String(Some(Box::new(format!("%{q}%"))))],
    );
    let comic_ids = query_ids_from_stmt(&db, stmt).await?;
    load_comics_ordered(&db, comic_ids).await
}

pub async fn read_data_version() -> Result<i32, HentaiError> {
    let db = connection()?;
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

async fn count_filtered(db: &DatabaseConnection, filter: &ComicFilterDto) -> Result<i64, HentaiError> {
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
    let mut by_id: HashMap<String, comics::Model> =
        models.into_iter().map(|m| (m.comic_id.clone(), m)).collect();
    let meta_by_id: HashMap<String, comic_meta::Model> = meta_models
        .into_iter()
        .map(|m| (m.comic_id.clone(), m))
        .collect();
    let tag_map = load_tag_names(db, &comic_ids).await?;
    let author_map = load_author_names(db, &comic_ids).await?;
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
            authors: author_map.get(&model.comic_id).cloned().unwrap_or_default(),
            tags: tag_map.get(&model.comic_id).cloned().unwrap_or_default(),
        });
    }
    Ok(result)
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

async fn load_author_names(
    db: &DatabaseConnection,
    comic_ids: &[String],
) -> Result<HashMap<String, Vec<String>>, HentaiError> {
    let rows = ComicAuthors::find()
        .filter(Expr::col(comic_authors::Column::ComicId).is_in(comic_ids.to_vec()))
        .order_by_asc(comic_authors::Column::AuthorName)
        .all(db)
        .await
        .map_err(map_db_err)?;
    let mut map: HashMap<String, Vec<String>> = HashMap::new();
    for row in rows {
        map.entry(row.comic_id).or_default().push(row.author_name);
    }
    Ok(map)
}
