//! Path migration 的落库实现：把配对结果 rekey 到新 Comic / Series 身份。
//!
//! 与 [`super::pairing`] 同属一个 Path migration 模块。本模块只负责数据库写入，
//! 且**不自行开启事务**——调用方（Library sync 或 Local 改根）持有事务，保证整轮写入原子。

use sea_orm::{ConnectionTrait, EntityTrait, Set, Statement};

use crate::db::map_db_err;
use crate::entity::{comic_meta, comics, prelude::*};
use crate::error::HentaiError;
use crate::series_id::series_name_from_folder_path;
use crate::util::compute_sort_key;

use super::pairing::{ComicMigration, SeriesMigrationPair};

/// 批量 rekey Comic（参与调用方事务）。
pub(crate) async fn apply_comic_rekeys<C: ConnectionTrait>(
    db: &C,
    migrations: &[ComicMigration],
) -> Result<(), HentaiError> {
    for migration in migrations {
        apply_comic_rekey(db, migration).await?;
    }
    Ok(())
}

async fn apply_comic_rekey<C: ConnectionTrait>(
    db: &C,
    migration: &ComicMigration,
) -> Result<(), HentaiError> {
    let from_id = &migration.from_comic_id;
    let comic = &migration.to_comic;
    let to_id = &comic.comic_id;
    let deleted_at = Comics::find_by_id(from_id.clone())
        .one(db)
        .await
        .map_err(map_db_err)?
        .and_then(|row| row.deleted_at);

    let comic_active = comics::ActiveModel {
        comic_id: Set(to_id.clone()),
        path: Set(comic.path.clone()),
        resource_type: Set(comic.resource_type.clone()),
        resource_size: Set(comic.resource_size),
        created_at: Set(comic.created_at),
        last_updated_at: Set(comic.last_updated_at),
        library_id: Set(comic.library_id.clone()),
        deleted_at: Set(deleted_at),
    };
    Comics::insert(comic_active)
        .exec(db)
        .await
        .map_err(map_db_err)?;

    let meta_active = comic_meta::ActiveModel {
        comic_id: Set(to_id.clone()),
        title: Set(comic.title.clone()),
        title_sort_key: Set(compute_sort_key(&comic.title)),
        content_rating: Set(comic.content_rating.clone()),
        page_count: Set(comic.page_count),
        description: Set(comic.description.clone()),
        published_at: Set(comic.published_at),
        title_locked: Set(comic.locks.title),
        description_locked: Set(comic.locks.description),
        published_at_locked: Set(comic.locks.published_at),
        content_rating_locked: Set(comic.locks.content_rating),
        authors_locked: Set(comic.locks.authors),
        tags_locked: Set(comic.locks.tags),
        languages: Set(crate::comic::serialize_languages(&comic.languages)),
        languages_locked: Set(comic.locks.languages),
        parodies_locked: Set(comic.locks.parodies),
        characters_locked: Set(comic.locks.characters),
    };
    ComicMeta::insert(meta_active)
        .exec(db)
        .await
        .map_err(map_db_err)?;

    rekey_comic_child_table(db, "comic_tags", from_id, to_id).await?;
    rekey_comic_child_table(db, "comic_authors", from_id, to_id).await?;
    rekey_comic_child_table(db, "comic_parodies", from_id, to_id).await?;
    rekey_comic_child_table(db, "comic_characters", from_id, to_id).await?;
    rekey_comic_child_table(db, "comic_reading_histories", from_id, to_id).await?;
    rekey_comic_child_table(db, "comic_thumbnails", from_id, to_id).await?;
    rekey_comic_child_table(db, "series_items", from_id, to_id).await?;
    rekey_reference_column(db, "series_thumbnails", "source_comic_id", from_id, to_id).await?;

    Comics::delete_by_id(from_id.clone())
        .exec(db)
        .await
        .map_err(map_db_err)?;
    Ok(())
}

