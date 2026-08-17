use std::collections::{HashMap, HashSet};

use sea_orm::{ConnectionTrait, DatabaseConnection, EntityTrait, Statement};

use crate::comic::ComicDto;
use crate::db::map_db_err;
use crate::entity::prelude::*;
use crate::error::HentaiError;

use crate::metadata_lock::merge_kept_scan_with_existing;
use super::migrate::{
    detect_path_migration_pairs, migrated_id_sets, ComicMigration, ComicMigrationPair,
};
use crate::resource::can_generate_thumbnail;
use super::scanner::ScanItem;

pub struct ComicScanReplacePlan {
    pub removed_ids: Vec<String>,
    pub added_count: i32,
    pub kept_count: i32,
    pub migrated_count: i32,
    pub migrations: Vec<ComicMigration>,
    pub to_upsert: Vec<ComicDto>,
    pub thumbnail_invalidated_comic_ids: Vec<String>,
    pub thumbnail_generation_targets: Vec<ComicDto>,
}

struct IdDiff {
    removed_ids: HashSet<String>,
    added_ids: HashSet<String>,
    kept_ids: HashSet<String>,
}

pub async fn build_scan_replace_plan(
    db: &DatabaseConnection,
    scanned: Vec<ScanItem>,
    library_id: &str,
) -> Result<ComicScanReplacePlan, HentaiError> {
    let unique = dedupe_scanned(scanned);
    let scanned_ids: HashSet<String> = unique.keys().cloned().collect();
    let existing = load_comics_for_library(db, library_id).await?;
    let existing_by_id: HashMap<String, ComicDto> =
        existing.into_iter().map(|c| (c.comic_id.clone(), c)).collect();
    let existing_ids: HashSet<String> = existing_by_id.keys().cloned().collect();
    let id_diff = compute_id_diff(&existing_ids, &scanned_ids);
    let removed_by_id: HashMap<String, ComicDto> = id_diff
        .removed_ids
        .iter()
        .filter_map(|id| existing_by_id.get(id).map(|comic| (id.clone(), comic.clone())))
        .collect();
    let added_by_id: HashMap<String, ComicDto> = id_diff
        .added_ids
        .iter()
        .filter_map(|id| unique.get(id).map(|comic| (id.clone(), comic.clone())))
        .collect();
    let migration_pairs = detect_path_migration_pairs(&removed_by_id, &added_by_id);
    let (migrated_from_ids, migrated_to_ids) = migrated_id_sets(&migration_pairs);
    let migrations = build_migrations(&migration_pairs, &existing_by_id, &unique);
    let removed_ids: Vec<String> = id_diff
        .removed_ids
        .difference(&migrated_from_ids)
        .cloned()
        .collect();
    let added_ids: HashSet<String> = id_diff
        .added_ids
        .difference(&migrated_to_ids)
        .cloned()
        .collect();
    let kept_ids = &id_diff.kept_ids;
    let mut thumbnail_invalidated = Vec::new();
    let mut to_upsert = Vec::new();
    for (id, row) in &unique {
        if migrated_to_ids.contains(id) {
            continue;
        }
        if added_ids.contains(id) {
            to_upsert.push(row.clone());
        } else if let Some(prior) = existing_by_id.get(id) {
            if prior.path != row.path || prior.resource_type != row.resource_type {
                thumbnail_invalidated.push(id.clone());
            }
            to_upsert.push(merge_kept_scan_with_existing(row, prior));
        }
    }
    let thumbnail_targets = build_thumbnail_targets(
        db,
        &to_upsert,
        &added_ids,
        kept_ids,
        &thumbnail_invalidated.iter().cloned().collect(),
    )
    .await?;
    Ok(ComicScanReplacePlan {
        removed_ids,
        added_count: added_ids.len() as i32,
        kept_count: kept_ids.len() as i32,
        migrated_count: migrations.len() as i32,
        migrations,
        to_upsert,
        thumbnail_invalidated_comic_ids: thumbnail_invalidated,
        thumbnail_generation_targets: thumbnail_targets,
    })
}

fn dedupe_scanned(scanned: Vec<ScanItem>) -> HashMap<String, ComicDto> {
    let mut map = HashMap::new();
    for item in scanned {
        map.insert(item.comic.comic_id.clone(), item.comic);
    }
    map
}

