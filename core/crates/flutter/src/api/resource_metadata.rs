use super::{comic::ComicDto, init::HentaiErrorDto};

#[derive(Debug, Clone)]
pub struct MediaResourceDto {
    pub comic: ComicDto,
    pub library_name: String,
    pub state: String,
    pub error: Option<String>,
    pub last_success_at: Option<i64>,
}

#[derive(Debug, Clone)]
pub struct MediaPageDto {
    pub items: Vec<MediaResourceDto>,
    pub total: i64,
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

pub async fn query_media_resources(
    library_id: Option<String>,
    state: Option<String>,
    show_r18: bool,
    offset: i64,
    limit: i64,
) -> Result<MediaPageDto, HentaiErrorDto> {
    let page =
        hentai_core::resource_metadata::query_media(library_id, state, show_r18, offset, limit)
            .await?;
    Ok(MediaPageDto {
        total: page.total,
        items: page
            .items
            .into_iter()
            .map(|item| MediaResourceDto {
                comic: item.comic.into(),
                library_name: item.library_name,
                state: item.state,
                error: item.error,
                last_success_at: item.last_success_at,
            })
            .collect(),
    })
}