/// 批量 rekey Series（参与调用方事务）。
///
/// 目标 series_id 仍被占用时延后处理，避免迁移环；仍无法推进则跳过，
/// 交由后续 orphan / series rebuild 收尾。
pub(crate) async fn apply_series_rekeys<C: ConnectionTrait>(
    db: &C,
    migrations: &[SeriesMigrationPair],
) -> Result<(), HentaiError> {
    if migrations.is_empty() {
        return Ok(());
    }
    let mut pending: Vec<SeriesMigrationPair> = migrations.to_vec();
    while !pending.is_empty() {
        let before = pending.len();
        let mut deferred = Vec::new();
        for migration in pending {
            let target_exists = Series::find_by_id(migration.to_series_id.clone())
                .one(db)
                .await
                .map_err(map_db_err)?
                .is_some();
            if target_exists {
                deferred.push(migration);
                continue;
            }
            apply_series_rekey(db, &migration).await?;
        }
        pending = deferred;
        if pending.len() == before {
            // Target still occupied (cycle/conflict): skip; orphan + rebuild handles the rest.
            break;
        }
    }
    Ok(())
}

async fn apply_series_rekey<C: ConnectionTrait>(
    db: &C,
    migration: &SeriesMigrationPair,
) -> Result<(), HentaiError> {
    let from_id = &migration.from_series_id;
    let to_id = &migration.to_series_id;
    let Some(row) = Series::find_by_id(from_id.clone())
        .one(db)
        .await
        .map_err(map_db_err)?
    else {
        return Ok(());
    };

    let new_name = if row.name_locked {
        row.name.clone()
    } else {
        series_name_from_folder_path(&migration.to_folder_path)
    };
    let active = crate::entity::series::ActiveModel {
        series_id: Set(to_id.clone()),
        folder_path: Set(migration.to_folder_path.clone()),
        name: Set(new_name.clone()),
        name_sort_key: Set(compute_sort_key(&new_name)),
        serialization_status: Set(row.serialization_status.clone()),
        total_count: Set(row.total_count),
        name_locked: Set(row.name_locked),
        serialization_status_locked: Set(row.serialization_status_locked),
        total_count_locked: Set(row.total_count_locked),
        library_id: Set(row.library_id.clone()),
    };
    Series::insert(active).exec(db).await.map_err(map_db_err)?;
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "UPDATE series_items SET series_id = ? WHERE series_id = ?",
        [
            sea_orm::Value::String(Some(Box::new(to_id.clone()))),
            sea_orm::Value::String(Some(Box::new(from_id.clone()))),
        ],
    ))
    .await
    .map_err(map_db_err)?;
    rekey_reference_column(db, "series_thumbnails", "series_id", from_id, to_id).await?;
    Series::delete_by_id(from_id.clone())
        .exec(db)
        .await
        .map_err(map_db_err)?;
    Ok(())
}

async fn rekey_comic_child_table<C: ConnectionTrait>(
    db: &C,
    table: &str,
    from_id: &str,
    to_id: &str,
) -> Result<(), HentaiError> {
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("UPDATE {table} SET comic_id = ? WHERE comic_id = ?"),
        [
            sea_orm::Value::String(Some(Box::new(to_id.to_string()))),
            sea_orm::Value::String(Some(Box::new(from_id.to_string()))),
        ],
    ))
    .await
    .map_err(map_db_err)?;
    Ok(())
}

async fn rekey_reference_column<C: ConnectionTrait>(
    db: &C,
    table: &str,
    column: &str,
    from_id: &str,
    to_id: &str,
) -> Result<(), HentaiError> {
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("UPDATE {table} SET {column} = ? WHERE {column} = ?"),
        [
            sea_orm::Value::String(Some(Box::new(to_id.to_string()))),
            sea_orm::Value::String(Some(Box::new(from_id.to_string()))),
        ],
    ))
    .await
    .map_err(map_db_err)?;
    Ok(())
}
