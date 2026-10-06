use hentai_core::{
    add_author as core_add, add_author_link as core_add_link, count_all_authors as core_count,
    delete_author_link as core_delete_link, delete_authors_by_names,
    fetch_authors_page as core_fetch, get_author_detail as core_detail, list_all_authors,
    list_author_links as core_list_links, load_author_image as core_load_image,
    rename_author as core_rename, resolve_author_image as core_image,
    update_author_link as core_update_link, watch_authors, AuthorIdentity, AuthorImageRef,
    AuthorImageSlot, AuthorImageSource, AuthorLinkDto, AuthorLinkPlatform,
};

use super::comic::PageRequestDto;
use super::init::HentaiErrorDto;
use super::stream_watch::{emit_or_closed, normalize_watch_result};

#[derive(Debug, Clone)]
pub struct AuthorIdentityFrbDto {
    pub id: i64,
    pub name: String,
    pub verified: bool,
}

impl From<AuthorIdentity> for AuthorIdentityFrbDto {
    fn from(value: AuthorIdentity) -> Self {
        Self {
            id: value.id,
            name: value.name,
            verified: value.verified,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AuthorLinkPlatformFrb {
    Pixiv,
    X,
    Patreon,
    Fanbox,
    Discord,
    Other,
}

impl From<AuthorLinkPlatform> for AuthorLinkPlatformFrb {
    fn from(value: AuthorLinkPlatform) -> Self {
        match value {
            AuthorLinkPlatform::Pixiv => Self::Pixiv,
            AuthorLinkPlatform::X => Self::X,
            AuthorLinkPlatform::Patreon => Self::Patreon,
            AuthorLinkPlatform::Fanbox => Self::Fanbox,
            AuthorLinkPlatform::Discord => Self::Discord,
            AuthorLinkPlatform::Other => Self::Other,
        }
    }
}

impl From<AuthorLinkPlatformFrb> for AuthorLinkPlatform {
    fn from(value: AuthorLinkPlatformFrb) -> Self {
        match value {
            AuthorLinkPlatformFrb::Pixiv => Self::Pixiv,
            AuthorLinkPlatformFrb::X => Self::X,
            AuthorLinkPlatformFrb::Patreon => Self::Patreon,
            AuthorLinkPlatformFrb::Fanbox => Self::Fanbox,
            AuthorLinkPlatformFrb::Discord => Self::Discord,
            AuthorLinkPlatformFrb::Other => Self::Other,
        }
    }
}

#[derive(Debug, Clone)]
pub struct AuthorLinkFrbDto {
    pub id: i64,
    pub platform: AuthorLinkPlatformFrb,
    pub url: String,
    pub platform_display_name: Option<String>,
    pub sort_key: i64,
}

impl From<AuthorLinkDto> for AuthorLinkFrbDto {
    fn from(value: AuthorLinkDto) -> Self {
        Self {
            id: value.id,
            platform: value.platform.into(),
            url: value.url,
            platform_display_name: value.platform_display_name,
            sort_key: value.sort_key,
        }
    }
}

#[derive(Debug, Clone)]
pub struct AuthorFacetCountFrbDto {
    pub name: String,
    pub attachment_count: i64,
}

#[derive(Debug, Clone)]
pub struct AuthorTopComicFrbDto {
    pub comic_id: String,
    pub title: String,
}

#[derive(Debug, Clone)]
pub struct AuthorDetailFrbDto {
    pub identity: AuthorIdentityFrbDto,
    pub links: Vec<AuthorLinkFrbDto>,
    pub tags: Vec<AuthorFacetCountFrbDto>,
    pub parodies: Vec<AuthorFacetCountFrbDto>,
    pub characters: Vec<AuthorFacetCountFrbDto>,
    pub top_comics: Vec<AuthorTopComicFrbDto>,
    pub comic_count: i64,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AuthorImageSourceFrb {
    PlatformCached,
    ComicCover,
    None,
}

impl From<AuthorImageSource> for AuthorImageSourceFrb {
    fn from(value: AuthorImageSource) -> Self {
        match value {
            AuthorImageSource::PlatformCached => Self::PlatformCached,
            AuthorImageSource::ComicCover => Self::ComicCover,
            AuthorImageSource::None => Self::None,
        }
    }
}

#[derive(Debug, Clone)]
pub struct AuthorImageRefFrbDto {
    pub avatar_source: AuthorImageSourceFrb,
    pub avatar_comic_id: Option<String>,
    pub avatar_link_id: Option<i64>,
    pub background_source: AuthorImageSourceFrb,
    pub background_comic_id: Option<String>,
    pub background_link_id: Option<i64>,
}

impl From<AuthorImageRef> for AuthorImageRefFrbDto {
    fn from(value: AuthorImageRef) -> Self {
        Self {
            avatar_source: value.avatar_source.into(),
            avatar_comic_id: value.avatar_comic_id,
            avatar_link_id: value.avatar_link_id,
            background_source: value.background_source.into(),
            background_comic_id: value.background_comic_id,
            background_link_id: value.background_link_id,
        }
    }
}

#[derive(Debug, Clone)]
pub struct AuthorPagedDto {
    pub items: Vec<AuthorIdentityFrbDto>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

#[flutter_rust_bridge::frb]
pub async fn list_all_authors_frb() -> Result<Vec<AuthorIdentityFrbDto>, HentaiErrorDto> {
    list_all_authors()
        .await
        .map(|rows| rows.into_iter().map(AuthorIdentityFrbDto::from).collect())
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn fetch_authors_page_frb(
    request: PageRequestDto,
) -> Result<AuthorPagedDto, HentaiErrorDto> {
    let total = core_count().await.map_err(HentaiErrorDto::from)?;
    let page_size = request.page_size.max(1);
    if total <= 0 {
        return Ok(AuthorPagedDto {
            items: vec![],
            total_count: 0,
            page: 1,
            page_size,
        });
    }
    let total_pages = (total + page_size as i64 - 1) / page_size as i64;
    let mut page = request.page.max(1);
    if page as i64 > total_pages {
        page = total_pages as i32;
    }
    let offset = (page - 1) * page_size;
    let items = core_fetch(page_size, offset)
        .await
        .map_err(HentaiErrorDto::from)?;
    Ok(AuthorPagedDto {
        items: items.into_iter().map(AuthorIdentityFrbDto::from).collect(),
        total_count: total,
        page,
        page_size,
    })
}

#[flutter_rust_bridge::frb]
pub async fn add_author_frb(name: String) -> Result<AuthorIdentityFrbDto, HentaiErrorDto> {
    core_add(&name)
        .await
        .map(AuthorIdentityFrbDto::from)
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn delete_authors_by_names_frb(names: Vec<String>) -> Result<(), HentaiErrorDto> {
    delete_authors_by_names(names)
        .await
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn rename_author_frb(old_name: String, new_name: String) -> Result<(), HentaiErrorDto> {
    core_rename(&old_name, &new_name)
        .await
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn watch_authors_frb(
    sink: crate::frb_generated::StreamSink<Vec<AuthorIdentityFrbDto>>,
) -> Result<(), HentaiErrorDto> {
    normalize_watch_result(
        watch_authors(|items| {
            emit_or_closed(
                &sink,
                items.into_iter().map(AuthorIdentityFrbDto::from).collect(),
            )
        })
        .await,
    )
}

#[flutter_rust_bridge::frb]
pub async fn get_author_detail_frb(
    author_id: i64,
    show_r18: bool,
) -> Result<Option<AuthorDetailFrbDto>, HentaiErrorDto> {
    let detail = core_detail(author_id, show_r18)
        .await
        .map_err(HentaiErrorDto::from)?;
    Ok(detail.map(|d| AuthorDetailFrbDto {
        identity: d.identity.into(),
        links: d.links.into_iter().map(AuthorLinkFrbDto::from).collect(),
        tags: d
            .tags
            .into_iter()
            .map(|t| AuthorFacetCountFrbDto {
                name: t.name,
                attachment_count: t.attachment_count,
            })
            .collect(),
        parodies: d
            .parodies
            .into_iter()
            .map(|t| AuthorFacetCountFrbDto {
                name: t.name,
                attachment_count: t.attachment_count,
            })
            .collect(),
        characters: d
            .characters
            .into_iter()
            .map(|t| AuthorFacetCountFrbDto {
                name: t.name,
                attachment_count: t.attachment_count,
            })
            .collect(),
        top_comics: d
            .top_comics
            .into_iter()
            .map(|c| AuthorTopComicFrbDto {
                comic_id: c.comic_id,
                title: c.title,
            })
            .collect(),
        comic_count: d.comic_count,
    }))
}

#[flutter_rust_bridge::frb]
pub async fn list_author_links_frb(
    author_id: i64,
) -> Result<Vec<AuthorLinkFrbDto>, HentaiErrorDto> {
    core_list_links(author_id)
        .await
        .map(|rows| rows.into_iter().map(AuthorLinkFrbDto::from).collect())
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn add_author_link_frb(
    author_id: i64,
    platform: AuthorLinkPlatformFrb,
    url: String,
    platform_display_name: Option<String>,
) -> Result<AuthorLinkFrbDto, HentaiErrorDto> {
    core_add_link(author_id, platform.into(), &url, platform_display_name)
        .await
        .map(AuthorLinkFrbDto::from)
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn update_author_link_frb(
    link_id: i64,
    platform: AuthorLinkPlatformFrb,
    url: String,
    platform_display_name: Option<String>,
) -> Result<(), HentaiErrorDto> {
    core_update_link(link_id, platform.into(), &url, platform_display_name)
        .await
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn delete_author_link_frb(author_id: i64, link_id: i64) -> Result<(), HentaiErrorDto> {
    core_delete_link(author_id, link_id)
        .await
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn resolve_author_image_frb(
    author_id: i64,
    show_r18: bool,
) -> Result<AuthorImageRefFrbDto, HentaiErrorDto> {
    core_image(author_id, show_r18)
        .await
        .map(AuthorImageRefFrbDto::from)
        .map_err(HentaiErrorDto::from)
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AuthorImageSlotFrb {
    Avatar,
    Background,
}

impl From<AuthorImageSlotFrb> for AuthorImageSlot {
    fn from(value: AuthorImageSlotFrb) -> Self {
        match value {
            AuthorImageSlotFrb::Avatar => Self::Avatar,
            AuthorImageSlotFrb::Background => Self::Background,
        }
    }
}

#[flutter_rust_bridge::frb]
pub async fn load_author_image_frb(
    author_id: i64,
    slot: AuthorImageSlotFrb,
    show_r18: bool,
) -> Result<Option<Vec<u8>>, HentaiErrorDto> {
    tokio::task::spawn_blocking(move || core_load_image(author_id, slot.into(), show_r18))
        .await
        .map_err(|error| {
            HentaiErrorDto::from(hentai_core::HentaiError::validation(error.to_string()))
        })?
        .map_err(HentaiErrorDto::from)
}
