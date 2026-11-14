use std::io::Read;
use std::path::PathBuf;

use crate::error::HentaiError;
use crate::resource::{local_access, ResourceAccess};

use super::cache::{ReaderCache, ReaderPageCacheRead};
use super::dto::ReaderPageDto;
use super::manager::{with_ephemeral_reader, ReaderSessionRead};
use super::open::{load_page_bytes, load_page_list};

pub struct ReaderPageRead {
    session: ReaderSessionRead,
    cache: ReaderPageCacheRead,
}

impl ReaderPageRead {
    pub fn capture(comic_id: &str) -> Result<Self, HentaiError> {
        let session = ReaderSessionRead::capture(comic_id)?;
        let cache = ReaderPageCacheRead::capture(comic_id);
        Ok(Self { session, cache })
    }
}

pub fn load_reader_page(
    read: ReaderPageRead,
    page_index: i32,
) -> Result<ReaderPageDto, HentaiError> {
    let session = &read.session;
    let comic_id = &session.comic_id;
    let resource_type = &session.resource_type;
    // Hard-error contract: session must be open even when serving disk cache.
    session.ensure_current()?;

    if resource_type == "dir" {
        let file_path = load_directory_page_path(session, page_index)?;
        return Ok(ReaderPageDto::FilePath { path: file_path });
    }

    let Some(source) = &session.source_version else {
        return load_page_bytes(session, page_index).map(|data| ReaderPageDto::Bytes { data });
    };
    let cache = ReaderCache::app()?;
    let result = load_archive_page_with(
        &read.cache,
        || session.with_current_io(|| cache.cached_page_path(comic_id, source, page_index)),
        || load_page_bytes(session, page_index),
        |bytes| session.with_current_io(|| cache.write_page(comic_id, source, page_index, bytes)),
    )?;
    session.ensure_current()?;
    Ok(result)
}

pub(crate) fn load_page_image_bytes(
    comic_id: &str,
    path: &str,
    resource_type: &str,
    page_index: i32,
) -> Result<Vec<u8>, HentaiError> {
    let read = ReaderPageCacheRead::capture(comic_id);
    with_ephemeral_reader(comic_id, path, resource_type, |session| {
        session.ensure_current()?;
        let resource_type = &session.resource_type;
        if resource_type == "dir" {
            let file_path = load_directory_page_path(session, page_index)?;
            return read_file_bytes(&file_path);
        }

        let Some(source) = &session.source_version else {
            return load_page_bytes(session, page_index);
        };
        let cache = ReaderCache::app()?;
        let result = load_archive_page_bytes_with(
            &read,
            || {
                session.with_current_io(|| {
                    cache
                        .cached_page_path(comic_id, source, page_index)?
                        .map(|path| read_file_bytes(&path.to_string_lossy()))
                        .transpose()
                })
            },
            || load_page_bytes(session, page_index),
            |bytes| {
                session.with_current_io(|| {
                    cache
                        .write_page(comic_id, source, page_index, bytes)
                        .map(|_| ())
                })
            },
        )?;
        session.ensure_current()?;
        Ok(result)
    })
}

fn load_directory_page_path(
    session: &ReaderSessionRead,
    page_index: i32,
) -> Result<String, HentaiError> {
    let list = load_page_list(session)?;
    let index = usize::try_from(page_index)
        .map_err(|_| HentaiError::reader_invalid_content(format!("页索引无效: {page_index}")))?;
    list.dir_page_paths
        .get(index)
        .cloned()
        .ok_or_else(|| HentaiError::reader_invalid_content(format!("页索引超出范围: {page_index}")))
}

fn read_file_bytes(path: &str) -> Result<Vec<u8>, HentaiError> {
    let mut stream = local_access().open_stream(path)?;
    let mut bytes = Vec::new();
    stream
        .read_to_end(&mut bytes)
        .map_err(|error| HentaiError::validation(error.to_string()))?;
    Ok(bytes)
}

