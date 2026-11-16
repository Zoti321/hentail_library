use sea_orm::{ColumnTrait, DatabaseTransaction, EntityTrait, QueryFilter};

use crate::db::map_db_err;
use crate::entity::{image_set_carriers, image_set_images, image_sets};
use crate::error::HentaiError;

use super::plan::ImageSetPlan;

const CHUNK: usize = 400;

/// Applies the plan in dependency order: children are removed before parents, and parents are inserted before children.
pub(crate) async fn apply_image_set_plan(
    txn: &DatabaseTransaction,
    library_id: &str,
    plan: &ImageSetPlan,
) -> Result<(), HentaiError> {
    for chunk in plan.images_delete.chunks(CHUNK) {
        image_set_images::Entity::delete_many()
            .filter(image_set_images::Column::ImageSetImageId.is_in(chunk.to_vec()))
            .exec(txn)
            .await
            .map_err(map_db_err)?;
    }
    for chunk in plan.carriers_delete.chunks(CHUNK) {
        image_set_carriers::Entity::delete_many()
            .filter(image_set_carriers::Column::LibraryId.eq(library_id))
            .filter(image_set_carriers::Column::CarrierRelativePath.is_in(chunk.to_vec()))
            .exec(txn)
            .await
            .map_err(map_db_err)?;
    }
    for chunk in plan.sets_delete.chunks(CHUNK) {
        image_sets::Entity::delete_many()
            .filter(image_sets::Column::ImageSetId.is_in(chunk.to_vec()))
            .exec(txn)
            .await
            .map_err(map_db_err)?;
    }
    for chunk in plan.sets_insert.chunks(CHUNK) {
        image_sets::Entity::insert_many(chunk.iter().cloned().map(image_sets::ActiveModel::from))
            .exec(txn)
            .await
            .map_err(map_db_err)?;
    }
    for chunk in plan.carriers_insert.chunks(CHUNK) {
        image_set_carriers::Entity::insert_many(
            chunk
                .iter()
                .cloned()
                .map(image_set_carriers::ActiveModel::from),
        )
        .exec(txn)
        .await
        .map_err(map_db_err)?;
    }
    for chunk in plan.images_insert.chunks(CHUNK) {
        image_set_images::Entity::insert_many(
            chunk
                .iter()
                .cloned()
                .map(image_set_images::ActiveModel::from),
        )
        .exec(txn)
        .await
        .map_err(map_db_err)?;
    }
    Ok(())
}
