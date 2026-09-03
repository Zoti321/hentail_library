use hentai_core::{
    self, count_all, fetch_comics_page, find_comic_by_id, init_db, read_data_version, search_by_keyword,
};

use super::init::HentaiErrorDto;

#[derive(Debug, Clone)]
pub struct ComicFilterDto {
    pub show_r18: bool,
    pub query: Option<String>,
    pub resource_types: Vec<String>,
    pub content_ratings: Vec<String>,
    pub tags_all: Vec<String>,
    pub tags_any: Vec<String>,
    pub tags_exclude: Vec<String>,
    pub authors_all: Vec<String>,
    pub authors_any: Vec<String>,
    pub authors_exclude: Vec<String>,
    pub library_id: Option<String>,
}

#[derive(Debug, Clone)]
pub struct ComicMetaLocksDto {
    pub title: bool,
    pub description: bool,
    pub published_at: bool,
    pub content_rating: bool,
    pub authors: bool,
    pub tags: bool,
    pub languages: bool,
    pub parodies: bool,
    pub characters: bool,
}

#[derive(Debug, Clone)]
pub struct ComicDto {
    pub comic_id: String,
    pub path: String,
    pub resource_type: String,
    pub resource_size: i64,
    pub created_at: i64,
    pub last_updated_at: i64,
    pub title: String,
    pub content_rating: String,
    pub page_count: i32,
    pub description: Option<String>,
    pub published_at: Option<i64>,
    pub last_read_time_ms: Option<i64>,
    pub authors: Vec<String>,
    pub tags: Vec<String>,
    pub languages: Vec<String>,
    pub parodies: Vec<String>,
    pub characters: Vec<String>,
    pub locks: ComicMetaLocksDto,
    pub library_id: String,
}

