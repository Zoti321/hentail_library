use crate::error::HentaiError;

use super::cache::ReaderCache;
use super::dto::ReaderPageDto;
use super::manager::open_reader;
use super::open::{load_page_bytes, load_page_list};

pub fn load_reader_page(
    comic_id: &str,
    path: &str,
    resource_type: &str,
    page_index: i32,
) -> Result<ReaderPageDto, HentaiError> {
    if resource_type == "dir" {
        open_reader(comic_id, path, resource_type)?;
        let list = load_page_list(comic_id, path, resource_type)?;
        let index = usize::try_from(page_index).map_err(|_| {
            HentaiError::reader_invalid_content(format!("页索引无效: {page_index}"))
        })?;
        let file_path = list
            .dir_page_paths
            .get(index)
            .ok_or_else(|| {
                HentaiError::reader_invalid_content(format!("页索引超出范围: {page_index}"))
            })?
            .clone();
        return Ok(ReaderPageDto::FilePath { path: file_path });
    }

    open_reader(comic_id, path, resource_type)?;
    let cache = ReaderCache::app()?;
    if let Some(cached_path) = cache.cached_page_path(comic_id, path, page_index)? {
        return Ok(ReaderPageDto::FilePath {
            path: cached_path.to_string_lossy().to_string(),
        });
    }

    let bytes = load_page_bytes(comic_id, path, resource_type, page_index)?;
    match cache.write_page(comic_id, path, page_index, &bytes) {
        Ok(file_path) => Ok(ReaderPageDto::FilePath {
            path: file_path.to_string_lossy().to_string(),
        }),
        Err(_) => Ok(ReaderPageDto::Bytes { data: bytes }),
    }
}

pub fn ensure_archive_page_cached(
    comic_id: &str,
    path: &str,
    resource_type: &str,
    page_index: i32,
    cache: &ReaderCache,
) -> Result<(), HentaiError> {
    if cache
        .cached_page_path(comic_id, path, page_index)?
        .is_some()
    {
        return Ok(());
    }
    let bytes = load_page_bytes(comic_id, path, resource_type, page_index)?;
    let _ = cache.write_page(comic_id, path, page_index, &bytes)?;
    Ok(())
}