fn compute_id_diff(existing_ids: &HashSet<String>, scanned_ids: &HashSet<String>) -> IdDiff {
    IdDiff {
        removed_ids: existing_ids.difference(scanned_ids).cloned().collect(),
        added_ids: scanned_ids.difference(existing_ids).cloned().collect(),
        kept_ids: existing_ids.intersection(scanned_ids).cloned().collect(),
    }
}

fn build_migrations(
    pairs: &[ComicMigrationPair],
    existing_by_id: &HashMap<String, ComicDto>,
    scanned_by_id: &HashMap<String, ComicDto>,
) -> Vec<ComicMigration> {
    pairs
        .iter()
        .filter_map(|pair| {
            let existing = existing_by_id.get(&pair.from_comic_id)?;
            let scanned = scanned_by_id.get(&pair.to_comic_id)?;
            let mut merged = merge_kept_scan_with_existing(scanned, existing);
            merged.comic_id = scanned.comic_id.clone();
            Some(ComicMigration {
                from_comic_id: pair.from_comic_id.clone(),
                to_comic: merged,
            })
        })
        .collect()
}

async fn load_all_comics(db: &DatabaseConnection) -> Result<Vec<ComicDto>, HentaiError> {
  use crate::comic::repository::load_comics_ordered;
  let rows = Comics::find().all(db).await.map_err(map_db_err)?;
  let ids: Vec<String> = rows.into_iter().map(|r| r.comic_id).collect();
  load_comics_ordered(db, ids).await
}

async fn load_comics_for_library(
    db: &DatabaseConnection,
    library_id: &str,
) -> Result<Vec<ComicDto>, HentaiError> {
    use crate::comic::repository::load_comics_ordered;
    use sea_orm::ColumnTrait;
    use sea_orm::QueryFilter;
    let rows = Comics::find()
        .filter(crate::entity::comics::Column::LibraryId.eq(library_id))
        .all(db)
        .await
        .map_err(map_db_err)?;
    let ids: Vec<String> = rows.into_iter().map(|r| r.comic_id).collect();
    load_comics_ordered(db, ids).await
}

async fn build_thumbnail_targets(
    db: &DatabaseConnection,
    to_upsert: &[ComicDto],
    added_ids: &HashSet<String>,
    kept_ids: &HashSet<String>,
    invalidated_ids: &HashSet<String>,
) -> Result<Vec<ComicDto>, HentaiError> {
    let mut targets = Vec::new();
    for comic in to_upsert {
        if !can_generate_thumbnail(&comic.resource_type) {
            continue;
        }
        let id = &comic.comic_id;
        if added_ids.contains(id) || invalidated_ids.contains(id) {
            targets.push(comic.clone());
            continue;
        }
        if kept_ids.contains(id) && needs_thumbnail_generation(db, comic).await? {
            targets.push(comic.clone());
        }
    }
    Ok(targets)
}

async fn needs_thumbnail_generation(
    db: &DatabaseConnection,
    comic: &ComicDto,
) -> Result<bool, HentaiError> {
    crate::thumbnail::thumbnail_needs_generation(db, comic).await
}

pub async fn load_thumbnail_stats(
    db: &DatabaseConnection,
) -> Result<HashMap<String, (i64, i64)>, HentaiError> {
    let rows = ComicThumbnails::find().all(db).await.map_err(map_db_err)?;
    let mut map = HashMap::new();
    for row in rows {
        if let (Some(ms), Some(size)) = (row.source_modified_ms, row.source_size) {
            map.insert(row.comic_id, (ms, size));
        }
    }
    Ok(map)
}

pub async fn load_existing_comics_map(
    db: &DatabaseConnection,
) -> Result<HashMap<String, ComicDto>, HentaiError> {
    let comics = load_all_comics(db).await?;
    Ok(comics.into_iter().map(|c| (c.comic_id.clone(), c)).collect())
}

pub async fn load_saved_paths(db: &DatabaseConnection) -> Result<Vec<String>, HentaiError> {
    let rows = Libraries::find().all(db).await.map_err(map_db_err)?;
    Ok(rows.into_iter().map(|r| r.root_path).collect())
}

pub async fn count_comic_ids_for_library(
    db: &DatabaseConnection,
    library_id: &str,
) -> Result<i64, HentaiError> {
    let row = db
        .query_one(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT COUNT(*) FROM comics WHERE library_id = ?",
            [sea_orm::Value::String(Some(Box::new(library_id.to_string())))],
        ))
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::db_query_failed("count comics 无结果", None))?;
    row.try_get_by_index::<i64>(0)
        .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
}