fn load_archive_page_bytes_with(
    read: &ReaderPageCacheRead,
    cached: impl FnOnce() -> Result<Option<Vec<u8>>, HentaiError>,
    decode: impl FnOnce() -> Result<Vec<u8>, HentaiError>,
    publish: impl FnOnce(&[u8]) -> Result<(), HentaiError>,
) -> Result<Vec<u8>, HentaiError> {
    // Keep lookup and the complete copy under one gate; no cache path escapes to a byte consumer.
    if let Some(Some(bytes)) = read.apply_if_current(cached)? {
        return Ok(bytes);
    }
    let bytes = decode()?;
    let _ = read.apply_if_current(|| publish(&bytes));
    Ok(bytes)
}

fn load_archive_page_with(
    read: &ReaderPageCacheRead,
    cached: impl FnOnce() -> Result<Option<PathBuf>, HentaiError>,
    decode: impl FnOnce() -> Result<Vec<u8>, HentaiError>,
    publish: impl FnOnce(&[u8]) -> Result<PathBuf, HentaiError>,
) -> Result<ReaderPageDto, HentaiError> {
    if let Some(Some(cached_path)) = read.apply_if_current(cached)? {
        return Ok(ReaderPageDto::FilePath {
            path: cached_path.to_string_lossy().to_string(),
        });
    }

    let bytes = decode()?;
    match read.apply_if_current(|| publish(&bytes)) {
        Ok(Some(file_path)) => Ok(ReaderPageDto::FilePath {
            path: file_path.to_string_lossy().to_string(),
        }),
        Ok(None) | Err(_) => Ok(ReaderPageDto::Bytes { data: bytes }),
    }
}

#[cfg(test)]
mod byte_tests {
    use std::sync::{mpsc, Arc, Mutex};
    use std::time::Duration;

    use super::*;
    use crate::reader::ReaderPageCacheRequest;

    #[test]
    fn directory_bytes_keep_natural_order_and_release_ephemeral_sessions() {
        let root = tempfile::tempdir().unwrap().keep();
        std::fs::write(root.join("10.jpg"), b"page-ten").unwrap();
        std::fs::write(root.join("2.jpg"), b"page-two").unwrap();
        let comic_id = "page_bytes_directory";
        let path = root.to_string_lossy();
        assert_eq!(
            load_page_image_bytes(comic_id, &path, "dir", 0).unwrap(),
            b"page-two"
        );
        assert_eq!(
            load_page_image_bytes(comic_id, &path, "dir", 1).unwrap(),
            b"page-ten"
        );
        for index in [-1, 2] {
            let error = load_page_image_bytes(comic_id, &path, "dir", index).unwrap_err();
            assert_eq!(
                error.code,
                crate::error::HentaiErrorCode::ReaderInvalidContent
            );
            assert!(super::super::manager::session_path_and_type(comic_id).is_err());
        }
        assert!(super::super::manager::session_path_and_type(comic_id).is_err());
    }

    #[test]
    fn byte_load_preserves_an_existing_reader_session() {
        let root = tempfile::tempdir().unwrap().keep();
        std::fs::write(root.join("1.jpg"), b"page-one").unwrap();
        let comic_id = "page_bytes_existing_session";
        let path = root.to_string_lossy();
        super::super::manager::open_reader(comic_id, &path, "dir").unwrap();
        assert_eq!(
            load_page_image_bytes(comic_id, &path, "dir", 0).unwrap(),
            b"page-one"
        );
        assert!(super::super::manager::session_path_and_type(comic_id).is_ok());
        super::super::manager::close_reader(comic_id);
    }

    #[test]
    fn cached_copy_remains_owned_after_cache_is_cleared() {
        let comic_id = "page_bytes_owned_cache_hit";
        let read = ReaderPageCacheRead::capture(comic_id);
        let cache = Mutex::new(vec![0, 1, 254, 255]);
        let bytes = load_archive_page_bytes_with(
            &read,
            || Ok(Some(cache.lock().unwrap().clone())),
            || panic!("cache hit must not decode"),
            |_| panic!("cache hit must not warm the cache"),
        )
        .unwrap();
        ReaderPageCacheRequest::begin_clear(comic_id)
            .clear_with(|| {
                cache.lock().unwrap().clear();
                Ok(())
            })
            .unwrap();
        assert_eq!(bytes, [0, 1, 254, 255]);
        assert!(cache.lock().unwrap().is_empty());
    }

