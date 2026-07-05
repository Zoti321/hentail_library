use sea_orm::{ActiveModelTrait, EntityTrait, Set};

use crate::db::{connection, map_db_err};
use crate::entity::{prelude::*, series};
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
