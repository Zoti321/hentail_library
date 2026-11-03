use hentai_core::{
    count_trashed_comics, fetch_trashed_comics_page, list_trashed_comic_ids, purge_comics,
    restore_comics, trash_comics,
};

use super::comic::PageRequestDto;
use super::init::HentaiErrorDto;

/// 回收站列表行（Summary；不含 facet 与完整 Catalog DTO）。
#[derive(Debug, Clone)]
pub struct TrashedComicFrbDto {
    pub comic_id: String,
    pub path: String,
    pub resource_type: String,
    pub resource_size: i64,
    pub created_at: i64,
    pub last_updated_at: i64,
    pub title: String,
    pub page_count: i32,
    pub deleted_at: i64,
    pub library_name: String,
    pub library_kind: String,
}

#[derive(Debug, Clone)]
pub struct PagedTrashedComicResultFrbDto {
    pub items: Vec<TrashedComicFrbDto>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

#[derive(Debug, Clone)]
pub struct TrashedComicCountsFrbDto {
    pub total: i64,
    pub local: i64,
    pub remote: i64,
}

#[derive(Debug, Clone)]
pub struct ComicPurgeResultFrbDto {
    pub succeeded: i32,
    pub failed: i32,
    pub error_samples: Vec<String>,
}

#[flutter_rust_bridge::frb]
pub async fn trash_comics_frb(comic_ids: Vec<String>) -> Result<(), HentaiErrorDto> {
    trash_comics(comic_ids)
        .await
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn restore_comics_frb(comic_ids: Vec<String>) -> Result<(), HentaiErrorDto> {
    restore_comics(comic_ids)
        .await
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn purge_comics_frb(
    comic_ids: Vec<String>,
) -> Result<ComicPurgeResultFrbDto, HentaiErrorDto> {
    let result = purge_comics(comic_ids)
        .await
        .map_err(HentaiErrorDto::from)?;
    Ok(ComicPurgeResultFrbDto {
        succeeded: result.succeeded,
        failed: result.failed,
        error_samples: result.error_samples,
    })
}

#[flutter_rust_bridge::frb]
pub async fn fetch_trashed_comics_page_frb(
    request: PageRequestDto,
) -> Result<PagedTrashedComicResultFrbDto, HentaiErrorDto> {
    let result = fetch_trashed_comics_page(request.into())
        .await
        .map_err(HentaiErrorDto::from)?;
    Ok(PagedTrashedComicResultFrbDto {
        items: result
            .items
            .into_iter()
            .map(|item| TrashedComicFrbDto {
                comic_id: item.comic_id,
                path: item.path,
                resource_type: item.resource_type,
                resource_size: item.resource_size,
                created_at: item.created_at,
                last_updated_at: item.last_updated_at,
                title: item.title,
                page_count: item.page_count,
                deleted_at: item.deleted_at,
                library_name: item.library_name,
                library_kind: item.library_kind,
            })
            .collect(),
        total_count: result.total_count,
        page: result.page,
        page_size: result.page_size,
    })
}

#[flutter_rust_bridge::frb]
pub async fn count_trashed_comics_frb() -> Result<TrashedComicCountsFrbDto, HentaiErrorDto> {
    let counts = count_trashed_comics()
        .await
        .map_err(HentaiErrorDto::from)?;
    Ok(TrashedComicCountsFrbDto {
        total: counts.total,
        local: counts.local,
        remote: counts.remote,
    })
}

#[flutter_rust_bridge::frb]
pub async fn list_trashed_comic_ids_frb() -> Result<Vec<String>, HentaiErrorDto> {
    list_trashed_comic_ids()
        .await
        .map_err(HentaiErrorDto::from)
}
