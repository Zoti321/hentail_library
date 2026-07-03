use std::collections::HashSet;

use sea_orm::{
    ColumnTrait, ConnectionTrait, DatabaseConnection, EntityTrait, QueryFilter, Set,
    TransactionTrait,
};

use crate::db::{connection, map_db_err};
use crate::entity::{prelude::*, series, series_items};
use crate::error::HentaiError;
use crate::series::{AutoSeriesInferService, ComicTitleInput, InferredSeriesGroup};

#[derive(Debug, Clone, Default)]
pub struct InferSeriesResultDto {
    pub groups_applied: i32,
    pub comics_assigned: i32,
    pub new_series_created: i32,
}

pub async fn infer_series() -> Result<InferSeriesResultDto, HentaiError> {
    let db = connection()?;
    let assigned = load_assigned_comic_ids(&db).await?;
    let candidates = load_unassigned_comics(&db, &assigned).await?;
    let groups = AutoSeriesInferService::default().infer_groups(&candidates, 2);
    let mut comics_assigned = 0i32;
    let mut new_series_created = 0i32;
    for group in &groups {
        let created = apply_inferred_group(&db, group).await?;
        if created {
            new_series_created += 1;
        }
        comics_assigned += group.entries.len() as i32;
    }
    Ok(InferSeriesResultDto {
        groups_applied: groups.len() as i32,
        comics_assigned,
        new_series_created,
    })
}

async fn load_assigned_comic_ids(db: &DatabaseConnection) -> Result<HashSet<String>, HentaiError> {
    let rows = SeriesItems::find().all(db).await.map_err(map_db_err)?;
    Ok(rows.into_iter().map(|r| r.comic_id).collect())
}

async fn load_unassigned_comics(
    db: &DatabaseConnection,
    assigned: &HashSet<String>,
) -> Result<Vec<ComicTitleInput>, HentaiError> {
    let rows = Comics::find().all(db).await.map_err(map_db_err)?;
    Ok(rows
        .into_iter()
        .filter(|c| !assigned.contains(&c.comic_id))
        .map(|c| ComicTitleInput {
            comic_id: c.comic_id,
            title: c.title,
        })
        .collect())
}

async fn apply_inferred_group(
    db: &DatabaseConnection,
    group: &InferredSeriesGroup,
) -> Result<bool, HentaiError> {
    let existing = Series::find_by_id(&group.series_name)
        .one(db)
        .await
        .map_err(map_db_err)?;
    let is_new = existing.is_none();
    let txn = db.begin().await.map_err(map_db_err)?;
    Series::insert(series::ActiveModel {
        name: Set(group.series_name.clone()),
        ..Default::default()
    })
    .on_conflict(
        sea_orm::sea_query::OnConflict::column(series::Column::Name)
            .do_nothing()
            .to_owned(),
    )
    .exec(&txn)
    .await
    .map_err(map_db_err)?;
    let max_existing = max_sort_order(&txn, &group.series_name).await?;
    let mut next_order = if max_existing >= 0 {
        max_existing + 1
    } else {
        0
    };
    for entry in &group.entries {
        SeriesItems::delete_many()
            .filter(series_items::Column::ComicId.eq(&entry.comic_id))
            .exec(&txn)
            .await
            .map_err(map_db_err)?;
        SeriesItems::insert(series_items::ActiveModel {
            series_name: Set(group.series_name.clone()),
            comic_id: Set(entry.comic_id.clone()),
            sort_order: Set(next_order),
            ..Default::default()
        })
        .on_conflict(
            sea_orm::sea_query::OnConflict::column(series_items::Column::ComicId)
                .update_columns([
                    series_items::Column::SeriesName,
                    series_items::Column::SortOrder,
                ])
                .to_owned(),
        )
        .exec(&txn)
        .await
        .map_err(map_db_err)?;
        next_order += 1;
    }
    txn.commit().await.map_err(map_db_err)?;
    Ok(is_new)
}

async fn max_sort_order(
    db: &impl ConnectionTrait,
    series_name: &str,
) -> Result<i32, HentaiError> {
    let rows = SeriesItems::find()
        .filter(series_items::Column::SeriesName.eq(series_name))
        .all(db)
        .await
        .map_err(map_db_err)?;
    Ok(rows.into_iter().map(|r| r.sort_order).max().unwrap_or(-1))
}
