use std::collections::HashMap;
use std::io::Cursor;
use std::sync::{Arc, Mutex, OnceLock};

use image::ImageReader;

use crate::error::HentaiError;
use crate::image_cache::{ComicCoverKey, ImageCache};
use crate::resource::{read_source_stat_with, ResourceAccess};

use super::generate::{flatten_alpha_on_white, load_cover_bytes, resize_to_max_long_edge};

pub const HD_MAX_LONG_EDGE: u32 = 2048;
const HD_JPEG_QUALITY: u8 = 90;

/// `comic_thumbnails` 行中决定高清封面取哪一页的字段。
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ThumbnailCoverMeta {
    pub is_user_set: bool,
    pub source_page_index: Option<i32>,
}

/// Comic 高清封面：与库缩略图同一页（用户指定页优先，否则默认封面选图规则），按源版本缓存。
///
/// 返回 `None` 表示只用缩略图：无可用封面，或迁移前的用户指定封面没有记录页码。
pub fn load_comic_hd_cover_with(
    cache: &ImageCache,
    access: &dyn ResourceAccess,
    comic_id: &str,
    location: &str,
    resource_type: &str,
    thumbnail: Option<ThumbnailCoverMeta>,
    load_page: impl FnOnce(i32) -> Result<Vec<u8>, HentaiError>,
) -> Result<Option<Vec<u8>>, HentaiError> {
    let page_index = match thumbnail {
        Some(ThumbnailCoverMeta {
            source_page_index: Some(index),
            ..
        }) => Some(index),
        Some(ThumbnailCoverMeta {
            is_user_set: true, ..
        }) => return Ok(None),
        _ => None,
    };
    let Some((source_modified_ms, source_size)) =
        read_source_stat_with(access, location, resource_type)?
    else {
        return Ok(None);
    };
    let key = ComicCoverKey {
        comic_id,
        source_modified_ms,
        source_size,
        page_index,
    };

    with_comic_lock(comic_id, || {
        if let Some(bytes) = cache.read_comic_cover(&key) {
            return Ok(Some(bytes));
        }
        let source = match page_index {
            Some(index) => Some(load_page(index)?),
            None => load_cover_bytes(access, location, resource_type)?,
        };
        let Some(source) = source else {
            return Ok(None);
        };
        let hd = encode_hd_image(&source)?;
        if let Err(err) = cache.write_comic_cover(&key, &hd) {
            tracing::warn!(comic_id, error = %err, "write hd cover cache failed");
        }
        Ok(Some(hd))
    })
}

/// 同一 Comic 的高清封面串行生成：头像与背景同时请求时只生成一次。
fn with_comic_lock<T>(comic_id: &str, f: impl FnOnce() -> T) -> T {
    static LOCKS: OnceLock<Mutex<HashMap<String, Arc<Mutex<()>>>>> = OnceLock::new();
    let locks = || {
        LOCKS
            .get_or_init(Default::default)
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner())
    };
    let lock = Arc::clone(locks().entry(comic_id.to_string()).or_default());
    let result = {
        let _guard = lock.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
        f()
    };
    let mut map = locks();
    // 表本身持有一份、本调用持有一份：再无其它等待者时移除。
    if Arc::strong_count(&lock) == 2 {
        map.remove(comic_id);
    }
    result
}

