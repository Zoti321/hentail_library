use sea_orm::{ActiveModelTrait, ColumnTrait, EntityTrait, QueryFilter, Set};

use crate::db::{connection, map_db_err};
use crate::entity::{prelude::*, series, series_items};
use crate::error::HentaiError;

#[derive(Debug, Clone, Default)]
pub struct UpdateSeriesUserMetaDto {
    pub name: Option<String>,
    pub serialization_status: Option<String>,
    pub total_count: Option<i32>,
    pub clear_total_count: bool,
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
