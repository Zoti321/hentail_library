use sea_orm::{ColumnTrait, EntityTrait, QueryFilter};

use crate::db::{connection, map_db_err};
use crate::entity::{image_set_images, image_sets};
use crate::error::HentaiError;
use crate::util::natural_sort::compare_filename_natural;

use super::dto::{ImageSetDto, ImageSetImageDto};

fn image_set_image_from_row(row: image_set_images::Model) -> ImageSetImageDto {
    ImageSetImageDto {
        image_set_image_id: row.image_set_image_id,
        image_set_id: row.image_set_id,
        library_id: row.library_id,
        carrier_relative_path: row.carrier_relative_path,
        member_path: row.member_path,
        carrier_kind: row.carrier_kind,
        name: row.name,
        excluded: row.excluded,
    }
}

fn sort_image_set_images(rows: &mut [image_set_images::Model]) {
    rows.sort_by(|a, b| {
        a.sort_order
            .cmp(&b.sort_order)
            .then_with(|| a.image_set_image_id.cmp(&b.image_set_image_id))
    });
}

/// Image sets of one library in natural order by name (legacy `is_root` rows still sort first).
pub async fn list_image_sets(library_id: &str) -> Result<Vec<ImageSetDto>, HentaiError> {
    let db = connection()?;
    let mut rows = image_sets::Entity::find()
        .filter(image_sets::Column::LibraryId.eq(library_id))
        .all(&db)
        .await
        .map_err(|e| map_db_err(&e))?;
    rows.sort_by(|a, b| {
        b.is_root
            .cmp(&a.is_root)
            .then_with(|| compare_filename_natural(&a.name, &b.name))
    });
    Ok(rows
        .into_iter()
        .map(|row| ImageSetDto {
            image_set_id: row.image_set_id,
            library_id: row.library_id,
            relative_path: row.relative_path,
            name: row.name,
            is_root: row.is_root,
            name_locked: row.name_locked,
        })
        .collect())
}

/// Default workspace view: non-excluded images in user `sort_order` (ADR-0064).
pub async fn list_image_set_images(
    library_id: &str,
    image_set_id: &str,
) -> Result<Vec<ImageSetImageDto>, HentaiError> {
    let db = connection()?;
    let mut rows = image_set_images::Entity::find()
        .filter(image_set_images::Column::LibraryId.eq(library_id))
        .filter(image_set_images::Column::ImageSetId.eq(image_set_id))
        .filter(image_set_images::Column::Excluded.eq(false))
        .all(&db)
        .await
        .map_err(|e| map_db_err(&e))?;
    sort_image_set_images(&mut rows);
    Ok(rows
        .into_iter()
        .map(|mut row| {
            row.excluded = false;
            image_set_image_from_row(row)
        })
        .collect())
}

/// Manage workspace view: all members in user `sort_order` with real `excluded` flag.
pub async fn list_image_set_workspace_images(
    library_id: &str,
    image_set_id: &str,
) -> Result<Vec<ImageSetImageDto>, HentaiError> {
    let db = connection()?;
    let mut rows = image_set_images::Entity::find()
        .filter(image_set_images::Column::LibraryId.eq(library_id))
        .filter(image_set_images::Column::ImageSetId.eq(image_set_id))
        .all(&db)
        .await
        .map_err(|e| map_db_err(&e))?;
    sort_image_set_images(&mut rows);
    Ok(rows.into_iter().map(image_set_image_from_row).collect())
}
