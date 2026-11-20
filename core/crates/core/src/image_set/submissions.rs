use std::collections::HashSet;

use sea_orm::{
    ActiveModelTrait, ColumnTrait, ConnectionTrait, EntityTrait, QueryFilter, QueryOrder, Set,
    TransactionTrait,
};

use crate::db::{connection, map_db_err};
use crate::entity::{image_set_submission_members, image_set_submissions};
use crate::error::HentaiError;
use crate::library_write::with_library_write;
use crate::util::millis_now;

use super::ids::image_set_submission_id;
use super::workspace::{load_set_images, require_set};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImageSetSubmissionDto {
    pub submission_id: String,
    pub library_id: String,
    pub image_set_id: String,
    pub name: String,
    pub member_image_ids: Vec<String>,
}

pub async fn list_image_set_submissions(
    library_id: &str,
    image_set_id: &str,
) -> Result<Vec<ImageSetSubmissionDto>, HentaiError> {
    let db = connection()?;
    require_set(&db, library_id, image_set_id).await?;
    let rows = image_set_submissions::Entity::find()
        .filter(image_set_submissions::Column::LibraryId.eq(library_id))
        .filter(image_set_submissions::Column::ImageSetId.eq(image_set_id))
        .order_by_asc(image_set_submissions::Column::Name)
        .order_by_asc(image_set_submissions::Column::SubmissionId)
        .all(&db)
        .await
        .map_err(|e| map_db_err(&e))?;
    let mut out = Vec::with_capacity(rows.len());
    for row in rows {
        let member_image_ids = load_member_ids(&db, &row.submission_id).await?;
        out.push(ImageSetSubmissionDto {
            submission_id: row.submission_id,
            library_id: row.library_id,
            image_set_id: row.image_set_id,
            name: row.name,
            member_image_ids,
        });
    }
    Ok(out)
}

pub async fn create_image_set_submission(
    library_id: &str,
    image_set_id: &str,
    name: &str,
) -> Result<ImageSetSubmissionDto, HentaiError> {
    let now = millis_now();
    let name = resolve_create_submission_name(name, now);
    with_library_write(|| async {
        let db = connection()?;
        let txn = db.begin().await.map_err(|e| map_db_err(&e))?;
        require_set(&txn, library_id, image_set_id).await?;
        let submission_id = image_set_submission_id(library_id, image_set_id, &name, now);
        let row = image_set_submissions::ActiveModel {
            submission_id: Set(submission_id.clone()),
            library_id: Set(library_id.to_string()),
            image_set_id: Set(image_set_id.to_string()),
            name: Set(name.clone()),
        };
        row.insert(&txn).await.map_err(|e| map_db_err(&e))?;
        txn.commit().await.map_err(|e| map_db_err(&e))?;
        crate::revision::notify_committed();
        Ok(ImageSetSubmissionDto {
            submission_id,
            library_id: library_id.to_string(),
            image_set_id: image_set_id.to_string(),
            name,
            member_image_ids: Vec::new(),
        })
    })
    .await
}

pub async fn rename_image_set_submission(
    library_id: &str,
    submission_id: &str,
    name: &str,
) -> Result<(), HentaiError> {
    let name = require_name(name)?;
    with_library_write(|| async {
        let db = connection()?;
        let txn = db.begin().await.map_err(|e| map_db_err(&e))?;
        let row = require_submission(&txn, library_id, submission_id).await?;
        let mut active: image_set_submissions::ActiveModel = row.into();
        active.name = Set(name);
        active.update(&txn).await.map_err(|e| map_db_err(&e))?;
        txn.commit().await.map_err(|e| map_db_err(&e))?;
        crate::revision::notify_committed();
        Ok(())
    })
    .await
}

pub async fn delete_image_set_submission(
    library_id: &str,
    submission_id: &str,
) -> Result<(), HentaiError> {
    with_library_write(|| async {
        let db = connection()?;
        let txn = db.begin().await.map_err(|e| map_db_err(&e))?;
        let _ = require_submission(&txn, library_id, submission_id).await?;
        image_set_submissions::Entity::delete_by_id(submission_id)
            .exec(&txn)
            .await
            .map_err(|e| map_db_err(&e))?;
        txn.commit().await.map_err(|e| map_db_err(&e))?;
        crate::revision::notify_committed();
        Ok(())
    })
    .await
}

pub async fn add_image_set_submission_members(
    library_id: &str,
    submission_id: &str,
    image_ids: &[String],
) -> Result<(), HentaiError> {
    if image_ids.is_empty() {
        return Ok(());
    }
    with_library_write(|| async {
        let db = connection()?;
        let txn = db.begin().await.map_err(|e| map_db_err(&e))?;
        let sub = require_submission(&txn, library_id, submission_id).await?;
        let set_images = load_set_images(&txn, library_id, &sub.image_set_id).await?;
        let known: HashSet<&str> = set_images
            .iter()
            .map(|row| row.image_set_image_id.as_str())
            .collect();
        let existing = load_member_ids(&txn, submission_id).await?;
        let existing_set: HashSet<&str> = existing.iter().map(String::as_str).collect();
        let mut seen = HashSet::new();
        for id in image_ids {
            if !known.contains(id.as_str()) {
                return Err(HentaiError::validation(format!(
                    "图集图片不属于该图集: {id}"
                )));
            }
            if existing_set.contains(id.as_str()) || !seen.insert(id.as_str()) {
                return Err(HentaiError::validation(format!("投稿成员重复: {id}")));
            }
        }
        let mut next = image_set_submission_members::Entity::find()
            .filter(image_set_submission_members::Column::SubmissionId.eq(submission_id))
            .order_by_desc(image_set_submission_members::Column::SortOrder)
            .one(&txn)
            .await
            .map_err(|e| map_db_err(&e))?
            .map(|row| row.sort_order.saturating_add(1))
            .unwrap_or(0);
        for id in image_ids {
            let row = image_set_submission_members::ActiveModel {
                submission_id: Set(submission_id.to_string()),
                image_set_image_id: Set(id.clone()),
                sort_order: Set(next),
            };
            row.insert(&txn).await.map_err(|e| map_db_err(&e))?;
            next = next.saturating_add(1);
        }
        txn.commit().await.map_err(|e| map_db_err(&e))?;
        crate::revision::notify_committed();
        Ok(())
    })
    .await
}