#[derive(Debug, Clone)]
pub struct PageRequestDto {
    pub page: i32,
    pub page_size: i32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum ComicSortFieldDto {
    #[default]
    Title,
    CreatedAt,
    LastUpdatedAt,
    PublishedAt,
    ReadAt,
    FileSize,
    PageCount,
}

#[derive(Debug, Clone)]
pub struct ComicSortOptionDto {
    pub field: ComicSortFieldDto,
    pub descending: bool,
}

#[derive(Debug, Clone)]
pub struct PagedComicResultDto {
    pub items: Vec<ComicDto>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

impl From<hentai_core::ComicDto> for ComicDto {
    fn from(value: hentai_core::ComicDto) -> Self {
        Self {
            comic_id: value.comic_id,
            path: value.path,
            resource_type: value.resource_type,
            resource_size: value.resource_size,
            created_at: value.created_at,
            last_updated_at: value.last_updated_at,
            title: value.title,
            content_rating: value.content_rating,
            page_count: value.page_count,
            description: value.description,
            published_at: value.published_at,
            last_read_time_ms: value.last_read_time_ms,
            authors: value.authors,
            tags: value.tags,
            languages: value.languages,
            parodies: value.parodies,
            characters: value.characters,
            locks: ComicMetaLocksDto {
                title: value.locks.title,
                description: value.locks.description,
                published_at: value.locks.published_at,
                content_rating: value.locks.content_rating,
                authors: value.locks.authors,
                tags: value.locks.tags,
                languages: value.locks.languages,
                parodies: value.locks.parodies,
                characters: value.locks.characters,
            },
            library_id: value.library_id,
        }
    }
}

impl From<ComicFilterDto> for hentai_core::ComicFilterDto {
    fn from(value: ComicFilterDto) -> Self {
        Self {
            show_r18: value.show_r18,
            query: value.query,
            resource_types: value.resource_types,
            content_ratings: value.content_ratings,
            tags_all: value.tags_all,
            tags_any: value.tags_any,
            tags_exclude: value.tags_exclude,
            authors_all: value.authors_all,
            authors_any: value.authors_any,
            authors_exclude: value.authors_exclude,
            library_id: value.library_id,
        }
    }
}

impl From<PageRequestDto> for hentai_core::PageRequestDto {
    fn from(value: PageRequestDto) -> Self {
        Self {
            page: value.page,
            page_size: value.page_size,
        }
    }
}

impl From<ComicSortOptionDto> for hentai_core::ComicSortOptionDto {
    fn from(value: ComicSortOptionDto) -> Self {
        Self {
            field: match value.field {
                ComicSortFieldDto::Title => hentai_core::ComicSortFieldDto::Title,
                ComicSortFieldDto::CreatedAt => hentai_core::ComicSortFieldDto::CreatedAt,
                ComicSortFieldDto::LastUpdatedAt => {
                    hentai_core::ComicSortFieldDto::LastUpdatedAt
                }
                ComicSortFieldDto::PublishedAt => hentai_core::ComicSortFieldDto::PublishedAt,
                ComicSortFieldDto::ReadAt => hentai_core::ComicSortFieldDto::ReadAt,
                ComicSortFieldDto::FileSize => hentai_core::ComicSortFieldDto::FileSize,
                ComicSortFieldDto::PageCount => hentai_core::ComicSortFieldDto::PageCount,
            },
            descending: value.descending,
        }
    }
}

impl From<hentai_core::PagedComicResultDto> for PagedComicResultDto {
    fn from(value: hentai_core::PagedComicResultDto) -> Self {
        Self {
            items: value.items.into_iter().map(ComicDto::from).collect(),
            total_count: value.total_count,
            page: value.page,
            page_size: value.page_size,
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn init_db_frb(app_data_dir: String, db_file_name: String) -> Result<(), HentaiErrorDto> {
    init_db(&app_data_dir, &db_file_name).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn comic_id_from_path_frb(raw_path: String) -> String {
    hentai_core::comic_id_from_path(&raw_path)
}

#[flutter_rust_bridge::frb(sync)]
pub fn fetch_comics_page_frb(
    request: PageRequestDto,
    filter: ComicFilterDto,
    sort: ComicSortOptionDto,
) -> Result<PagedComicResultDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(fetch_comics_page(request.into(), filter.into(), sort.into()))
        .map(PagedComicResultDto::from)
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn find_comic_by_id_frb(comic_id: String) -> Result<Option<ComicDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(find_comic_by_id(&comic_id))
        .map(|opt| opt.map(ComicDto::from))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn search_by_keyword_frb(keyword: String) -> Result<Vec<ComicDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(search_by_keyword(&keyword))
        .map(|rows| rows.into_iter().map(ComicDto::from).collect())
        .map_err(HentaiErrorDto::from)
}

#[derive(Debug, Clone, Default)]
pub struct UpdateComicUserMetaFrbDto {
    pub title: Option<String>,
    pub content_rating: Option<String>,
    pub description: Option<String>,
    pub published_at: Option<i64>,
    pub authors: Option<Vec<String>>,
    pub tags: Option<Vec<String>>,
    pub languages: Option<Vec<String>>,
    pub parodies: Option<Vec<String>>,
    pub characters: Option<Vec<String>>,
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_comics_by_ids_frb(comic_ids: Vec<String>) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(hentai_core::delete_comics_by_ids(comic_ids))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_comic_user_meta_frb(
    comic_id: String,
    meta: UpdateComicUserMetaFrbDto,
) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(hentai_core::update_comic_user_meta(
        &comic_id,
        hentai_core::UpdateComicUserMetaDto {
            title: meta.title,
            content_rating: meta.content_rating,
            description: meta.description,
            published_at: meta.published_at,
            authors: meta.authors,
            tags: meta.tags,
            languages: meta.languages,
            parodies: meta.parodies,
            characters: meta.characters,
        },
    ))
    .map_err(HentaiErrorDto::from)
}

#[derive(Debug, Clone, Default)]
pub struct SetComicMetaLocksFrbDto {
    pub title: Option<bool>,
    pub description: Option<bool>,
    pub published_at: Option<bool>,
    pub content_rating: Option<bool>,
    pub authors: Option<bool>,
    pub tags: Option<bool>,
    pub languages: Option<bool>,
    pub parodies: Option<bool>,
    pub characters: Option<bool>,
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_comic_meta_locks_frb(
    comic_id: String,
    locks: SetComicMetaLocksFrbDto,
) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(hentai_core::set_comic_meta_locks(
        &comic_id,
        hentai_core::SetComicMetaLocksDto {
            title: locks.title,
            description: locks.description,
            published_at: locks.published_at,
            content_rating: locks.content_rating,
            authors: locks.authors,
            tags: locks.tags,
            languages: locks.languages,
            parodies: locks.parodies,
            characters: locks.characters,
        },
    ))
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn refresh_comic_metadata_frb(comic_id: String) -> Result<(), HentaiErrorDto> {
    hentai_core::refresh_comic_metadata(&comic_id)
        .await
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn search_by_tag_expression_frb(
    must_include: Vec<String>,
    optional_or: Vec<String>,
    must_exclude: Vec<String>,
) -> Result<Vec<ComicDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(hentai_core::search_by_tag_expression(
        must_include,
        optional_or,
        must_exclude,
    ))
    .map(|rows| rows.into_iter().map(ComicDto::from).collect())
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn count_all_comics_frb() -> Result<i64, HentaiErrorDto> {
    hentai_core::runtime::block_on(count_all()).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn watch_comic_changes(
    sink: crate::frb_generated::StreamSink<i32>,
) -> Result<(), HentaiErrorDto> {
    let mut last = read_data_version().await.map_err(HentaiErrorDto::from)?;
    loop {
        tokio::time::sleep(std::time::Duration::from_millis(400)).await;
        let Ok(version) = read_data_version().await else {
            continue;
        };
        if version != last {
            last = version;
            if sink.add(version).is_err() {
                break;
            }
        }
    }
    Ok(())
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
    crate::tracing_init::init_tracing_subscriber();
}
