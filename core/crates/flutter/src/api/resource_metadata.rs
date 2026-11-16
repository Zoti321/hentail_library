use super::init::HentaiErrorDto;

#[derive(Debug, Clone)]
pub struct MediaOverviewDto {
    pub total: i64,
    pub disabled: i64,
    pub pending: i64,
    pub processing: i64,
    pub completed: i64,
    pub failed: i64,
    pub unsupported: i64,
    pub local_libraries: i64,
    pub enabled_libraries: i64,
}

pub async fn get_resource_metadata_enabled(library_id: String) -> Result<bool, HentaiErrorDto> {
    hentai_core::resource_metadata::is_enabled(&library_id)
        .await
        .map_err(Into::into)
}

pub async fn set_resource_metadata_enabled(
    library_id: String,
    enabled: bool,
) -> Result<(), HentaiErrorDto> {
    hentai_core::resource_metadata::set_enabled(&library_id, enabled)
        .await
        .map_err(Into::into)
}

pub async fn process_resource_metadata_tick() -> Result<bool, HentaiErrorDto> {
    hentai_core::resource_metadata::process_next()
        .await
        .map_err(Into::into)
}

pub async fn query_media_overview(show_r18: bool) -> Result<MediaOverviewDto, HentaiErrorDto> {
    let summary = hentai_core::resource_metadata::query_media_overview(show_r18).await?;
    Ok(MediaOverviewDto {
        total: summary.total,
        disabled: summary.disabled,
        pending: summary.pending,
        processing: summary.processing,
        completed: summary.completed,
        failed: summary.failed,
        unsupported: summary.unsupported,
        local_libraries: summary.local_libraries,
        enabled_libraries: summary.enabled_libraries,
    })
}
