use sea_orm::{
    ActiveModelTrait, ColumnTrait, ConnectionTrait, DatabaseConnection, EntityTrait, QueryFilter,
    Set, Statement, TransactionTrait,
};

use crate::comic::ComicDto;
use crate::db::map_db_err;
use crate::entity::{
    authors, comic_authors, comic_tags, comic_thumbnails, comics, prelude::*,
    series_reading_histories, tags,
};
use crate::error::HentaiError;

use super::plan::ComicScanReplacePlan;

pub async fn apply_scan_replace_plan(
    db: &DatabaseConnection,
    plan: &ComicScanReplacePlan,
) -> Result<(), HentaiError> {
    let txn = db.begin().await.map_err(map_db_err)?;
    if !plan.removed_ids.is_empty() {
        delete_comics_side_effects(&txn, &plan.removed_ids).await?;
    }
    if !plan.thumbnail_invalidated_comic_ids.is_empty() {
        ComicThumbnails::delete_many()
            .filter(
                comic_thumbnails::Column::ComicId
                    .is_in(plan.thumbnail_invalidated_comic_ids.clone()),
            )
            .exec(&txn)
            .await
            .map_err(map_db_err)?;
    }
    upsert_comics(&txn, &plan.to_upsert).await?;
    remove_orphan_series_items(&txn).await?;
    txn.commit().await.map_err(map_db_err)?;
    Ok(())
}

pub async fn clear_all_comics(db: &DatabaseConnection) -> Result<i32, HentaiError> {
    let count = count_comics(db).await? as i32;
    if count == 0 {
        return Ok(0);
    }
    let txn = db.begin().await.map_err(map_db_err)?;
    for table in [
        "comic_reading_histories",
        "series_reading_histories",
        "series_items",
        "comics",
    ] {
        txn.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!("DELETE FROM {table}"),
        ))
        .await
        .map_err(map_db_err)?;
    }
    txn.commit().await.map_err(map_db_err)?;
    Ok(count)
}

async fn count_comics(db: &DatabaseConnection) -> Result<i64, HentaiError> {
    let row = db
        .query_one(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT COUNT(*) FROM comics".to_string(),
        ))
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::db_query_failed("count 无结果", None))?;
    row.try_get_by_index::<i64>(0)
        .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
}

async fn delete_comics_side_effects<C: ConnectionTrait>(
    db: &C,
    comic_ids: &[String],
) -> Result<(), HentaiError> {
    if comic_ids.is_empty() {
        return Ok(());
    }
    const BATCH_SIZE: usize = 500;
    for chunk in comic_ids.chunks(BATCH_SIZE) {
        delete_comics_side_effects_batch(db, chunk).await?;
    }
    Ok(())
}

async fn delete_comics_side_effects_batch<C: ConnectionTrait>(
    db: &C,
    comic_ids: &[String],
) -> Result<(), HentaiError> {
    if comic_ids.is_empty() {
        return Ok(());
    }
    let placeholders = comic_ids
        .iter()
        .map(|_| "?")
        .collect::<Vec<_>>()
        .join(",");
    let values: Vec<sea_orm::Value> = comic_ids
        .iter()
        .map(|id| sea_orm::Value::String(Some(Box::new(id.clone()))))
        .collect();
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM comic_reading_histories WHERE comic_id IN ({placeholders})"),
        values.clone(),
    ))
    .await
    .map_err(map_db_err)?;
    SeriesReadingHistories::delete_many()
        .filter(series_reading_histories::Column::LastReadComicId.is_in(comic_ids.to_vec()))
        .exec(db)
        .await
        .map_err(map_db_err)?;
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM series_items WHERE comic_id IN ({placeholders})"),
        values.clone(),
    ))
    .await
    .map_err(map_db_err)?;
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM comics WHERE comic_id IN ({placeholders})"),
        values,
    ))
    .await
    .map_err(map_db_err)?;
    Ok(())
}

pub async fn remove_orphan_series_items<C: ConnectionTrait>(db: &C) -> Result<(), HentaiError> {
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM series_items WHERE comic_id NOT IN (SELECT comic_id FROM comics)".to_string(),
    ))
    .await
    .map_err(map_db_err)?;
    Ok(())
}

async fn upsert_comics<C: ConnectionTrait>(db: &C, comics_list: &[ComicDto]) -> Result<(), HentaiError> {
    for comic in comics_list {
        let active = comics::ActiveModel {
            comic_id: Set(comic.comic_id.clone()),
            path: Set(comic.path.clone()),
            resource_type: Set(comic.resource_type.clone()),
            title: Set(comic.title.clone()),
            content_rating: Set(comic.content_rating.clone()),
            page_count: Set(comic.page_count),
            ..Default::default()
        };
        Comics::insert(active)
            .on_conflict(
                sea_orm::sea_query::OnConflict::column(comics::Column::ComicId)
                    .update_columns([
                        comics::Column::Path,
                        comics::Column::ResourceType,
                        comics::Column::Title,
                        comics::Column::ContentRating,
                        comics::Column::PageCount,
                    ])
                    .to_owned(),
            )
            .exec(db)
            .await
            .map_err(map_db_err)?;
        replace_comic_authors(db, &comic.comic_id, &comic.authors).await?;
        replace_comic_tags(db, &comic.comic_id, &comic.tags).await?;
    }
    Ok(())
}

pub async fn replace_comic_authors<C: ConnectionTrait>(
    db: &C,
    comic_id: &str,
    author_names: &[String],
) -> Result<(), HentaiError> {
    ComicAuthors::delete_many()
        .filter(comic_authors::Column::ComicId.eq(comic_id))
        .exec(db)
        .await
        .map_err(map_db_err)?;
    let unique: std::collections::HashSet<&String> = author_names.iter().collect();
    for name in unique {
        let author = authors::ActiveModel {
            name: Set(name.clone()),
            ..Default::default()
        };
        Authors::insert(author)
            .on_conflict(
                sea_orm::sea_query::OnConflict::column(authors::Column::Name)
                    .do_nothing()
                    .to_owned(),
            )
            .exec(db)
            .await
            .map_err(map_db_err)?;
        let row = comic_authors::ActiveModel {
            comic_id: Set(comic_id.to_string()),
            author_name: Set(name.clone()),
            ..Default::default()
        };
        ComicAuthors::insert(row).exec(db).await.map_err(map_db_err)?;
    }
    Ok(())
}

pub async fn replace_comic_tags<C: ConnectionTrait>(
    db: &C,
    comic_id: &str,
    tag_names: &[String],
) -> Result<(), HentaiError> {
    ComicTags::delete_many()
        .filter(comic_tags::Column::ComicId.eq(comic_id))
        .exec(db)
        .await
        .map_err(map_db_err)?;
    let unique: std::collections::HashSet<&String> = tag_names.iter().collect();
    for name in unique {
        let tag = tags::ActiveModel {
            name: Set(name.clone()),
            ..Default::default()
        };
        Tags::insert(tag)
            .on_conflict(
                sea_orm::sea_query::OnConflict::column(tags::Column::Name)
                    .do_nothing()
                    .to_owned(),
            )
            .exec(db)
            .await
            .map_err(map_db_err)?;
        let row = comic_tags::ActiveModel {
            comic_id: Set(comic_id.to_string()),
            tag_name: Set(name.clone()),
            ..Default::default()
        };
        ComicTags::insert(row).exec(db).await.map_err(map_db_err)?;
    }
    Ok(())
}
