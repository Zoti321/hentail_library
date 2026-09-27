use std::collections::HashMap;

use sea_orm::{
    ColumnTrait, ConnectionTrait, DatabaseConnection, EntityTrait, QueryFilter, Set, Statement,
    TransactionTrait,
};

use crate::db::map_db_err;
use crate::entity::{library_resource_snapshots, prelude::*};
use crate::error::HentaiError;
use crate::library::LibraryDto;
use crate::resource::read_source_stat_with;
use crate::resource::{local_access, ResourceAccess};
use crate::sync::scanner::ScanItem;

use super::scan_item_location_key;

pub async fn load_snapshot_map(
    db: &DatabaseConnection,
    library_id: &str,
) -> Result<HashMap<String, (i64, i64, String)>, HentaiError> {
    let rows = LibraryResourceSnapshots::find()
        .filter(library_resource_snapshots::Column::LibraryId.eq(library_id))
        .all(db)
        .await
        .map_err(map_db_err)?;
    Ok(rows
        .into_iter()
        .map(|row| {
            (
                row.location_key,
                (row.modified_ms, row.size, row.resource_type),
            )
        })
        .collect())
}

pub async fn rebuild_snapshot_from_scan_items(
    db: &DatabaseConnection,
    library_id: &str,
    library: &LibraryDto,
    scan_items: &[ScanItem],
) -> Result<(), HentaiError> {
    let access: &dyn ResourceAccess = local_access();
    let txn = db.begin().await.map_err(map_db_err)?;
    LibraryResourceSnapshots::delete_many()
        .filter(library_resource_snapshots::Column::LibraryId.eq(library_id))
        .exec(&txn)
        .await
        .map_err(map_db_err)?;

    for item in scan_items {
        let location_key = scan_item_location_key(library, item);
        if location_key.is_empty() {
            continue;
        }
        let (modified_ms, size) = if library.kind == "remote" {
            (
                item.comic.last_updated_at,
                item.comic.resource_size,
            )
        } else {
            read_source_stat_with(access, &item.path, &item.resource_type)?
                .unwrap_or((item.comic.last_updated_at, item.comic.resource_size))
        };
        let active = library_resource_snapshots::ActiveModel {
            library_id: Set(library_id.to_string()),
            location_key: Set(location_key),
            resource_type: Set(item.resource_type.clone()),
            modified_ms: Set(modified_ms),
            size: Set(size),
        };
        LibraryResourceSnapshots::insert(active)
            .exec(&txn)
            .await
            .map_err(map_db_err)?;
    }
    txn.commit().await.map_err(map_db_err)?;
    Ok(())
}

pub async fn delete_snapshots_for_library<C: ConnectionTrait>(
    db: &C,
    library_id: &str,
) -> Result<(), HentaiError> {
    LibraryResourceSnapshots::delete_many()
        .filter(library_resource_snapshots::Column::LibraryId.eq(library_id))
        .exec(db)
        .await
        .map_err(map_db_err)?;
    Ok(())
}

pub async fn snapshot_row_count(
    db: &DatabaseConnection,
    library_id: &str,
) -> Result<i64, HentaiError> {
    let row = db
        .query_one(Statement::from_sql_and_values(
            db.get_database_backend(),
            "SELECT COUNT(*) AS c FROM library_resource_snapshots WHERE library_id = ?",
            [sea_orm::Value::String(Some(Box::new(library_id.to_string())))],
        ))
        .await
        .map_err(map_db_err)?;
    Ok(row
        .and_then(|r| r.try_get::<i64>("", "c").ok())
        .unwrap_or(0))
}