    #[test]
    fn cached_copy_finishes_before_same_comic_clear() {
        let comic_id = "page_bytes_copy_clear_gate";
        let read = ReaderPageCacheRead::capture(comic_id);
        let cache = Arc::new(Mutex::new(vec![42]));
        let copy_cache = cache.clone();
        let (entered_tx, entered_rx) = mpsc::channel();
        let (release_tx, release_rx) = mpsc::channel();
        let reader = std::thread::spawn(move || {
            load_archive_page_bytes_with(
                &read,
                || {
                    entered_tx.send(()).unwrap();
                    release_rx.recv_timeout(Duration::from_secs(5)).unwrap();
                    Ok(Some(copy_cache.lock().unwrap().clone()))
                },
                || panic!("cache hit must not decode"),
                |_| panic!("cache hit must not publish"),
            )
            .unwrap()
        });
        entered_rx.recv_timeout(Duration::from_secs(5)).unwrap();
        let clear_cache = cache.clone();
        let (attempt_tx, attempt_rx) = mpsc::channel();
        let (cleared_tx, cleared_rx) = mpsc::channel();
        let clear = std::thread::spawn(move || {
            attempt_tx.send(()).unwrap();
            ReaderPageCacheRequest::begin_clear(comic_id)
                .clear_with(|| {
                    clear_cache.lock().unwrap().clear();
                    Ok(())
                })
                .unwrap();
            cleared_tx.send(()).unwrap();
        });
        attempt_rx.recv_timeout(Duration::from_secs(5)).unwrap();
        let premature_clear = cleared_rx.recv_timeout(Duration::from_millis(50));
        release_tx.send(()).unwrap();
        let bytes = reader.join().unwrap();
        clear.join().unwrap();
        assert!(matches!(
            premature_clear,
            Err(mpsc::RecvTimeoutError::Timeout)
        ));
        assert_eq!(bytes, [42]);
        assert!(cache.lock().unwrap().is_empty());
    }

    #[test]
    fn pending_clear_and_obsolete_reads_skip_cache_and_return_source_bytes() {
        let comic_id = "page_bytes_pending_clear";
        let old = ReaderPageCacheRead::capture(comic_id);
        ReaderPageCacheRequest::begin_clear(comic_id);
        let current = ReaderPageCacheRead::capture(comic_id);
        for read in [old, current] {
            let bytes = load_archive_page_bytes_with(
                &read,
                || panic!("cache is unavailable during clear"),
                || Ok(vec![0, 1, 254, 255]),
                |_| panic!("cache is unavailable during clear"),
            )
            .unwrap();
            assert_eq!(bytes, [0, 1, 254, 255]);
        }
    }

    #[test]
    fn clear_during_decode_does_not_cancel_owned_source_bytes() {
        let comic_id = "page_bytes_clear_decode";
        let read = ReaderPageCacheRead::capture(comic_id);
        let bytes = load_archive_page_bytes_with(
            &read,
            || Ok(None),
            || {
                ReaderPageCacheRequest::begin_clear(comic_id);
                Ok(vec![0, 1, 254, 255])
            },
            |_| panic!("old decode must not warm a cleared cache"),
        )
        .unwrap();
        assert_eq!(bytes, [0, 1, 254, 255]);
    }

    #[test]
    fn cache_miss_warms_once_and_returns_original_bytes_on_write_failure() {
        let read = ReaderPageCacheRead::capture("page_bytes_warm_failure");
        let mut writes = 0;
        let bytes = load_archive_page_bytes_with(
            &read,
            || Ok(None),
            || Ok(vec![0, 1, 254, 255]),
            |bytes| {
                writes += 1;
                assert_eq!(bytes, [0, 1, 254, 255]);
                Err(HentaiError::reader_invalid_content("cache write failed"))
            },
        )
        .unwrap();
        assert_eq!(writes, 1);
        assert_eq!(bytes, [0, 1, 254, 255]);
    }

