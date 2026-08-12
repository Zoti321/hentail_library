//! WebDAV [ResourceAccess] via `reqwest_dav` (Basic auth).

use std::io::Cursor;
use std::sync::Mutex;

use reqwest_dav::types::list_cmd::{ListEntity, ListFile, ListFolder};
use reqwest_dav::{Auth, Client, ClientBuilder, Depth};

use crate::error::HentaiError;
use crate::runtime::block_on;

use super::{
    ResourceAccess, ResourceEntry, ResourceKind, ResourceStat, ResourceStream,
};

/// WebDAV adapter. Location keys are absolute http(s) URLs under the library root.
pub struct WebDavResourceAccess {
    client: Client,
    /// Origin + path prefix used when joining relative PROPFIND hrefs, e.g. `https://host/dav`.
    root_url: String,
    /// Cached Depth::1 listings keyed by directory location.
    list_cache: Mutex<Option<(String, Vec<ResourceEntry>)>>,
}

impl WebDavResourceAccess {
    pub fn connect(
        root_url: &str,
        username: &str,
        password: &str,
    ) -> Result<Self, HentaiError> {
        let root_url = root_url.trim().trim_end_matches('/').to_string();
        if root_url.is_empty() {
            return Err(HentaiError::validation("WebDAV 根 URL 不能为空"));
        }
        let client = ClientBuilder::new()
            .set_host(root_url.clone())
            .set_auth(Auth::Basic(username.to_string(), password.to_string()))
            .build()
            .map_err(|e| map_dav_error(&e))?;
        Ok(Self {
            client,
            root_url,
            list_cache: Mutex::new(None),
        })
    }

    fn path_for_request(&self, location: &str) -> String {
        let location = location.trim().trim_end_matches('/');
        if let Some(rest) = location.strip_prefix(&self.root_url) {
            if rest.is_empty() {
                return "/".to_string();
            }
            return rest.to_string();
        }
        // Already a path-absolute href from the server.
        if location.starts_with('/') {
            return location.to_string();
        }
        location.to_string()
    }

    fn absolute_location(&self, href: &str) -> String {
        let href = href.trim();
        if href.starts_with("http://") || href.starts_with("https://") {
            return href.trim_end_matches('/').to_string();
        }
        if let Ok(base) = url::Url::parse(&self.root_url) {
            if let Ok(joined) = base.join(href) {
                let mut s = joined.to_string();
                while s.ends_with('/') && s.len() > 1 {
                    s.pop();
                }
                return s;
            }
        }
        if href.starts_with('/') {
            // scheme://host + href
            if let Ok(base) = url::Url::parse(&self.root_url) {
                let origin = format!(
                    "{}://{}",
                    base.scheme(),
                    base.host_str().unwrap_or_default()
                );
                return format!("{}{}", origin, href.trim_end_matches('/'));
            }
        }
        format!(
            "{}/{}",
            self.root_url.trim_end_matches('/'),
            href.trim_start_matches('/')
        )
    }
}

impl ResourceAccess for WebDavResourceAccess {
    fn list(&self, location: &str) -> Result<Vec<ResourceEntry>, HentaiError> {
        let location = location.trim().trim_end_matches('/');
        if let Ok(guard) = self.list_cache.lock() {
            if let Some((cached_loc, entries)) = guard.as_ref() {
                if cached_loc == location {
                    return Ok(entries.clone());
                }
            }
        }

        let path = self.path_for_request(location);
        let entities = block_on(self.client.list(&path, Depth::Number(1)))
            .map_err(|e| map_dav_error(&e))?;

        let mut out = Vec::new();
        for entity in entities {
            match entity {
                ListEntity::File(ListFile {
                    href,
                    content_length,
                    last_modified,
                    ..
                }) => {
                    let abs = self.absolute_location(&href);
                    if abs == location || abs.trim_end_matches('/') == location {
                        continue; // self
                    }
                    let name = abs.rsplit('/').next().unwrap_or(&abs).to_string();
                    let _ = (content_length, last_modified);
                    out.push(ResourceEntry {
                        name,
                        location: abs,
                        kind: ResourceKind::File,
                    });
                }
                ListEntity::Folder(ListFolder { href, .. }) => {
                    let abs = self.absolute_location(&href);
                    if abs == location || abs.trim_end_matches('/') == location {
                        continue;
                    }
                    let name = abs.rsplit('/').next().unwrap_or(&abs).to_string();
                    out.push(ResourceEntry {
                        name,
                        location: abs,
                        kind: ResourceKind::Dir,
                    });
                }
            }
        }
        out.sort_by(|a, b| a.name.cmp(&b.name));
        if let Ok(mut guard) = self.list_cache.lock() {
            *guard = Some((location.to_string(), out.clone()));
        }
        Ok(out)
    }

    fn stat(&self, location: &str) -> Result<Option<ResourceStat>, HentaiError> {
        let location = location.trim().trim_end_matches('/');
        let path = self.path_for_request(location);
        let entities = block_on(self.client.list(&path, Depth::Number(0)))
            .map_err(|e| map_dav_error(&e))?;
        for entity in entities {
            match entity {
                ListEntity::File(ListFile {
                    href,
                    content_length,
                    last_modified,
                    ..
                }) => {
                    let abs = self.absolute_location(&href);
                    if abs.trim_end_matches('/') == location {
                        return Ok(Some(ResourceStat {
                            kind: ResourceKind::File,
                            size: content_length.max(0) as u64,
                            modified_ms: last_modified.timestamp_millis(),
                        }));
                    }
                }
                ListEntity::Folder(ListFolder { href, .. }) => {
                    let abs = self.absolute_location(&href);
                    if abs.trim_end_matches('/') == location {
                        return Ok(Some(ResourceStat {
                            kind: ResourceKind::Dir,
                            size: 0,
                            modified_ms: 0,
                        }));
                    }
                }
            }
        }
        // Depth 0 sometimes returns empty for collections — treat root as dir if list works.
        if location == self.root_url.trim_end_matches('/') {
            return Ok(Some(ResourceStat {
                kind: ResourceKind::Dir,
                size: 0,
                modified_ms: 0,
            }));
        }
        Ok(None)
    }

    fn open_stream(&self, location: &str) -> Result<ResourceStream, HentaiError> {
        let path = self.path_for_request(location);
        let bytes = block_on(async {
            let response = self.client.get(&path).await.map_err(|e| map_dav_error(&e))?;
            let bytes = response.bytes().await.map_err(|e| {
                HentaiError::remote_unreachable(format!("读取远程资源失败: {e}"))
            })?;
            Ok::<Vec<u8>, HentaiError>(bytes.to_vec())
        })?;
        Ok(Box::new(Cursor::new(bytes)))
    }
}

fn map_dav_error(err: &reqwest_dav::Error) -> HentaiError {
    let msg = err.to_string();
    let lower = msg.to_ascii_lowercase();
    if lower.contains("401")
        || lower.contains("403")
        || lower.contains("unauthorized")
        || lower.contains("auth")
    {
        return HentaiError::remote_auth_failed(format!("WebDAV 鉴权失败: {msg}"));
    }
    if lower.contains("tls")
        || lower.contains("certificate")
        || lower.contains("ssl")
        || lower.contains("handshake")
    {
        return HentaiError::remote_tls_failed(format!("WebDAV TLS 失败: {msg}"));
    }
    HentaiError::remote_unreachable(format!("WebDAV 不可达: {msg}"))
}