/// 高清规格：长边 ≤ [HD_MAX_LONG_EDGE] 时原样返回源字节，否则 Lanczos3 缩放后重新编码。
pub fn encode_hd_image(source_bytes: &[u8]) -> Result<Vec<u8>, HentaiError> {
    let (width, height) = ImageReader::new(Cursor::new(source_bytes))
        .with_guessed_format()
        .map_err(|e| HentaiError::validation(e.to_string()))?
        .into_dimensions()
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    if width.max(height) <= HD_MAX_LONG_EDGE {
        return Ok(source_bytes.to_vec());
    }
    let img = image::load_from_memory(source_bytes)
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    let resized = resize_to_max_long_edge(&flatten_alpha_on_white(&img), HD_MAX_LONG_EDGE);
    let mut buf = Vec::new();
    image::codecs::jpeg::JpegEncoder::new_with_quality(&mut buf, HD_JPEG_QUALITY)
        .encode_image(&resized.to_rgb8())
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    Ok(buf)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::resource::FakeResourceAccess;
    use image::{GenericImageView, ImageBuffer, Rgb};

    fn png_bytes(width: u32, height: u32) -> Vec<u8> {
        let img: ImageBuffer<Rgb<u8>, Vec<u8>> =
            ImageBuffer::from_pixel(width, height, Rgb([200, 40, 40]));
        let mut out = Vec::new();
        img.write_to(&mut Cursor::new(&mut out), image::ImageFormat::Png)
            .expect("encode png");
        out
    }

    #[test]
    fn small_image_is_returned_byte_for_byte() {
        let source = png_bytes(1200, 2048);
        let hd = encode_hd_image(&source).expect("hd");
        assert_eq!(hd, source);
    }

    #[test]
    fn large_image_is_downscaled_to_2048_long_edge() {
        let source = png_bytes(1500, 3000);
        let hd = encode_hd_image(&source).expect("hd");
        let decoded = image::load_from_memory(&hd).expect("decode");
        assert_eq!(decoded.dimensions(), (1024, 2048));
    }

    #[test]
    fn undecodable_bytes_fail() {
        assert!(encode_hd_image(b"not an image").is_err());
    }

    fn cbz_with(entries: &[(&str, Vec<u8>)]) -> Vec<u8> {
        use std::io::Write;
        let mut bytes = Vec::new();
        {
            let mut zip = zip::ZipWriter::new(Cursor::new(&mut bytes));
            for (name, data) in entries {
                zip.start_file(*name, zip::write::SimpleFileOptions::default())
                    .expect("start");
                zip.write_all(data).expect("write");
            }
            zip.finish().expect("finish");
        }
        bytes
    }

    struct Fixture {
        _temp: tempfile::TempDir,
        cache: ImageCache,
        access: FakeResourceAccess,
    }

    const LOCATION: &str = "/lib/comic.cbz";

    fn fixture() -> Fixture {
        let temp = tempfile::TempDir::new().expect("tempdir");
        let cache = ImageCache::with_root(temp.path(), u64::MAX);
        let mut access = FakeResourceAccess::new();
        access.insert_file(
            LOCATION,
            cbz_with(&[
                ("001.png", png_bytes(10, 10)),
                ("cover.png", png_bytes(20, 30)),
            ]),
        );
        Fixture {
            _temp: temp,
            cache,
            access,
        }
    }

    fn load(
        f: &Fixture,
        thumbnail: Option<ThumbnailCoverMeta>,
        load_page: impl FnOnce(i32) -> Result<Vec<u8>, HentaiError>,
    ) -> Option<Vec<u8>> {
        load_comic_hd_cover_with(
            &f.cache, &f.access, "comic-1", LOCATION, "cbz", thumbnail, load_page,
        )
        .expect("load hd cover")
    }

    fn no_page(_: i32) -> Result<Vec<u8>, HentaiError> {
        panic!("page loader must not be called")
    }

    #[test]
    fn default_cover_follows_thumbnail_cover_selection() {
        let f = fixture();
        let auto_thumb = ThumbnailCoverMeta {
            is_user_set: false,
            source_page_index: None,
        };
        assert_eq!(load(&f, Some(auto_thumb), no_page), Some(png_bytes(20, 30)));
        assert_eq!(load(&f, None, no_page), Some(png_bytes(20, 30)));
    }

    #[test]
    fn user_set_cover_page_is_used() {
        let f = fixture();
        let mut requested = None;
        let hd = load(
            &f,
            Some(ThumbnailCoverMeta {
                is_user_set: true,
                source_page_index: Some(3),
            }),
            |index| {
                requested = Some(index);
                Ok(png_bytes(40, 60))
            },
        );
        assert_eq!(requested, Some(3));
        assert_eq!(hd, Some(png_bytes(40, 60)));
    }

    #[test]
    fn legacy_user_set_cover_without_page_falls_back_to_thumbnail() {
        let f = fixture();
        let hd = load(
            &f,
            Some(ThumbnailCoverMeta {
                is_user_set: true,
                source_page_index: None,
            }),
            no_page,
        );
        assert_eq!(hd, None);
    }

    #[test]
    fn second_load_is_served_from_cache_until_source_changes() {
        let mut f = fixture();
        let user_page = Some(ThumbnailCoverMeta {
            is_user_set: true,
            source_page_index: Some(1),
        });
        let calls = std::cell::Cell::new(0);
        let counting = |_: i32| {
            calls.set(calls.get() + 1);
            Ok(png_bytes(40, 60))
        };
        assert!(load(&f, user_page, counting).is_some());
        assert!(load(&f, user_page, counting).is_some());
        assert_eq!(calls.get(), 1, "second load must hit the disk cache");

        f.access.set_modified_ms(LOCATION, 42);
        assert!(load(&f, user_page, counting).is_some());
        assert_eq!(
            calls.get(),
            2,
            "source change must invalidate the cache entry"
        );
    }
}
