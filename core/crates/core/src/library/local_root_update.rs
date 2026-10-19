//! Local Library root update and Path migration during root change.

use std::collections::HashMap;
use std::path::{Path, PathBuf};

use sea_orm::{
    ActiveModelTrait, ColumnTrait, ConnectionTrait, EntityTrait, QueryFilter, Set, Statement,
    TransactionTrait,
};

use crate::comic::ComicDto;
use crate::comic_id::normalize_path_for_key;
use crate::db::{connection, map_db_err};
use crate::entity::{libraries, prelude::*};
use crate::error::HentaiError;
use crate::library::dto::{model_to_dto, LibraryDto, KIND_LOCAL};
use crate::library_write::with_library_write;
use crate::path_migration::{
    apply_comic_rekeys, apply_series_rekeys, ComicMigration, SeriesMigrationPair,
};
use crate::reader::clear_reader_sessions;
use crate::resource::{local_access, ResourceAccess, ResourceKind};
use crate::series_id::series_id_from_folder_path;

/// Change a Local library's Library root while keeping `library_id` and name.
/// Rejects empty roots and Local roots that equal or nest under another Local library.
pub async fn update_local_library_root(
    library_id: &str,
    root_path: &str,
) -> Result<LibraryDto, HentaiError> {
    let id = library_id.trim();
    if id.is_empty() {
        return Err(HentaiError::validation("library_id 不能为空"));
    }
    let root = root_path.trim();
    if root.is_empty() {
        return Err(HentaiError::validation("Library root 不能为空"));
    }
    with_library_write(|| update_local_library_root_locked(id, root)).await
}

/// [`update_local_library_root`] body for callers that already hold the library write
/// lock (ADR-0026). The Library root probe runs before the transaction opens, so the
/// SQLite transaction never spans filesystem I/O.
async fn update_local_library_root_locked(id: &str, root: &str) -> Result<LibraryDto, HentaiError> {
    let db = connection()?;
    let Some(model) = Libraries::find_by_id(id.to_string())
        .one(&db)
        .await
        .map_err(map_db_err)?
    else {
        return Err(HentaiError::validation(format!("Library 不存在: {id}")));
    };
    if model.kind != KIND_LOCAL {
        return Err(HentaiError::validation(
            "仅 Local library 可更新本地 Library root",
        ));
    }

    let existing_libs = super::list_libraries().await?;
    ensure_local_root_not_nested(root, Some(id), &existing_libs)?;

    let old_root = model.root_path.clone();
    let should_migrate = local_access().probe_root(root).is_ok();
    let txn = db.begin().await.map_err(map_db_err)?;

    if should_migrate {
        migrate_local_library_root_rows(&txn, id, &old_root, root).await?;
    }

    let mut active: libraries::ActiveModel = model.into();
    active.root_path = Set(root.to_string());
    let updated = active.update(&txn).await.map_err(map_db_err)?;
    txn.commit().await.map_err(map_db_err)?;
    clear_reader_sessions();
    Ok(model_to_dto(updated))
}

async fn migrate_local_library_root_rows<C: ConnectionTrait>(
    db: &C,
    library_id: &str,
    old_root: &str,
    new_root: &str,
) -> Result<(), HentaiError> {
    let comic_migrations =
        load_local_root_comic_migrations(db, library_id, old_root, new_root).await?;
    apply_comic_rekeys(db, &comic_migrations).await?;
    rekey_local_root_series(db, library_id, old_root, new_root).await?;
    Ok(())
}

async fn load_local_root_comic_migrations<C: ConnectionTrait>(
    db: &C,
    library_id: &str,
    old_root: &str,
    new_root: &str,
) -> Result<Vec<ComicMigration>, HentaiError> {
    let comics = load_full_comics_for_library(db, library_id).await?;
    let mut migrations = Vec::new();
    for comic in comics {
        let from_comic_id = comic.comic_id.clone();
        let Some(new_path) = remap_root_relative_path(&comic.path, old_root, new_root) else {
            continue;
        };
        if !target_resource_matches_kind(&new_path, &comic.resource_type)? {
            continue;
        }
        let new_id = crate::comic_id::comic_id_from_path(&new_path);
        if new_id == comic.comic_id {
            continue;
        }
        let mut to_comic = comic;
        to_comic.comic_id = new_id;
        to_comic.path = new_path;
        migrations.push(ComicMigration {
            from_comic_id,
            to_comic,
        });
    }
    Ok(migrations)
}

