use sha1::{Digest, Sha1};
use url::Url;

use crate::error::HentaiError;

/// Normalize a WebDAV Library root for identity / storage.
///
/// - Trims whitespace
/// - Defaults scheme to `https` when omitted
/// - Lowercases host
/// - Strips default ports, credentials in URL, fragment, and trailing slash (except `/`)
/// - Rejects non-http(s) schemes and `http` unless `allow_http`
pub fn normalize_webdav_root(raw: &str, allow_http: bool) -> Result<String, HentaiError> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return Err(HentaiError::validation("WebDAV 根 URL 不能为空"));
    }
    if trimmed.contains(['\n', '\r', '\0']) {
        return Err(HentaiError::validation("WebDAV 根 URL 含非法字符"));
    }

    let with_scheme = if looks_like_scheme(trimmed) {
        trimmed.to_string()
    } else {
        format!("https://{trimmed}")
    };

    let mut parsed = Url::parse(&with_scheme).map_err(|_| {
        HentaiError::validation("WebDAV 根 URL 无效")
    })?;

    match parsed.scheme() {
        "https" => {}
        "http" => {
            if !allow_http {
                return Err(HentaiError::validation(
                    "默认仅允许 HTTPS；若使用 HTTP 请显式允许",
                ));
            }
        }
        other => {
            return Err(HentaiError::validation(format!(
                "不支持的 WebDAV scheme: {other}"
            )));
        }
    }

    if !parsed.username().is_empty() || parsed.password().is_some() {
        return Err(HentaiError::validation(
            "请勿在 URL 中嵌入用户名或密码；请使用单独的凭证字段",
        ));
    }

    if parsed.host_str().map(str::is_empty).unwrap_or(true) {
        return Err(HentaiError::validation("WebDAV 根 URL 缺少主机名"));
    }

    // Lowercase host for stable identity.
    if let Some(host) = parsed.host_str().map(|h| h.to_ascii_lowercase()) {
        let _ = parsed.set_host(Some(&host));
    }
    parsed.set_fragment(None);
    // Drop query — Library root should be a directory URL.
    parsed.set_query(None);

    let mut out = parsed.to_string();
    // url crate keeps trailing slash for empty path as `https://host/`;
    // for non-root paths, strip a single trailing slash.
    if out.ends_with('/') {
        let without = out.trim_end_matches('/');
        // Keep `https://host` → normalize to `https://host` (no trailing slash),
        // unless path was only `/` which becomes host-only — acceptable for root.
        if without.matches('/').count() >= 2 {
            // scheme://host[/path...] — always at least two slashes after trim of trailing
            out = without.to_string();
        } else {
            out = without.to_string();
        }
    }
    Ok(out)
}

/// SHA1 of `library:` + normalized WebDAV root — same hasher family as local roots.
pub fn library_id_from_webdav_root(normalized_root: &str) -> String {
    let mut hasher = Sha1::new();
    hasher.update(b"library:");
    hasher.update(normalized_root.as_bytes());
    format!("{:x}", hasher.finalize())
}

fn looks_like_scheme(raw: &str) -> bool {
    raw.split_once("://")
        .map(|(scheme, _)| {
            !scheme.is_empty()
                && scheme
                    .bytes()
                    .all(|b| b.is_ascii_alphanumeric() || b == b'+' || b == b'-' || b == b'.')
        })
        .unwrap_or(false)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn defaults_to_https_and_strips_trailing_slash() {
        let n = normalize_webdav_root("NAS.Example/webdav/", false).unwrap();
        assert_eq!(n, "https://nas.example/webdav");
    }

    #[test]
    fn rejects_http_without_allow() {
        assert!(normalize_webdav_root("http://nas.local/dav", false).is_err());
    }

    #[test]
    fn allows_http_when_opted_in() {
        let n = normalize_webdav_root("http://nas.local/dav/", true).unwrap();
        assert_eq!(n, "http://nas.local/dav");
    }
}
