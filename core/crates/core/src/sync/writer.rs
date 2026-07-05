use sea_orm::{
    ActiveModelTrait, ColumnTrait, ConnectionTrait, DatabaseConnection, EntityTrait, QueryFilter,
    Set, Statement, TransactionTrait,
};

use crate::comic::{now_ms, ComicDto};
use crate::db::map_db_err;
use crate::entity::{
    authors, comic_authors, comic_meta, comic_tags, comic_thumbnails, comics, prelude::*, tags,
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
        if comic.page_count <= 0 {
            continue;
        }
        let existing_comic = Comics::find_by_id(comic.comic_id.clone())
            .one(db)
            .await
            .map_err(map_db_err)?;
        let existing_meta = ComicMeta::find_by_id(comic.comic_id.clone())
            .one(db)
            .await
            .map_err(map_db_err)?;
        let is_new = existing_comic.is_none();
        let now = now_ms();
        let created_at = if is_new {
            now
        } else {
            comic.created_at
        };
        let mut changed = is_new;
        if let Some(ref row) = existing_comic {
            changed |= row.path != comic.path
                || row.resource_type != comic.resource_type
                || row.resource_size != comic.resource_size;
        }
        if let Some(ref row) = existing_meta {
            changed |= row.title != comic.title
                || row.content_rating != comic.content_rating
                || row.page_count != comic.page_count
                || row.description != comic.description
                || row.published_at != comic.published_at;
        }
        if !is_new {
            let existing_authors = load_author_names_for_comic(db, &comic.comic_id).await?;
            let existing_tags = load_tag_names_for_comic(db, &comic.comic_id).await?;
            changed |= existing_authors != comic.authors || existing_tags != comic.tags;
        }
        let last_updated_at = if changed { now } else { comic.last_updated_at };

        let comic_active = comics::ActiveModel {
            comic_id: Set(comic.comic_id.clone()),
            path: Set(comic.path.clone()),
            resource_type: Set(comic.resource_type.clone()),
            resource_size: Set(comic.resource_size),
            created_at: Set(created_at),
            last_updated_at: Set(last_updated_at),
            ..Default::default()
        };
        Comics::insert(comic_active)
            .on_conflict(
                sea_orm::sea_query::OnConflict::column(comics::Column::ComicId)
                    .update_columns([
                        comics::Column::Path,
                        comics::Column::ResourceType,
                        comics::Column::ResourceSize,
                        comics::Column::LastUpdatedAt,
                    ])
                    .to_owned(),
            )
            .exec(db)
            .await
            .map_err(map_db_err)?;

        let meta_active = comic_meta::ActiveModel {
            comic_id: Set(comic.comic_id.clone()),
            title: Set(comic.title.clone()),
            content_rating: Set(comic.content_rating.clone()),
            page_count: Set(comic.page_count),
            description: Set(comic.description.clone()),
            published_at: Set(comic.published_at),
            ..Default::default()
        };
        ComicMeta::insert(meta_active)
            .on_conflict(
                sea_orm::sea_query::OnConflict::column(comic_meta::Column::ComicId)
                    .update_columns([
                        comic_meta::Column::Title,
                        comic_meta::Column::ContentRating,
                        comic_meta::Column::PageCount,
                        comic_meta::Column::Description,
                        comic_meta::Column::PublishedAt,
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

async fn load_author_names_for_comic<C: ConnectionTrait>(
    db: &C,
    comic_id: &str,
) -> Result<Vec<String>, HentaiError> {
    let rows = ComicAuthors::find()
        .filter(comic_authors::Column::ComicId.eq(comic_id))
        .all(db)
        .await
        .map_err(map_db_err)?;
    let mut names: Vec<String> = rows.into_iter().map(|r| r.author_name).collect();
    names.sort();
    Ok(names)
}

async fn load_tag_names_for_comic<C: ConnectionTrait>(
    db: &C,
    comic_id: &str,
) -> Result<Vec<String>, HentaiError> {
    let rows = ComicTags::find()
        .filter(comic_tags::Column::ComicId.eq(comic_id))
        .all(db)
        .await
        .map_err(map_db_err)?;
    let mut names: Vec<String> = rows.into_iter().map(|r| r.tag_name).collect();
    names.sort();
    Ok(names)
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
