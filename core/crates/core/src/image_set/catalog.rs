use sea_orm::{ColumnTrait, EntityTrait, QueryFilter};

use crate::db::{connection, map_db_err};
use crate::entity::{image_set_images, image_sets};
use crate::error::HentaiError;
use crate::util::natural_sort::compare_filename_natural;

use super::dto::{ImageSetDto, ImageSetImageDto};

/// Image sets of one library in natural order by name (legacy `is_root` rows still sort first).
pub async fn list_image_sets(library_id: &str) -> Result<Vec<ImageSetDto>, HentaiError> {
    let db = connection()?;
    let mut rows = image_sets::Entity::find()
        .filter(image_sets::Column::LibraryId.eq(library_id))
        .all(&db)
        .await
        .map_err(map_db_err)?;
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

/// Image set images of one set, in natural order of their location keys.
pub async fn list_image_set_images(
    library_id: &str,
    image_set_id: &str,
) -> Result<Vec<ImageSetImageDto>, HentaiError> {
    let db = connection()?;
    let mut rows = image_set_images::Entity::find()
        .filter(image_set_images::Column::LibraryId.eq(library_id))
        .filter(image_set_images::Column::ImageSetId.eq(image_set_id))
        .all(&db)
        .await
        .map_err(map_db_err)?;
    rows.sort_by(|a, b| compare_filename_natural(&location_key(a), &location_key(b)));
    Ok(rows
        .into_iter()
        .map(|row| ImageSetImageDto {
            image_set_image_id: row.image_set_image_id,
            image_set_id: row.image_set_id,
            library_id: row.library_id,
            carrier_relative_path: row.carrier_relative_path,
            member_path: row.member_path,
            carrier_kind: row.carrier_kind,
            name: row.name,
        })
        .collect())
}

fn location_key(row: &image_set_images::Model) -> String {
    if row.member_path.is_empty() {
        row.carrier_relative_path.clone()
    } else {
        format!("{}/{}", row.carrier_relative_path, row.member_path)
    }
}
