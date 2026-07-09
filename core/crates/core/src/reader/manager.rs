use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};

use crate::comic_id::normalize_path_for_key;
use crate::error::HentaiError;

use super::backend::{open_backend, ReaderBackend};

struct CachedSession {
    normalized_path: String,
    backend: ReaderBackend,
}

struct SessionStore {
    sessions: HashMap<String, CachedSession>,
    order: Vec<String>,
}

impl SessionStore {
    fn new() -> Self {
        Self {
            sessions: HashMap::new(),
            order: Vec::new(),
        }
    }

    fn touch(&mut self, comic_id: &str) {
        self.order.retain(|id| id != comic_id);
        self.order.push(comic_id.to_string());
    }

    fn evict_if_needed(&mut self) {
        while self.order.len() > MAX_SESSIONS {
            let Some(oldest) = self.order.first().cloned() else {
                break;
            };
            self.order.remove(0);
            self.sessions.remove(&oldest);
        }
    }
}

const MAX_SESSIONS: usize = 4;

fn store() -> &'static Mutex<SessionStore> {
    static STORE: OnceLock<Mutex<SessionStore>> = OnceLock::new();
    STORE.get_or_init(|| Mutex::new(SessionStore::new()))
}

#[tracing::instrument(err, fields(comic_id, resource_type, path))]
pub fn open_reader(comic_id: &str, path: &str, resource_type: &str) -> Result<(), HentaiError> {
    let normalized_path = normalize_path_for_key(path);
    let mut store = store().lock().map_err(|e| HentaiError::validation(e.to_string()))?;
    if let Some(existing) = store.sessions.get(comic_id) {
        if existing.normalized_path == normalized_path {
            store.touch(comic_id);
            tracing::debug!(comic_id, "reader session reused");
            return Ok(());
        }
        store.sessions.remove(comic_id);
        store.order.retain(|id| id != comic_id);
    }
    let backend = open_backend(path, resource_type)?;
    store.sessions.insert(
        comic_id.to_string(),
        CachedSession {
            normalized_path,
            backend,
        },
    );
    store.touch(comic_id);
    store.evict_if_needed();
    tracing::info!(comic_id, resource_type, "reader opened");
    Ok(())
}

pub fn with_session<T>(
    comic_id: &str,
    f: impl FnOnce(&ReaderBackend) -> Result<T, HentaiError>,
) -> Result<T, HentaiError> {
    let store = store().lock().map_err(|e| HentaiError::validation(e.to_string()))?;
    let Some(session) = store.sessions.get(comic_id) else {
        return Err(HentaiError::reader_invalid_content(format!(
            "阅读会话未打开: {comic_id}"
        )));
    };
    f(&session.backend)
}

pub fn close_reader(comic_id: &str) {
    let Ok(mut store) = store().lock() else {
        return;
    };
    store.sessions.remove(comic_id);
    store.order.retain(|id| id != comic_id);
}

pub fn clear_reader_sessions() {
    let Ok(mut store) = store().lock() else {
        return;
    };
    store.sessions.clear();
    store.order.clear();
}
