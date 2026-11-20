use std::collections::HashSet;

use sea_orm::sea_query::Expr;
use sea_orm::{
    ActiveModelTrait, ColumnTrait, ConnectionTrait, EntityTrait, QueryFilter, Set,
    TransactionTrait,
};

use crate::db::{connection, map_db_err};
use crate::entity::{image_set_images, image_sets};
use crate::error::HentaiError;
use crate::library_write::with_library_write;

/// Sets exclude for one or many Image set images in one set (catalog-only; no disk I/O).
pub async fn set_image_set_images_excluded(
    library_id: &str,
    image_set_id: &str,
    image_ids: &[String],
    excluded: bool,
) -> Result<(), HentaiError> {
    if image_ids.is_empty() {
        return Ok(());
    }
    with_library_write(|| async {
        let db = connection()?;
        let txn = db.begin().await.map_err(|e| map_db_err(&e))?;
        require_set(&txn, library_id, image_set_id).await?;
        let rows = load_set_images(&txn, library_id, image_set_id).await?;
        let known: HashSet<&str> = rows
            .iter()
            .map(|row| row.image_set_image_id.as_str())
            .collect();
        for id in image_ids {
            if !known.contains(id.as_str()) {
                return Err(HentaiError::validation(format!(
                    "图集图片不属于该图集: {id}"
                )));
            }
        }
        image_set_images::Entity::update_many()
            .col_expr(image_set_images::Column::Excluded, Expr::value(excluded))
            .filter(image_set_images::Column::ImageSetImageId.is_in(image_ids.to_vec()))
            .exec(&txn)
            .await
            .map_err(|e| map_db_err(&e))?;
        txn.commit().await.map_err(|e| map_db_err(&e))?;
        crate::revision::notify_committed();
        Ok(())
    })
    .await
}

/// Authoritative full-set reorder: `ordered_ids` must list every image in the set exactly once.
pub async fn reorder_image_set_images(
    library_id: &str,
    image_set_id: &str,
    ordered_ids: &[String],
) -> Result<(), HentaiError> {
    with_library_write(|| async {
        let db = connection()?;
        let txn = db.begin().await.map_err(|e| map_db_err(&e))?;
        require_set(&txn, library_id, image_set_id).await?;
        let rows = load_set_images(&txn, library_id, image_set_id).await?;
        validate_full_permutation(&rows, ordered_ids)?;
        let by_id: std::collections::HashMap<&str, &image_set_images::Model> = rows
            .iter()
            .map(|row| (row.image_set_image_id.as_str(), row))
            .collect();
        for (sort_order, id) in ordered_ids.iter().enumerate() {
            let Some(row) = by_id.get(id.as_str()) else {
                return Err(HentaiError::validation(format!(
                    "图集图片不属于该图集: {id}"
                )));
            };
            let mut active: image_set_images::ActiveModel = (*row).clone().into();
            active.sort_order = Set(sort_order as i64);
            active.update(&txn).await.map_err(|e| map_db_err(&e))?;
        }
        txn.commit().await.map_err(|e| map_db_err(&e))?;
        crate::revision::notify_committed();
        Ok(())
    })
    .await
}

fn validate_full_permutation(
    rows: &[image_set_images::Model],
    ordered_ids: &[String],
) -> Result<(), HentaiError> {
    if ordered_ids.len() != rows.len() {
        return Err(HentaiError::validation(
            "排序列表必须包含该图集的全部图片且数量一致".to_string(),
        ));
    }
    let mut seen = HashSet::new();
    let known: HashSet<&str> = rows
        .iter()
        .map(|row| row.image_set_image_id.as_str())
        .collect();
    for id in ordered_ids {
        if !known.contains(id.as_str()) {
            return Err(HentaiError::validation(format!(
                "图集图片不属于该图集: {id}"
            )));
        }
        if !seen.insert(id.as_str()) {
            return Err(HentaiError::validation(format!("排序列表含重复图片: {id}")));
        }
    }
    Ok(())
}

async fn require_set<C: ConnectionTrait>(
    db: &C,
    library_id: &str,
    image_set_id: &str,
) -> Result<image_sets::Model, HentaiError> {
    let set = image_sets::Entity::find_by_id(image_set_id)
        .one(db)
        .await
        .map_err(|e| map_db_err(&e))?
        .ok_or_else(|| HentaiError::validation(format!("图集不存在: {image_set_id}")))?;
    if set.library_id != library_id {
        return Err(HentaiError::validation("图集不属于该图集库".to_string()));
    }
    Ok(set)
}

async fn load_set_images<C: ConnectionTrait>(
    db: &C,
    library_id: &str,
    image_set_id: &str,
) -> Result<Vec<image_set_images::Model>, HentaiError> {
    image_set_images::Entity::find()
        .filter(image_set_images::Column::LibraryId.eq(library_id))
        .filter(image_set_images::Column::ImageSetId.eq(image_set_id))
        .all(db)
        .await
        .map_err(|e| map_db_err(&e))
}
