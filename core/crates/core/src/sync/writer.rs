use std::collections::{HashMap, HashSet};

use sea_orm::{
    ColumnTrait, ConnectionTrait, DatabaseConnection, EntityTrait, QueryFilter, Statement,
    TransactionTrait,
};

use crate::comic::{delete_comics_side_effects, load_comics_ordered, upsert_comics, ComicDto};
use crate::db::map_db_err;
use crate::entity::{comic_thumbnails, prelude::*};
use crate::error::HentaiError;
use crate::history::{normalize_reading_history_titles, purge_expired_reading_histories};
use crate::path_migration::{apply_comic_rekeys, apply_series_rekeys, ComicMigration};

use super::plan::ComicScanReplacePlan;
use super::series_rebuild::rebuild_series_from_comics;

pub async fn apply_scan_replace_plan(
    db: &DatabaseConnection,
    plan: &ComicScanReplacePlan,
    library_id: &str,
) -> Result<(), HentaiError> {
    let txn = db.begin().await.map_err(map_db_err)?;
    apply_scan_replace_plan_in(&txn, plan, library_id).await?;
    txn.commit().await.map_err(map_db_err)?;
    crate::revision::notify_committed();
    Ok(())
}

pub(crate) async fn apply_scan_replace_plan_in(
    txn: &sea_orm::DatabaseTransaction,
    plan: &ComicScanReplacePlan,
    library_id: &str,
) -> Result<(), HentaiError> {
    let ids: HashSet<String> = plan
        .to_upsert
        .iter()
        .map(|item| item.comic.comic_id.clone())
        .chain(
            plan.migrations
                .iter()
                .map(|migration| migration.from_comic_id.clone()),
        )
        .chain(plan.removed_ids.iter().cloned())
        .collect();
    // Locks, metadata and page counts belong to this transaction, not the scan plan.
    let current: HashMap<String, ComicDto> = load_comics_ordered(txn, ids.into_iter().collect())
        .await?
        .into_iter()
        .map(|comic| (comic.comic_id.clone(), comic))
        .collect();
    if plan
        .existing_comic_ids
        .iter()
        .any(|id| !current.contains_key(id))
    {
        return Err(HentaiError::validation(
            "同步计划中的漫画已移除，请重新同步",
        ));
    }
    let to_upsert: Vec<ComicDto> = plan
        .to_upsert
        .iter()
        .map(|item| item.merge_with_catalog(current.get(&item.comic.comic_id)))
        .collect::<Result<_, _>>()?;
    let migrations: Vec<ComicMigration> = plan
        .migrations
        .iter()
        .map(|migration| {
            let source = current.get(&migration.from_comic_id).ok_or_else(|| {
                HentaiError::validation(format!("待迁移漫画已移除: {}", migration.from_comic_id))
            })?;
            let mut to_comic = migration.scanned.merge_with_catalog(Some(source))?;
            to_comic.comic_id = migration.scanned.comic.comic_id.clone();
            Ok(ComicMigration {
                from_comic_id: migration.from_comic_id.clone(),
                to_comic,
            })
        })
        .collect::<Result<_, HentaiError>>()?;
    apply_comic_rekeys(txn, &migrations).await?;
    apply_series_rekeys(txn, &plan.series_migrations).await?;
    if !plan.removed_ids.is_empty() {
        delete_comics_side_effects(txn, &plan.removed_ids).await?;
    }
    if !plan.thumbnail_invalidated_comic_ids.is_empty() {
        ComicThumbnails::delete_many()
            .filter(
                comic_thumbnails::Column::ComicId
                    .is_in(plan.thumbnail_invalidated_comic_ids.clone()),
            )
            .exec(txn)
            .await
            .map_err(map_db_err)?;
    }
    let skipped = upsert_comics(txn, &to_upsert).await?;
    if !skipped.is_empty() {
        // Scan plans carry a parsed page count (Remote placeholder is 1), so a
        // skip here means the resource yielded no pages at all.
        tracing::debug!(?skipped, "scan upsert skipped comics without pages");
    }
    for item in plan
        .to_upsert
        .iter()
        .chain(plan.migrations.iter().map(|migration| &migration.scanned))
    {
        super::fingerprint::store_fingerprint(txn, item).await?;
    }
    normalize_reading_history_titles(txn).await?;
    purge_expired_reading_histories(txn).await?;
    rebuild_series_from_comics(txn, Some(library_id)).await?;
    Ok(())
}

pub async fn clear_all_comics(db: &DatabaseConnection) -> Result<i32, HentaiError> {
    let count = count_comics(db).await? as i32;
    if count == 0 {
        return Ok(0);
    }
    let txn = db.begin().await.map_err(map_db_err)?;
    for table in ["comic_reading_histories", "series_items", "comics"] {
        txn.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!("DELETE FROM {table}"),
        ))
        .await
        .map_err(map_db_err)?;
    }
    txn.commit().await.map_err(map_db_err)?;
    crate::revision::notify_committed();
    Ok(count)
}

pub async fn clear_comics_for_library(
    db: &DatabaseConnection,
    library_id: &str,
) -> Result<i32, HentaiError> {
    let comic_ids = load_comic_ids_for_library(db, library_id).await?;
    let count = comic_ids.len() as i32;
    if count == 0 {
        // Still clear orphan series for this library.
        Series::delete_many()
            .filter(crate::entity::series::Column::LibraryId.eq(library_id))
            .exec(db)
            .await
            .map_err(map_db_err)?;
        return Ok(0);
    }
    let txn = db.begin().await.map_err(map_db_err)?;
    delete_comics_side_effects(&txn, &comic_ids).await?;
    txn.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM series WHERE library_id = ?",
        [sea_orm::Value::String(Some(Box::new(
            library_id.to_string(),
        )))],
    ))
    .await
    .map_err(map_db_err)?;
    txn.commit().await.map_err(map_db_err)?;
    crate::revision::notify_committed();
    Ok(count)
}

async fn load_comic_ids_for_library(
    db: &DatabaseConnection,
    library_id: &str,
) -> Result<Vec<String>, HentaiError> {
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT comic_id FROM comics WHERE library_id = ?",
            [sea_orm::Value::String(Some(Box::new(
                library_id.to_string(),
            )))],
        ))
        .await
        .map_err(map_db_err)?;
    rows.into_iter()
        .map(|row| {
            row.try_get_by_index::<String>(0)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
        })
        .collect()
}

async fn count_comics(db: &DatabaseConnection) -> Result<i64, HentaiError> {
    let row = db
        .query_one(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT COUNT(*) FROM comics".to_string(),
        ))
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::db_query_failed("count ???", None))?;
    row.try_get_by_index::<i64>(0)
        .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
}
