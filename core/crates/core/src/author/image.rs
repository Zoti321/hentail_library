use crate::comic::find_comic_by_id;
use crate::error::HentaiError;
use crate::image_cache::ImageCache;
use crate::library::resolve_access_for_comic;
use crate::runtime::block_on;
use crate::thumbnail::hd::load_comic_hd_cover_with;
use crate::thumbnail::{find_thumbnail_cover_meta, load_page_image_bytes};

use super::{resolve_author_image, AuthorImageSource};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AuthorImageSlot {
    Avatar,
    Background,
}

/// 按 Author image 来源取该位置的高清图字节；`None` 表示无高清图（调用方保留缩略图过渡）。
///
/// 含阻塞 I/O（WebDAV 下载、解压、缩放），调用方须放在 blocking 线程。
pub fn load_author_image(
    author_id: i64,
    slot: AuthorImageSlot,
    show_r18: bool,
) -> Result<Option<Vec<u8>>, HentaiError> {
    let image = block_on(resolve_author_image(author_id, show_r18))?;
    let (source, comic_id) = match slot {
        AuthorImageSlot::Avatar => (image.avatar_source, image.avatar_comic_id),
        AuthorImageSlot::Background => (image.background_source, image.background_comic_id),
    };
    let comic_id = match (source, comic_id) {
        (AuthorImageSource::ComicCover, Some(comic_id)) => comic_id,
        _ => return Ok(None),
    };
    let Some(comic) = block_on(find_comic_by_id(&comic_id))? else {
        return Ok(None);
    };
    let thumbnail = block_on(find_thumbnail_cover_meta(&comic_id))?;
    let resolved = resolve_access_for_comic(&comic)?;
    let cache = ImageCache::app()?;
    load_comic_hd_cover_with(
        &cache,
        resolved.as_dyn(),
        &comic.comic_id,
        &comic.path,
        &comic.resource_type,
        thumbnail,
        |page_index| {
            load_page_image_bytes(
                &comic.comic_id,
                &comic.path,
                &comic.resource_type,
                page_index,
            )
        },
    )
}
