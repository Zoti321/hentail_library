use sea_orm::{ActiveModelTrait, ColumnTrait, EntityTrait, QueryFilter, Set};

use crate::db::{connection, map_db_err};
use crate::entity::{prelude::*, series, series_items};
use crate::error::HentaiError;
use crate::metadata_lock::series_auto_locks;

#[derive(Debug, Clone, Default)]
pub struct UpdateSeriesUserMetaDto {
    pub name: Option<String>,
    pub serialization_status: Option<String>,
    pub total_count: Option<i32>,
    pub clear_total_count: bool,
}

/// Partial patch for Series metadata field locks (`None` = leave unchanged).
#[derive(Debug, Clone, Default)]
pub struct SetSeriesMetaLocksDto {
    pub name: Option<bool>,
    pub serialization_status: Option<bool>,
    pub total_count: Option<bool>,
}

pub async fn update_series_user_meta(
    series_id: &str,
    meta: UpdateSeriesUserMetaDto,
) -> Result<(), HentaiError> {
    if meta.name.is_none()
        && meta.serialization_status.is_none()
        && meta.total_count.is_none()
        && !meta.clear_total_count
    {
        return Ok(());
    }
    let db = connection()?;
    let existing = Series::find_by_id(series_id)
        .one(&db)
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::validation(format!("系列不存在: {series_id}")))?;

    let auto_locks = series_auto_locks(
        meta.name.is_some(),
        meta.serialization_status.is_some(),
        meta.total_count.is_some() || meta.clear_total_count,
    );
    let mut active: series::ActiveModel = existing.into();
    if let Some(name) = meta.name {
        let trimmed = name.trim();
        if trimmed.is_empty() {
            return Err(HentaiError::validation("系列名称不能为空".to_string()));
        }
        active.name = Set(trimmed.to_string());
    }
    if let Some(serialization_status) = meta.serialization_status {
        active.serialization_status = Set(serialization_status);
    }
    if meta.clear_total_count {
        active.total_count = Set(None);
    } else if let Some(total_count) = meta.total_count {
        active.total_count = Set(Some(total_count));
    }
    if auto_locks.name {
        active.name_locked = Set(true);
    }
    if auto_locks.serialization_status {
        active.serialization_status_locked = Set(true);
    }
    if auto_locks.total_count {
        active.total_count_locked = Set(true);
    }
    active.update(&db).await.map_err(map_db_err)?;
    Ok(())
}

pub async fn set_series_meta_locks(
    series_id: &str,
    locks: SetSeriesMetaLocksDto,
) -> Result<(), HentaiError> {
    if locks.name.is_none()
        && locks.serialization_status.is_none()
        && locks.total_count.is_none()
    {
        return Ok(());
    }
    let db = connection()?;
    let existing = Series::find_by_id(series_id)
        .one(&db)
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| HentaiError::validation(format!("系列不存在: {series_id}")))?;

    let mut active: series::ActiveModel = existing.into();
    if let Some(v) = locks.name {
        active.name_locked = Set(v);
    }
    if let Some(v) = locks.serialization_status {
        active.serialization_status_locked = Set(v);
    }
    if let Some(v) = locks.total_count {
        active.total_count_locked = Set(v);
    }
    active.update(&db).await.map_err(map_db_err)?;
    Ok(())
}

/// 写入系列成员排序序号并加锁（Komga numberSort + numberSortLock）。
pub async fn update_series_item_sort_order(
    series_id: &str,
    comic_id: &str,
    sort_order: f64,
) -> Result<(), HentaiError> {
    if !sort_order.is_finite() {
        return Err(HentaiError::validation(
            "排序序号必须是有限数字".to_string(),
        ));
    }
    let series_id = series_id.trim();
    let comic_id = comic_id.trim();
    if series_id.is_empty() || comic_id.is_empty() {
        return Err(HentaiError::validation(
            "系列或漫画标识无效".to_string(),
        ));
    }
    let db = connection()?;
    let existing = SeriesItems::find()
        .filter(series_items::Column::SeriesId.eq(series_id))
        .filter(series_items::Column::ComicId.eq(comic_id))
        .one(&db)
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| {
            HentaiError::validation(format!(
                "系列成员不存在: {series_id}/{comic_id}"
            ))
        })?;

    let mut active: series_items::ActiveModel = existing.into();
    active.sort_order = Set(sort_order);
    active.sort_order_locked = Set(true);
    active.update(&db).await.map_err(map_db_err)?;
    Ok(())
}

/// 设置系列成员排序锁；解锁后下次 Library sync rebuild 会按文件名重编号。
pub async fn set_series_item_sort_order_locked(
    series_id: &str,
    comic_id: &str,
    locked: bool,
) -> Result<(), HentaiError> {
    let series_id = series_id.trim();
    let comic_id = comic_id.trim();
    if series_id.is_empty() || comic_id.is_empty() {
        return Err(HentaiError::validation(
            "系列或漫画标识无效".to_string(),
        ));
    }
    let db = connection()?;
    let existing = SeriesItems::find()
        .filter(series_items::Column::SeriesId.eq(series_id))
        .filter(series_items::Column::ComicId.eq(comic_id))
        .one(&db)
        .await
        .map_err(map_db_err)?
        .ok_or_else(|| {
            HentaiError::validation(format!(
                "系列成员不存在: {series_id}/{comic_id}"
            ))
        })?;

    let mut active: series_items::ActiveModel = existing.into();
    active.sort_order_locked = Set(locked);
    active.update(&db).await.map_err(map_db_err)?;
    Ok(())
}