async fn rekey_local_root_series<C: ConnectionTrait>(
    db: &C,
    library_id: &str,
    old_root: &str,
    new_root: &str,
) -> Result<(), HentaiError> {
    let rows = Series::find()
        .filter(crate::entity::series::Column::LibraryId.eq(library_id))
        .all(db)
        .await
        .map_err(map_db_err)?;
    let mut migrations = Vec::new();
    for row in rows {
        let Some(new_folder_path) = remap_root_relative_path(&row.folder_path, old_root, new_root)
        else {
            continue;
        };
        if !target_resource_is_dir(&new_folder_path)? {
            continue;
        }
        let new_series_id = series_id_from_folder_path(&new_folder_path);
        if new_series_id == row.series_id {
            continue;
        }
        migrations.push(SeriesMigrationPair {
            from_series_id: row.series_id.clone(),
            to_series_id: new_series_id,
            to_folder_path: new_folder_path,
        });
    }
    apply_series_rekeys(db, &migrations).await?;
    Ok(())
}

fn remap_root_relative_path(path: &str, old_root: &str, new_root: &str) -> Option<String> {
    let normalized_path = normalize_path_for_key(path);
    let normalized_old_root = normalize_path_for_key(old_root);
    if normalized_path.is_empty() || normalized_old_root.is_empty() {
        return None;
    }
    let rel = Path::new(&normalized_path)
        .strip_prefix(Path::new(&normalized_old_root))
        .ok()?;
    let mut next = PathBuf::from(new_root.trim());
    if rel != Path::new("") {
        next.push(rel);
    }
    Some(next.to_string_lossy().into_owned())
}

fn target_resource_matches_kind(path: &str, resource_type: &str) -> Result<bool, HentaiError> {
    let Some(stat) = local_access().stat(path)? else {
        return Ok(false);
    };
    let expected_kind = if resource_type == "dir" {
        ResourceKind::Dir
    } else {
        ResourceKind::File
    };
    Ok(stat.kind == expected_kind)
}

fn target_resource_is_dir(path: &str) -> Result<bool, HentaiError> {
    let Some(stat) = local_access().stat(path)? else {
        return Ok(false);
    };
    Ok(stat.kind == ResourceKind::Dir)
}

