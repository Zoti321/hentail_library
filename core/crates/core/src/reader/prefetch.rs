use crate::error::HentaiError;

use super::cache::{ReaderCache, ReaderPageCacheRequest};
use super::manager::ReaderSessionRead;
use super::open::load_page_bytes;

impl ReaderPageCacheRequest {
    fn prefetch(
        self,
        session: &ReaderSessionRead,
        page_indexes: &[i32],
    ) -> Result<(), HentaiError> {
        if self.comic_id != session.comic_id {
            return Err(HentaiError::reader_invalid_content(
                "预取请求与阅读会话不匹配",
            ));
        }
        session.ensure_current()?;
        let resource_type = &session.resource_type;
        if resource_type == "dir" || page_indexes.is_empty() || !self.is_current() {
            return Ok(());
        }
        let Some(source) = &session.source_version else {
            return Ok(());
        };
        let cache = ReaderCache::app()?;
        self.run_with(
            page_indexes,
            |page_index| {
                let cached = self.apply_if_current(|| {
                    cache.cached_page_path(&self.comic_id, source, page_index)
                })?;
                if !matches!(cached, Some(None)) {
                    return Ok(None);
                }
                load_page_bytes(session, page_index).map(Some)
            },
            |page_index, bytes| {
                cache
                    .write_page(&self.comic_id, source, page_index, bytes)
                    .map(|_| ())
            },
            || cache.evict_outside_pages(&self.comic_id, source, page_indexes),
        )
    }

    fn run_with(
        &self,
        page_indexes: &[i32],
        mut load: impl FnMut(i32) -> Result<Option<Vec<u8>>, HentaiError>,
        mut publish: impl FnMut(i32, &[u8]) -> Result<(), HentaiError>,
        evict: impl FnOnce() -> Result<(), HentaiError>,
    ) -> Result<(), HentaiError> {
        for &page_index in page_indexes {
            if !self.is_current() {
                break;
            }
            // Decode outside the gate; only a current request may publish its result.
            // Page errors remain best-effort, including session-not-open.
            let _ = load(page_index).and_then(|bytes| match bytes {
                Some(bytes) => self
                    .apply_if_current(|| publish(page_index, &bytes))
                    .map(|_| ()),
                None => Ok(()),
            });
        }
        self.apply_if_current(evict).map(|_| ())
    }
}

pub fn prefetch_reader_pages(
    request: ReaderPageCacheRequest,
    session: &ReaderSessionRead,
    page_indexes: &[i32],
) -> Result<(), HentaiError> {
    request.prefetch(session, page_indexes)
}

pub fn clear_reader_page_cache(request: ReaderPageCacheRequest) -> Result<(), HentaiError> {
    // A late clear worker cannot delete a newer window's cache.
    request.clear_with(|| ReaderCache::app()?.clear_comic(&request.comic_id))
}

#[cfg(test)]
mod tests {
    use std::sync::{mpsc, Arc, Mutex};
    use std::time::Duration;

    use super::*;

    #[test]
    fn worker_start_order_cannot_replace_accepted_request_order() {
        let comic_id = "prefetch_reversed_workers";
        let old = ReaderPageCacheRequest::begin(comic_id);
        let current = ReaderPageCacheRequest::begin(comic_id);
        let mut pages = Vec::new();
        current
            .run_with(
                &[4, 5],
                |_| Ok(Some(vec![42])),
                |page, _| {
                    pages.push(page);
                    Ok(())
                },
                || Ok(()),
            )
            .unwrap();
        old.run_with(
            &[0, 1],
            |_| panic!("obsolete worker must not decode"),
            |_, _| panic!("obsolete worker must not publish"),
            || panic!("obsolete worker must not evict"),
        )
        .unwrap();
        assert_eq!(pages, [4, 5]);
        assert!(current.is_current());
    }

    #[test]
    fn delayed_clear_cannot_remove_reopened_window() {
        let comic_id = "prefetch_delayed_clear";
        let clear = ReaderPageCacheRequest::begin_clear(comic_id);
        let reopened = ReaderPageCacheRequest::begin(comic_id);
        let pages = Mutex::new(vec![4, 5]);
        clear
            .apply_if_current(|| {
                pages.lock().unwrap().clear();
                Ok(())
            })
            .unwrap();
        assert_eq!(*pages.lock().unwrap(), [4, 5]);
        assert!(reopened.is_current());
    }

    #[test]
    fn clear_then_reopen_keeps_old_request_invalid() {
        let comic_id = "prefetch_reopen_identity";
        let old = ReaderPageCacheRequest::begin(comic_id);
        let clear = ReaderPageCacheRequest::begin_clear(comic_id);
        assert!(!old.is_current());
        let reopened = ReaderPageCacheRequest::begin(comic_id);
        assert!(!old.is_current());
        assert!(!clear.is_current());
        assert!(reopened.is_current());
    }

