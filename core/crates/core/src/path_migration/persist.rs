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

/// rekey 时按 `comic_id` 批量重指的 Comic 子表（唯一来源）。
///
/// [`apply_comic_rekey`] 只遍历本清单。`comics` 与 `comic_meta` 由显式 re-insert
/// 处理，故列在 `COMIC_REKEY_VIA_REINSERT`。模块测试
/// `comic_child_tables_cover_all_comic_id_columns` 断言 schema 中任何带 `comic_id`
/// 列的表都被覆盖，新增子表若漏登记会红灯。
const COMIC_CHILD_TABLES: &[&str] = &[
    "comic_tags",
    "comic_authors",
    "comic_parodies",
    "comic_characters",
    "comic_reading_histories",
    "comic_thumbnails",
    "series_items",
];

/// 带 `comic_id`、但在 rekey 时由显式 re-insert 处理（非批量 UPDATE）的表。
/// 仅守卫测试使用；生产路径不读取它。
#[cfg(test)]
const COMIC_REKEY_VIA_REINSERT: &[&str] = &["comics", "comic_meta"];

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

    for table in COMIC_CHILD_TABLES {
        rekey_comic_child_table(db, table, from_id, to_id).await?;
    }
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

#[cfg(test)]
mod tests {
    use super::*;
    use sea_orm::Database;
    use sea_orm_migration::MigratorTrait;

    /// 迁移到最新 schema 后，列出所有带 `comic_id` 列的表。
    async fn tables_with_comic_id() -> Vec<String> {
        let db = Database::connect("sqlite::memory:")
            .await
            .expect("in-memory db");
        crate::migration::Migrator::up(&db, None)
            .await
            .expect("run migrations");
        let rows = db
            .query_all(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "SELECT name FROM sqlite_master WHERE type = 'table'".to_string(),
            ))
            .await
            .expect("list tables");
        let mut with_comic_id = Vec::new();
        for row in rows {
            let name: String = row.try_get_by_index(0).expect("table name");
            let cols = db
                .query_all(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    format!("PRAGMA table_info('{name}')"),
                ))
                .await
                .expect("table_info");
            let has_comic_id = cols.iter().any(|col| {
                col.try_get_by_index::<String>(1)
                    .map(|col_name| col_name == "comic_id")
                    .unwrap_or(false)
            });
            if has_comic_id {
                with_comic_id.push(name);
            }
        }
        with_comic_id
    }

    #[tokio::test]
    async fn comic_child_tables_cover_all_comic_id_columns() {
        let with_comic_id = tables_with_comic_id().await;

        for table in COMIC_CHILD_TABLES {
            assert!(
                with_comic_id.iter().any(|t| t == table),
                "COMIC_CHILD_TABLES 中的 {table} 在 schema 中不存在或已无 comic_id 列"
            );
        }
        for table in &with_comic_id {
            let covered = COMIC_CHILD_TABLES.contains(&table.as_str())
                || COMIC_REKEY_VIA_REINSERT.contains(&table.as_str());
            assert!(
                covered,
                "表 {table} 带 comic_id 列但未纳入 rekey；请加入 COMIC_CHILD_TABLES 或 COMIC_REKEY_VIA_REINSERT"
            );
        }
    }
}