async fn load_comics_ordered_for_connection<C: ConnectionTrait>(
    db: &C,
    comic_ids: &[String],
) -> Result<Vec<ComicDto>, HentaiError> {
    if comic_ids.is_empty() {
        return Ok(vec![]);
    }
    let models = Comics::find()
        .filter(crate::entity::comics::Column::ComicId.is_in(comic_ids.to_vec()))
        .all(db)
        .await
        .map_err(map_db_err)?;
    let meta_models = ComicMeta::find()
        .filter(crate::entity::comic_meta::Column::ComicId.is_in(comic_ids.to_vec()))
        .all(db)
        .await
        .map_err(map_db_err)?;
    let author_map = crate::author::load_author_names_for_comics(db, comic_ids).await?;
    let tag_map = load_named_rows(
        db,
        "comic_tags",
        "tag_name",
        comic_ids,
        "ORDER BY tag_name ASC",
    )
    .await?;
    let parody_map = load_named_rows(
        db,
        "comic_parodies",
        "parody_name",
        comic_ids,
        "ORDER BY parody_name ASC",
    )
    .await?;
    let character_map = load_named_rows(
        db,
        "comic_characters",
        "character_name",
        comic_ids,
        "ORDER BY character_name ASC",
    )
    .await?;
    let last_read_map = load_last_read_times_for_comics(db, comic_ids).await?;

    let mut by_id: HashMap<String, crate::entity::comics::Model> = models
        .into_iter()
        .map(|m| (m.comic_id.clone(), m))
        .collect();
    let meta_by_id: HashMap<String, crate::entity::comic_meta::Model> = meta_models
        .into_iter()
        .map(|m| (m.comic_id.clone(), m))
        .collect();
    let mut out = Vec::with_capacity(comic_ids.len());
    for comic_id in comic_ids {
        let Some(model) = by_id.remove(comic_id) else {
            continue;
        };
        let Some(meta) = meta_by_id.get(comic_id) else {
            continue;
        };
        out.push(ComicDto {
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
    Ok(out)
}

async fn load_full_comics_for_library<C: ConnectionTrait>(
    db: &C,
    library_id: &str,
) -> Result<Vec<ComicDto>, HentaiError> {
    let comic_ids = load_comic_ids_for_library(db, library_id).await?;
    load_comics_ordered_for_connection(db, &comic_ids).await
}

async fn load_last_read_times_for_comics<C: ConnectionTrait>(
    db: &C,
    comic_ids: &[String],
) -> Result<HashMap<String, i64>, HentaiError> {
    if comic_ids.is_empty() {
        return Ok(HashMap::new());
    }
    let placeholders = comic_ids.iter().map(|_| "?").collect::<Vec<_>>().join(",");
    let values: Vec<sea_orm::Value> = comic_ids
        .iter()
        .map(|id| sea_orm::Value::String(Some(Box::new(id.clone()))))
        .collect();
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "SELECT comic_id, last_read_time FROM comic_reading_histories \
                 WHERE comic_id IN ({placeholders})"
            ),
            values,
        ))
        .await
        .map_err(map_db_err)?;
    let mut out = HashMap::new();
    for row in rows {
        let comic_id = row
            .try_get_by_index::<String>(0)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
        let last_read_time = row
            .try_get_by_index::<i64>(1)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
        out.insert(comic_id, last_read_time);
    }
    Ok(out)
}

async fn load_named_rows<C: ConnectionTrait>(
    db: &C,
    table: &str,
    value_column: &str,
    comic_ids: &[String],
    order_clause: &str,
) -> Result<HashMap<String, Vec<String>>, HentaiError> {
    if comic_ids.is_empty() {
        return Ok(HashMap::new());
    }
    let placeholders = comic_ids.iter().map(|_| "?").collect::<Vec<_>>().join(",");
    let values: Vec<sea_orm::Value> = comic_ids
        .iter()
        .map(|id| sea_orm::Value::String(Some(Box::new(id.clone()))))
        .collect();
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "SELECT comic_id, {value_column} FROM {table} \
                 WHERE comic_id IN ({placeholders}) {order_clause}"
            ),
            values,
        ))
        .await
        .map_err(map_db_err)?;
    let mut out: HashMap<String, Vec<String>> = HashMap::new();
    for row in rows {
        let comic_id = row
            .try_get_by_index::<String>(0)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
        let value = row
            .try_get_by_index::<String>(1)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
        out.entry(comic_id).or_default().push(value);
    }
    Ok(out)
}

async fn load_comic_ids_for_library<C: ConnectionTrait>(
    db: &C,
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

pub(crate) fn ensure_local_root_not_nested(
    root: &str,
    exclude_library_id: Option<&str>,
    existing_libs: &[LibraryDto],
) -> Result<(), HentaiError> {
    let new_key = normalize_path_for_key(root);
    if new_key.is_empty() {
        return Err(HentaiError::validation("Library root 不能为空"));
    }
    for lib in existing_libs {
        if lib.kind != KIND_LOCAL {
            continue;
        }
        if exclude_library_id.is_some_and(|id| lib.library_id == id) {
            continue;
        }
        let other = normalize_path_for_key(&lib.root_path);
        if other.is_empty() {
            continue;
        }
        if new_key == other
            || new_key.starts_with(&format!("{other}/"))
            || other.starts_with(&format!("{new_key}/"))
        {
            return Err(HentaiError::validation(
                "Local library 的 Library root 不能互相嵌套",
            ));
        }
    }
    Ok(())
}
