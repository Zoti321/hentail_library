use sea_orm::{ActiveModelTrait, EntityTrait, Set};

use crate::db::{connection, map_db_err};
use crate::entity::image_sets;
use crate::error::HentaiError;

#[derive(Debug, Clone, Default)]
pub struct UpdateImageSetUserMetaDto {
    pub name: Option<String>,
}

/// Partial patch for Image set Metadata field locks (`None` = leave unchanged).
#[derive(Debug, Clone, Default)]
pub struct SetImageSetMetaLocksDto {
    pub name: Option<bool>,
}

/// User Image set metadata write; a written name is trimmed and auto-locked.
pub async fn update_image_set_user_meta(
    image_set_id: &str,
    meta: UpdateImageSetUserMetaDto,
) -> Result<(), HentaiError> {
    let Some(name) = meta.name else {
        return Ok(());
    };
    let name = name.trim();
    if name.is_empty() {
        return Err(HentaiError::validation("图集名称不能为空".to_string()));
    }
    let mut active: image_sets::ActiveModel = find_image_set(image_set_id).await?.into();
    active.name = Set(name.to_string());
    active.name_locked = Set(true);
    active.update(&connection()?).await.map_err(map_db_err)?;
    crate::revision::notify_committed();
    Ok(())
}

/// Sets Metadata field locks only; unlocking does not rescan (the next sync merges).
pub async fn set_image_set_meta_locks(
    image_set_id: &str,
    locks: SetImageSetMetaLocksDto,
) -> Result<(), HentaiError> {
    let Some(name_locked) = locks.name else {
        return Ok(());
    };
    let mut active: image_sets::ActiveModel = find_image_set(image_set_id).await?.into();
    active.name_locked = Set(name_locked);
    active.update(&connection()?).await.map_err(map_db_err)?;
    crate::revision::notify_committed();
    Ok(())
}

async fn find_image_set(image_set_id: &str) -> Result<image_sets::Model, HentaiError> {
    image_sets::Entity::find_by_id(image_set_id)
        .one(&connection()?)
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::validation(format!("图集不存在: {image_set_id}")))
}