pub async fn remove_image_set_submission_members(
    library_id: &str,
    submission_id: &str,
    image_ids: &[String],
) -> Result<(), HentaiError> {
    if image_ids.is_empty() {
        return Ok(());
    }
    with_library_write(|| async {
        let db = connection()?;
        let txn = db.begin().await.map_err(|e| map_db_err(&e))?;
        let _ = require_submission(&txn, library_id, submission_id).await?;
        image_set_submission_members::Entity::delete_many()
            .filter(image_set_submission_members::Column::SubmissionId.eq(submission_id))
            .filter(image_set_submission_members::Column::ImageSetImageId.is_in(image_ids.to_vec()))
            .exec(&txn)
            .await
            .map_err(|e| map_db_err(&e))?;
        txn.commit().await.map_err(|e| map_db_err(&e))?;
        crate::revision::notify_committed();
        Ok(())
    })
    .await
}

/// Authoritative full membership reorder: `ordered_ids` must list every current member exactly once.
pub async fn reorder_image_set_submission_members(
    library_id: &str,
    submission_id: &str,
    ordered_ids: &[String],
) -> Result<(), HentaiError> {
    with_library_write(|| async {
        let db = connection()?;
        let txn = db.begin().await.map_err(|e| map_db_err(&e))?;
        let _ = require_submission(&txn, library_id, submission_id).await?;
        let members = image_set_submission_members::Entity::find()
            .filter(image_set_submission_members::Column::SubmissionId.eq(submission_id))
            .all(&txn)
            .await
            .map_err(|e| map_db_err(&e))?;
        if ordered_ids.len() != members.len() {
            return Err(HentaiError::validation(
                "排序列表必须包含该投稿的全部成员且数量一致".to_string(),
            ));
        }
        let known: HashSet<&str> = members
            .iter()
            .map(|row| row.image_set_image_id.as_str())
            .collect();
        let mut seen = HashSet::new();
        for id in ordered_ids {
            if !known.contains(id.as_str()) {
                return Err(HentaiError::validation(format!(
                    "图集图片不属于该投稿: {id}"
                )));
            }
            if !seen.insert(id.as_str()) {
                return Err(HentaiError::validation(format!("排序列表含重复图片: {id}")));
            }
        }
        let by_id: std::collections::HashMap<&str, &image_set_submission_members::Model> = members
            .iter()
            .map(|row| (row.image_set_image_id.as_str(), row))
            .collect();
        for (sort_order, id) in ordered_ids.iter().enumerate() {
            let row = by_id[id.as_str()];
            let mut active: image_set_submission_members::ActiveModel = (*row).clone().into();
            active.sort_order = Set(sort_order as i64);
            active.update(&txn).await.map_err(|e| map_db_err(&e))?;
        }
        txn.commit().await.map_err(|e| map_db_err(&e))?;
        crate::revision::notify_committed();
        Ok(())
    })
    .await
}

fn resolve_create_submission_name(name: &str, now_ms: i64) -> String {
    let trimmed = name.trim();
    if trimmed.is_empty() {
        format!("投稿-{now_ms}")
    } else {
        trimmed.to_string()
    }
}

fn require_name(name: &str) -> Result<String, HentaiError> {
    let trimmed = name.trim();
    if trimmed.is_empty() {
        return Err(HentaiError::validation("投稿名称不能为空".to_string()));
    }
    Ok(trimmed.to_string())
}

async fn require_submission<C: ConnectionTrait>(
    db: &C,
    library_id: &str,
    submission_id: &str,
) -> Result<image_set_submissions::Model, HentaiError> {
    let row = image_set_submissions::Entity::find_by_id(submission_id)
        .one(db)
        .await
        .map_err(|e| map_db_err(&e))?
        .ok_or_else(|| HentaiError::validation(format!("投稿不存在: {submission_id}")))?;
    if row.library_id != library_id {
        return Err(HentaiError::validation("投稿不属于该图集库".to_string()));
    }
    Ok(row)
}

async fn load_member_ids<C: ConnectionTrait>(
    db: &C,
    submission_id: &str,
) -> Result<Vec<String>, HentaiError> {
    let rows = image_set_submission_members::Entity::find()
        .filter(image_set_submission_members::Column::SubmissionId.eq(submission_id))
        .order_by_asc(image_set_submission_members::Column::SortOrder)
        .order_by_asc(image_set_submission_members::Column::ImageSetImageId)
        .all(db)
        .await
        .map_err(|e| map_db_err(&e))?;
    Ok(rows.into_iter().map(|row| row.image_set_image_id).collect())
}