    #[test]
    fn superseded_decode_cannot_publish_or_evict() {
        let comic_id = "prefetch_superseded_decode";
        let request = ReaderPageCacheRequest::begin(comic_id);
        let mut published = Vec::new();
        let mut evicted = false;
        request
            .run_with(
                &[0, 1],
                |_| {
                    ReaderPageCacheRequest::begin(comic_id);
                    Ok(Some(vec![42]))
                },
                |page, _| {
                    published.push(page);
                    Ok(())
                },
                || {
                    evicted = true;
                    Ok(())
                },
            )
            .unwrap();
        assert!(
            published.is_empty(),
            "obsolete decode published {published:?}"
        );
        assert!(!evicted);
    }

    #[test]
    fn cleared_decode_cannot_repopulate_cache() {
        let comic_id = "prefetch_cleared_decode";
        let request = ReaderPageCacheRequest::begin(comic_id);
        let mut published = false;
        request
            .run_with(
                &[0],
                |_| {
                    let clear = ReaderPageCacheRequest::begin_clear(comic_id);
                    clear.clear_with(|| Ok(()))?;
                    Ok(Some(vec![42]))
                },
                |_, _| {
                    published = true;
                    Ok(())
                },
                || panic!("cleared request must not evict"),
            )
            .unwrap();
        assert!(!published, "cleared decode repopulated cache");
    }

    #[test]
    fn current_window_keeps_best_effort_page_errors_and_evicts_once() {
        let request = ReaderPageCacheRequest::begin("prefetch_page_errors");
        let mut loaded = Vec::new();
        let mut published = Vec::new();
        let mut evictions = 0;
        request
            .run_with(
                &[0, 1, 2, 3],
                |page| {
                    loaded.push(page);
                    match page {
                        0 => Err(HentaiError::reader_invalid_content("decode failed")),
                        1 => Ok(None), // Already cached.
                        _ => Ok(Some(vec![42])),
                    }
                },
                |page, bytes| {
                    assert_eq!(bytes, [42]);
                    if page == 2 {
                        return Err(HentaiError::reader_invalid_content("publish failed"));
                    }
                    published.push(page);
                    Ok(())
                },
                || {
                    evictions += 1;
                    Ok(())
                },
            )
            .unwrap();
        assert_eq!(loaded, [0, 1, 2, 3]);
        assert_eq!(published, [3]);
        assert_eq!(evictions, 1);
    }

    #[test]
    fn current_eviction_error_is_preserved() {
        let request = ReaderPageCacheRequest::begin("prefetch_eviction_error");
        let result = request.run_with(
            &[],
            |_| unreachable!(),
            |_, _| unreachable!(),
            || Err(HentaiError::reader_invalid_content("eviction failed")),
        );
        assert!(result.unwrap_err().to_string().contains("eviction failed"));
    }

    #[test]
    fn cache_mutation_gate_is_local_to_each_comic() {
        let request = ReaderPageCacheRequest::begin("prefetch_locked_comic");
        let (entered_tx, entered_rx) = mpsc::channel();
        let (release_tx, release_rx) = mpsc::channel();
        let writer = std::thread::spawn(move || {
            request
                .apply_if_current(|| {
                    entered_tx.send(()).unwrap();
                    release_rx.recv_timeout(Duration::from_secs(5)).unwrap();
                    Ok(())
                })
                .unwrap();
        });
        entered_rx.recv_timeout(Duration::from_secs(5)).unwrap();
        let (other_tx, other_rx) = mpsc::channel();
        let other = std::thread::spawn(move || {
            let request = ReaderPageCacheRequest::begin("prefetch_independent_comic");
            request.apply_if_current(|| Ok(())).unwrap();
            other_tx.send(()).unwrap();
        });
        let independent = other_rx.recv_timeout(Duration::from_secs(5));
        release_tx.send(()).unwrap();
        writer.join().unwrap();
        other.join().unwrap();
        independent.expect("another Comic was blocked by this Comic's cache mutation");
    }

    #[test]
    fn clear_and_publication_share_the_same_gate() {
        let comic_id = "prefetch_clear_publication_gate";
        let request = ReaderPageCacheRequest::begin(comic_id);
        let pages = Arc::new(Mutex::new(Vec::new()));
        let writer_pages = pages.clone();
        let (entered_tx, entered_rx) = mpsc::channel();
        let (release_tx, release_rx) = mpsc::channel();
        let writer = std::thread::spawn(move || {
            request
                .apply_if_current(|| {
                    entered_tx.send(()).unwrap();
                    release_rx.recv_timeout(Duration::from_secs(5)).unwrap();
                    writer_pages.lock().unwrap().push(1);
                    Ok(())
                })
                .unwrap();
            request
        });
        entered_rx.recv_timeout(Duration::from_secs(5)).unwrap();
        let clear_pages = pages.clone();
        let clear = std::thread::spawn(move || {
            let clear = ReaderPageCacheRequest::begin_clear(comic_id);
            clear
                .clear_with(|| {
                    clear_pages.lock().unwrap().clear();
                    Ok(())
                })
                .unwrap();
        });
        release_tx.send(()).unwrap();
        let old = writer.join().unwrap();
        clear.join().unwrap();
        old.apply_if_current(|| {
            pages.lock().unwrap().push(2);
            Ok(())
        })
        .unwrap();
        assert!(pages.lock().unwrap().is_empty());
    }
}
