use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};

use crate::error::HentaiError;

use super::cache::ReaderCache;
use super::page::ensure_archive_page_cached;
use super::manager::open_reader;

fn generation_store() -> &'static Mutex<HashMap<String, u64>> {
    static STORE: OnceLock<Mutex<HashMap<String, u64>>> = OnceLock::new();
    STORE.get_or_init(|| Mutex::new(HashMap::new()))
}

fn set_prefetch_generation(comic_id: &str, generation: u64) {
    let Ok(mut store) = generation_store().lock() else {
        return;
    };
    store.insert(comic_id.to_string(), generation);
}

fn is_prefetch_generation_current(comic_id: &str, generation: u64) -> bool {
    let Ok(store) = generation_store().lock() else {
        return false;
    };
    store.get(comic_id) == Some(&generation)
}

pub fn prefetch_reader_pages(
    comic_id: &str,
    path: &str,
    resource_type: &str,
    page_indexes: &[i32],
    generation: u64,
) -> Result<(), HentaiError> {
    if resource_type == "dir" || page_indexes.is_empty() {
        return Ok(());
    }
    set_prefetch_generation(comic_id, generation);
    open_reader(comic_id, path, resource_type)?;
    let cache = ReaderCache::app()?;
    for &page_index in page_indexes {
        if !is_prefetch_generation_current(comic_id, generation) {
            break;
        }
        let _ = ensure_archive_page_cached(comic_id, path, resource_type, page_index, &cache);
    }
    if is_prefetch_generation_current(comic_id, generation) {
        cache.evict_outside_pages(comic_id, path, page_indexes)?;
    }
    Ok(())
}

pub fn clear_reader_page_cache(comic_id: &str) -> Result<(), HentaiError> {
    ReaderCache::app()?.clear_comic(comic_id)
}
