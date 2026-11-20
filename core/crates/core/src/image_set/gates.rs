use sea_orm::{ActiveModelTrait, EntityTrait, Set};

use crate::db::{connection, map_db_err};
use crate::entity::libraries;
use crate::error::HentaiError;
use crate::library::is_image_set_catalog;
use crate::library_write::with_library_write;

/// Per Local Image set library opt-in gates (ADR-0064). Defaults false.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ImageSetLibraryGatesDto {
    pub resource_mutation: bool,
    pub managed_layout: bool,
}

pub async fn get_image_set_library_gates(
    library_id: &str,
) -> Result<ImageSetLibraryGatesDto, HentaiError> {
    let lib = require_local_image_set_library(library_id).await?;
    Ok(ImageSetLibraryGatesDto {
        resource_mutation: lib.image_set_resource_mutation != 0,
        managed_layout: lib.image_set_managed_layout != 0,
    })
}

pub async fn set_image_set_resource_mutation(
    library_id: &str,
    enabled: bool,
) -> Result<(), HentaiError> {
    with_library_write(|| async {
        let lib = require_local_image_set_library(library_id).await?;
        let mut active: libraries::ActiveModel = lib.into();
        active.image_set_resource_mutation = Set(i32::from(enabled));
        active.update(&connection()?).await.map_err(|e| map_db_err(&e))?;
        crate::revision::notify_committed();
        Ok(())
    })
    .await
}

pub async fn set_image_set_managed_layout(
    library_id: &str,
    enabled: bool,
) -> Result<(), HentaiError> {
    with_library_write(|| async {
        let lib = require_local_image_set_library(library_id).await?;
        let mut active: libraries::ActiveModel = lib.into();
        active.image_set_managed_layout = Set(i32::from(enabled));
        active.update(&connection()?).await.map_err(|e| map_db_err(&e))?;
        crate::revision::notify_committed();
        Ok(())
    })
    .await
}

async fn require_local_image_set_library(
    library_id: &str,
) -> Result<libraries::Model, HentaiError> {
    let db = connection()?;
    let lib = libraries::Entity::find_by_id(library_id)
        .one(&db)
        .await
        .map_err(|e| map_db_err(&e))?
        .ok_or_else(|| HentaiError::validation("Library is unavailable"))?;
    if lib.kind != "local" {
        return Err(HentaiError::validation(
            "Image set resource mutation is only available for Local Image set libraries",
        ));
    }
    if !is_image_set_catalog(&lib.catalog_kind) {
        return Err(HentaiError::validation(
            "Image set resource mutation is only available for Image set libraries",
        ));
    }
    Ok(lib)
}
