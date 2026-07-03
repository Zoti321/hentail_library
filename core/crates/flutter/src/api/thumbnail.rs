use hentai_core::{delete_thumbnails_by_comic_ids, find_thumbnail_by_comic_id, ComicThumbnailDto as CoreThumb};

use super::init::HentaiErrorDto;

#[derive(Debug, Clone)]
pub struct ComicThumbnailDto {
    pub thumbnail: Vec<u8>,
    pub source_modified_ms: i64,
    pub source_size: i64,
}

impl From<CoreThumb> for ComicThumbnailDto {
    fn from(v: CoreThumb) -> Self {
        Self {
            thumbnail: v.thumbnail,
            source_modified_ms: v.source_modified_ms,
            source_size: v.source_size,
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn find_thumbnail_by_comic_id_frb(
    comic_id: String,
) -> Result<Option<ComicThumbnailDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(find_thumbnail_by_comic_id(&comic_id))
        .map(|opt| opt.map(ComicThumbnailDto::from))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_thumbnails_by_comic_ids_frb(comic_ids: Vec<String>) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(delete_thumbnails_by_comic_ids(comic_ids))
        .map_err(HentaiErrorDto::from)
}