    #[test]
    fn cache_copy_and_decode_errors_propagate_without_retry() {
        let read = ReaderPageCacheRead::capture("page_bytes_read_failure");
        let result = load_archive_page_bytes_with(
            &read,
            || Err(HentaiError::validation("cached read failed")),
            || panic!("cache read error must propagate"),
            |_| panic!("cache read error must propagate"),
        );
        assert!(result
            .unwrap_err()
            .to_string()
            .contains("cached read failed"));
        let result = load_archive_page_bytes_with(
            &read,
            || Ok(None),
            || Err(HentaiError::reader_invalid_content("decode failed")),
            |_| panic!("decode error must propagate"),
        );
        assert!(result.unwrap_err().to_string().contains("decode failed"));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::reader::ReaderPageCacheRequest;

    fn assert_bytes(page: ReaderPageDto, expected: &[u8]) {
        match page {
            ReaderPageDto::Bytes { data } => assert_eq!(data, expected),
            ReaderPageDto::FilePath { .. } => panic!("expected original source bytes"),
        }
    }

    #[test]
    fn clear_during_foreground_decode_returns_bytes_without_refilling_cache() {
        let comic_id = "foreground_clear_during_decode";
        let read = ReaderPageCacheRead::capture(comic_id);
        let source = vec![0, 1, 254, 255];
        let mut published = false;
        let page = load_archive_page_with(
            &read,
            || Ok(None),
            || {
                ReaderPageCacheRequest::begin_clear(comic_id);
                Ok(source.clone())
            },
            |_| {
                published = true;
                Ok(PathBuf::from("virtual-page.jpg"))
            },
        )
        .unwrap();
        assert!(!published, "foreground decode refilled a cleared cache");
        assert_bytes(page, &source);
    }

    #[test]
    fn read_captured_before_clear_cannot_access_cache_when_worker_starts_late() {
        let comic_id = "foreground_delayed_worker";
        let read = ReaderPageCacheRead::capture(comic_id);
        let clear = ReaderPageCacheRequest::begin_clear(comic_id);
        clear.clear_with(|| Ok(())).unwrap();
        let page = load_archive_page_with(
            &read,
            || panic!("old read must not inspect the new cache"),
            || Ok(vec![42]),
            |_| panic!("old read must not refill the cache"),
        )
        .unwrap();
        assert_bytes(page, &[42]);
    }

    #[test]
    fn read_captured_while_clear_is_pending_returns_bytes() {
        let comic_id = "foreground_pending_clear";
        let clear = ReaderPageCacheRequest::begin_clear(comic_id);
        let read = ReaderPageCacheRead::capture(comic_id);
        let page = load_archive_page_with(
            &read,
            || panic!("pending clear may remove a cached path"),
            || Ok(vec![42]),
            |_| panic!("pending clear may remove a newly published path"),
        )
        .unwrap();
        assert_bytes(page, &[42]);
        assert!(clear.is_current(), "foreground read cancelled cleanup");
    }

    #[test]
    fn new_read_may_publish_after_its_pending_clear_completes() {
        let comic_id = "foreground_completed_clear";
        let clear = ReaderPageCacheRequest::begin_clear(comic_id);
        let read = ReaderPageCacheRead::capture(comic_id);
        let page = load_archive_page_with(
            &read,
            || panic!("lookup must skip pending clear"),
            || {
                clear.clear_with(|| Ok(()))?;
                Ok(vec![42])
            },
            |bytes| {
                assert_eq!(bytes, [42]);
                Ok(PathBuf::from("new-page.jpg"))
            },
        )
        .unwrap();
        assert!(matches!(page, ReaderPageDto::FilePath { path } if path == "new-page.jpg"));
    }

    #[test]
    fn prefetch_window_changes_do_not_cancel_foreground_read() {
        let comic_id = "foreground_prefetch_independence";
        let read = ReaderPageCacheRead::capture(comic_id);
        let page = load_archive_page_with(
            &read,
            || Ok(None),
            || {
                ReaderPageCacheRequest::begin(comic_id);
                ReaderPageCacheRequest::begin(comic_id);
                Ok(vec![42])
            },
            |_| Ok(PathBuf::from("current-page.jpg")),
        )
        .unwrap();
        assert!(matches!(page, ReaderPageDto::FilePath { .. }));
        let prefetch = ReaderPageCacheRequest::begin(comic_id);
        ReaderPageCacheRead::capture(comic_id);
        assert!(prefetch.is_current());
    }

    #[test]
    fn obsolete_clear_cannot_release_a_newer_clear_barrier() {
        let comic_id = "foreground_superseded_clear";
        let old_clear = ReaderPageCacheRequest::begin_clear(comic_id);
        let clear = ReaderPageCacheRequest::begin_clear(comic_id);
        let read = ReaderPageCacheRead::capture(comic_id);
        old_clear
            .clear_with(|| panic!("obsolete clear must not execute"))
            .unwrap();
        let page = load_archive_page_with(
            &read,
            || panic!("newer clear is still pending"),
            || Ok(vec![42]),
            |_| panic!("newer clear is still pending"),
        )
        .unwrap();
        assert_bytes(page, &[42]);
        clear.clear_with(|| Ok(())).unwrap();
        assert_eq!(read.apply_if_current(|| Ok(7)).unwrap(), Some(7));
    }

    #[test]
    fn failed_clear_releases_barrier_and_preserves_its_error() {
        let comic_id = "foreground_failed_clear";
        let old_read = ReaderPageCacheRead::capture(comic_id);
        let clear = ReaderPageCacheRequest::begin_clear(comic_id);
        let read = ReaderPageCacheRead::capture(comic_id);
        let error = clear
            .clear_with(|| Err(HentaiError::reader_invalid_content("clear failed")))
            .unwrap_err();
        assert!(error.to_string().contains("clear failed"));
        assert_eq!(read.apply_if_current(|| Ok(7)).unwrap(), Some(7));
        assert_eq!(old_read.apply_if_current(|| Ok(7)).unwrap(), None);
    }

    #[test]
    fn newer_prefetch_releases_pending_clear_without_restoring_old_reads() {
        let comic_id = "foreground_prefetch_after_clear";
        let old_read = ReaderPageCacheRead::capture(comic_id);
        let clear = ReaderPageCacheRequest::begin_clear(comic_id);
        let read = ReaderPageCacheRead::capture(comic_id);
        ReaderPageCacheRequest::begin(comic_id);
        clear
            .clear_with(|| panic!("prefetch superseded clear"))
            .unwrap();
        assert_eq!(read.apply_if_current(|| Ok(7)).unwrap(), Some(7));
        assert_eq!(old_read.apply_if_current(|| Ok(7)).unwrap(), None);
    }

    #[test]
    fn cache_hit_returns_path_without_decoding_or_publishing() {
        let read = ReaderPageCacheRead::capture("foreground_cache_hit");
        let page = load_archive_page_with(
            &read,
            || Ok(Some(PathBuf::from("cached-page.jpg"))),
            || panic!("cache hit must not decode"),
            |_| panic!("cache hit must not publish"),
        )
        .unwrap();
        assert!(matches!(page, ReaderPageDto::FilePath { path } if path == "cached-page.jpg"));
    }

    #[test]
    fn cache_publication_failure_preserves_source_bytes() {
        let read = ReaderPageCacheRead::capture("foreground_publish_failure");
        let page = load_archive_page_with(
            &read,
            || Ok(None),
            || Ok(vec![0, 1, 254, 255]),
            |_| Err(HentaiError::reader_invalid_content("write failed")),
        )
        .unwrap();
        assert_bytes(page, &[0, 1, 254, 255]);
    }

    #[test]
    fn lookup_and_decode_failures_remain_hard_errors() {
        let read = ReaderPageCacheRead::capture("foreground_lookup_error");
        let result = load_archive_page_with(
            &read,
            || Err(HentaiError::reader_invalid_content("lookup failed")),
            || panic!("lookup error must propagate"),
            |_| panic!("lookup error must propagate"),
        );
        assert!(result.unwrap_err().to_string().contains("lookup failed"));
        let result = load_archive_page_with(
            &read,
            || Ok(None),
            || Err(HentaiError::reader_invalid_content("decode failed")),
            |_| panic!("decode error must propagate"),
        );
        assert!(result.unwrap_err().to_string().contains("decode failed"));
    }

    #[test]
    fn missing_session_remains_a_hard_error() {
        let error = ReaderPageRead::capture("foreground_missing_session")
            .and_then(|read| load_reader_page(read, 0))
            .unwrap_err();
        assert_eq!(
            error.code,
            crate::error::HentaiErrorCode::ReaderSessionNotOpen
        );
    }
}
