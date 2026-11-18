use sea_orm::{ActiveModelTrait, ConnectionTrait, EntityTrait, Set, TransactionTrait};

use crate::author::{load_image_set_author_names, replace_image_set_authors};
use crate::db::{connection, map_db_err};
use crate::entity::image_sets;
use crate::error::HentaiError;
use crate::named_facet::{
    load_image_set_named_facet, replace_image_set_named_facet, JunctionNamedFacet,
};

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
    let db = connection()?;
    let mut active: image_sets::ActiveModel = find_image_set(&db, image_set_id).await?.into();
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
    let db = connection()?;
    let mut active: image_sets::ActiveModel = find_image_set(&db, image_set_id).await?.into();
    active.name_locked = Set(name_locked);
    active.update(&connection()?).await.map_err(map_db_err)?;
    crate::revision::notify_committed();
    Ok(())
}

/// Author / Tag / Parody / Character bindings of one Image set (each name ASC).
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ImageSetFacetsDto {
    pub authors: Vec<String>,
    pub tags: Vec<String>,
    pub parodies: Vec<String>,
    pub characters: Vec<String>,
}

/// Replace-all facet patch (`None` = leave unchanged, empty = clear). No Metadata field lock:
/// sync never rewrites these bindings.
#[derive(Debug, Clone, Default)]
pub struct UpdateImageSetFacetsDto {
    pub authors: Option<Vec<String>>,
    pub tags: Option<Vec<String>>,
    pub parodies: Option<Vec<String>>,
    pub characters: Option<Vec<String>>,
}

pub async fn get_image_set_facets(image_set_id: &str) -> Result<ImageSetFacetsDto, HentaiError> {
    let db = connection()?;
    find_image_set(&db, image_set_id).await?;
    Ok(ImageSetFacetsDto {
        authors: load_image_set_author_names(&db, image_set_id).await?,
        tags: load_image_set_named_facet(&db, JunctionNamedFacet::Tag, image_set_id).await?,
        parodies: load_image_set_named_facet(&db, JunctionNamedFacet::Parody, image_set_id).await?,
        characters: load_image_set_named_facet(&db, JunctionNamedFacet::Character, image_set_id)
            .await?,
    })
}

pub async fn update_image_set_facets(
    image_set_id: &str,
    patch: UpdateImageSetFacetsDto,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let txn = db.begin().await.map_err(map_db_err)?;
    find_image_set(&txn, image_set_id).await?;
    if let Some(authors) = &patch.authors {
        replace_image_set_authors(&txn, image_set_id, authors).await?;
    }
    for (facet, names) in [
        (JunctionNamedFacet::Tag, &patch.tags),
        (JunctionNamedFacet::Parody, &patch.parodies),
        (JunctionNamedFacet::Character, &patch.characters),
    ] {
        if let Some(names) = names {
            replace_image_set_named_facet(&txn, facet, image_set_id, names).await?;
        }
    }
    txn.commit().await.map_err(map_db_err)?;
    crate::revision::notify_committed();
    Ok(())
}

async fn find_image_set<C: ConnectionTrait>(
    db: &C,
    image_set_id: &str,
) -> Result<image_sets::Model, HentaiError> {
    image_sets::Entity::find_by_id(image_set_id)
        .one(db)
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::validation(format!("图集不存在: {image_set_id}")))
}
