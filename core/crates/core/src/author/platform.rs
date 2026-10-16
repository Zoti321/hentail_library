use std::net::{IpAddr, SocketAddr};
use std::time::Duration;

use async_trait::async_trait;
use reqwest::header::{HeaderMap, HeaderValue, ACCEPT, CONTENT_TYPE, ORIGIN, USER_AGENT};
use scraper::{Html, Selector};
use serde_json::Value;
use url::Url;

use crate::error::HentaiError;

use super::AuthorLinkPlatform;

const CONNECT_TIMEOUT: Duration = Duration::from_secs(10);
const REQUEST_TIMEOUT: Duration = Duration::from_secs(20);
const MAX_REDIRECTS: usize = 3;
const PROFILE_MAX_BYTES: usize = 2 * 1024 * 1024;
pub const IMAGE_MAX_BYTES: usize = 16 * 1024 * 1024;
const APP_USER_AGENT: &str = "HentaiLibrary/0.1 author-profile-resolver";

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PlatformProfile {
    pub display_name: Option<String>,
    pub avatar_url: Option<String>,
    pub background_url: Option<String>,
}

#[derive(Debug, Clone)]
pub struct FetchResponse {
    pub final_url: Url,
    pub content_type: Option<String>,
    pub bytes: Vec<u8>,
}

#[async_trait]
#[allow(clippy::double_must_use)]
pub trait HttpTransport: Send + Sync {
    async fn get(
        &self,
        url: &Url,
        headers: HeaderMap,
        max_bytes: usize,
    ) -> Result<FetchResponse, HentaiError>;
}

#[derive(Debug, Default)]
pub struct RestrictedHttpTransport;

#[async_trait]
impl HttpTransport for RestrictedHttpTransport {
    async fn get(
        &self,
        url: &Url,
        headers: HeaderMap,
        max_bytes: usize,
    ) -> Result<FetchResponse, HentaiError> {
        let mut current = url.clone();
        for redirect_count in 0..=MAX_REDIRECTS {
            validate_remote_url(&current).await?;
            let host = current
                .host_str()
                .ok_or_else(|| HentaiError::validation("remote URL has no host"))?;
            let port = current
                .port_or_known_default()
                .ok_or_else(|| HentaiError::validation("remote URL has no port"))?;
            let socket = public_socket_for(host, port).await?;
            let client = reqwest::Client::builder()
                .connect_timeout(CONNECT_TIMEOUT)
                .timeout(REQUEST_TIMEOUT)
                .redirect(reqwest::redirect::Policy::none())
                .resolve(host, socket)
                .build()
                .map_err(map_network_error)?;
            let response = client
                .get(current.clone())
                .headers(headers.clone())
                .send()
                .await
                .map_err(map_network_error)?;
            if response.status().is_redirection() {
                if redirect_count == MAX_REDIRECTS {
                    return Err(HentaiError::validation("too many redirects"));
                }
                let location = response
                    .headers()
                    .get(reqwest::header::LOCATION)
                    .and_then(|value| value.to_str().ok())
                    .ok_or_else(|| HentaiError::validation("redirect has no location"))?;
                current = current
                    .join(location)
                    .map_err(|error| HentaiError::validation(error.to_string()))?;
                continue;
            }
            if !response.status().is_success() {
                return Err(HentaiError::remote_unreachable(format!(
                    "profile request returned HTTP {}",
                    response.status()
                )));
            }
            let content_type = response
                .headers()
                .get(CONTENT_TYPE)
                .and_then(|value| value.to_str().ok())
                .map(str::to_string);
            let bytes = response.bytes().await.map_err(map_network_error)?.to_vec();
            if bytes.len() > max_bytes {
                return Err(HentaiError::validation("remote response is too large"));
            }
            return Ok(FetchResponse {
                final_url: current,
                content_type,
                bytes,
            });
        }
        Err(HentaiError::validation("redirect loop"))
    }
}

pub async fn fetch_platform_profile(
    transport: &dyn HttpTransport,
    platform: AuthorLinkPlatform,
    profile_url: &str,
) -> Result<Option<PlatformProfile>, HentaiError> {
    let profile_url =
        Url::parse(profile_url).map_err(|error| HentaiError::validation(error.to_string()))?;
    if platform == AuthorLinkPlatform::Discord {
        // Discord 无公开用户资料 API：只校验链接形状，不抓取头像/横幅。
        if !discord_link_shape_supported(&profile_url) {
            tracing::debug!("discord author link is not a supported public link");
        }
        return Ok(None);
    }
    let Some(request) = profile_request(platform, &profile_url)? else {
        return Ok(None);
    };
    let response = transport
        .get(&request.url, request.headers.clone(), PROFILE_MAX_BYTES)
        .await?;
    request.parse(&response).map(Some)
}

pub async fn download_platform_image(
    transport: &dyn HttpTransport,
    image_url: &str,
) -> Result<Vec<u8>, HentaiError> {
    let url = Url::parse(image_url).map_err(|error| HentaiError::validation(error.to_string()))?;
    let response = transport
        .get(
            &url,
            default_headers("image/avif,image/webp,image/*,*/*;q=0.8"),
            IMAGE_MAX_BYTES,
        )
        .await?;
    if response.bytes.len() > IMAGE_MAX_BYTES {
        return Err(HentaiError::validation(
            "platform image response is too large",
        ));
    }
    let content_type = response
        .content_type
        .unwrap_or_default()
        .to_ascii_lowercase();
    if !content_type.starts_with("image/") {
        return Err(HentaiError::validation(
            "platform image response is not an image",
        ));
    }
    crate::thumbnail::hd::encode_hd_image(&response.bytes)
}

struct ProfileRequest {
    url: Url,
    headers: HeaderMap,
    parser: Parser,
}

impl ProfileRequest {
    fn parse(&self, response: &FetchResponse) -> Result<PlatformProfile, HentaiError> {
        match self.parser {
            Parser::Pixiv => parse_pixiv(&response.bytes),
            Parser::X => parse_x(&response.bytes),
            Parser::Patreon => parse_open_graph(&response.bytes, &response.final_url),
            Parser::Fanbox => parse_fanbox(&response.bytes),
        }
    }
}

#[derive(Clone, Copy)]
enum Parser {
    Pixiv,
    X,
    Patreon,
    Fanbox,
}

fn profile_request(
    platform: AuthorLinkPlatform,
    profile_url: &Url,
) -> Result<Option<ProfileRequest>, HentaiError> {
    let host = profile_url
        .host_str()
        .unwrap_or_default()
        .to_ascii_lowercase();
    let segments: Vec<&str> = profile_url
        .path_segments()
        .map(|parts| parts.filter(|part| !part.is_empty()).collect())
        .unwrap_or_default();
    let request = match platform {
        AuthorLinkPlatform::Pixiv => {
            if !domain_matches(&host, "pixiv.net") {
                return Ok(None);
            }
            let user_id = match segments.as_slice() {
                ["users", id, ..] if id.chars().all(|c| c.is_ascii_digit()) => *id,
                _ => return Ok(None),
            };
            ProfileRequest {
                url: Url::parse(&format!(
                    "https://www.pixiv.net/ajax/user/{user_id}?full=1&lang=en"
                ))
                .expect("static Pixiv URL"),
                headers: default_headers("application/json"),
                parser: Parser::Pixiv,
            }
        }
        AuthorLinkPlatform::X => {
            if !(domain_matches(&host, "x.com") || domain_matches(&host, "twitter.com")) {
                return Ok(None);
            }
            let handle = match segments.as_slice() {
                [handle] if valid_handle(handle) => *handle,
                _ => return Ok(None),
            };
            ProfileRequest {
                url: Url::parse(&format!(
                    "https://cdn.syndication.twimg.com/widgets/followbutton/info.json?screen_names={handle}"
                ))
                .expect("static X URL"),
                headers: default_headers("application/json"),
                parser: Parser::X,
            }
        }
        AuthorLinkPlatform::Patreon => {
            if !domain_matches(&host, "patreon.com")
                || !patreon_creator_path(profile_url, &segments)
            {
                return Ok(None);
            }
            ProfileRequest {
                url: profile_url.clone(),
                headers: default_headers("text/html,application/xhtml+xml"),
                parser: Parser::Patreon,
            }
        }
        AuthorLinkPlatform::Fanbox => {
            let creator = if host.ends_with(".fanbox.cc") && host != "www.fanbox.cc" {
                host.trim_end_matches(".fanbox.cc").to_string()
            } else if domain_matches(&host, "pixiv.net") {
                match segments.as_slice() {
                    ["fanbox", "creator", creator, ..] => (*creator).to_string(),
                    _ => return Ok(None),
                }
            } else {
                return Ok(None);
            };
            let mut headers = default_headers("application/json");
            headers.insert(ORIGIN, HeaderValue::from_static("https://www.fanbox.cc"));
            ProfileRequest {
                url: Url::parse(&format!(
                    "https://api.fanbox.cc/creator.get?creatorId={creator}"
                ))
                .expect("static FANBOX URL"),
                headers,
                parser: Parser::Fanbox,
            }
        }
        AuthorLinkPlatform::Discord => {
            // Discord 无公开用户资料 API：仅校验链接形状，不抓取头像/横幅。
            return Ok(None);
        }
        AuthorLinkPlatform::Other => return Ok(None),
    };
    Ok(Some(request))
}

/// Patreon 仅支持 Creator 资料页：`/c/{vanity}`、`/user?u={id}` 或历史 `/{vanity}`。
/// `/posts/...`、`/c`（缺 slug）等非资料页视为 Unsupported。
fn patreon_creator_path(url: &Url, segments: &[&str]) -> bool {
    const RESERVED: &[&str] = &[
        "posts",
        "post",
        "c",
        "user",
        "join",
        "login",
        "signup",
        "home",
        "explore",
        "search",
        "settings",
        "api",
        "about",
        "careers",
        "policy",
        "legal",
        "support",
        "help",
        "create",
        "stream",
        "downloads",
        "gift",
        "checkout",
        "billing",
        "membership",
    ];
    match segments {
        ["c", _] => true,
        ["user"] => url
            .query_pairs()
            .any(|(key, value)| key == "u" && !value.is_empty()),
        [vanity] => !RESERVED.contains(vanity),
        _ => false,
    }
}

/// Discord 首版只校验链接是否为合法的公开 Discord 链接（邀请页或用户页），不解析资料。
fn discord_link_shape_supported(profile_url: &Url) -> bool {
    let host = profile_url
        .host_str()
        .unwrap_or_default()
        .to_ascii_lowercase();
    if !(domain_matches(&host, "discord.gg")
        || domain_matches(&host, "discord.com")
        || domain_matches(&host, "discordapp.com"))
    {
        return false;
    }
    let segments: Vec<&str> = profile_url
        .path_segments()
        .map(|parts| parts.filter(|part| !part.is_empty()).collect())
        .unwrap_or_default();
    match segments.as_slice() {
        [_code] => host == "discord.gg",
        ["invite", _code] => true,
        ["users", id] => !id.is_empty() && id.chars().all(|c| c.is_ascii_digit()),
        _ => false,
    }
}

fn parse_pixiv(bytes: &[u8]) -> Result<PlatformProfile, HentaiError> {
    let json: Value = serde_json::from_slice(bytes).map_err(parse_error)?;
    let body = &json["body"];
    Ok(PlatformProfile {
        display_name: string_at(body, &["name"]),
        avatar_url: string_at(body, &["imageBig"]).or_else(|| string_at(body, &["image"])),
        background_url: string_at(body, &["background", "url"]),
    })
}

fn parse_x(bytes: &[u8]) -> Result<PlatformProfile, HentaiError> {
    let json: Value = serde_json::from_slice(bytes).map_err(parse_error)?;
    let body = json
        .as_array()
        .and_then(|items| items.first())
        .ok_or_else(|| HentaiError::validation("X profile response is empty"))?;
    let avatar =
        string_at(body, &["profile_image_url_https"]).map(|url| url.replace("_normal.", "."));
    Ok(PlatformProfile {
        display_name: string_at(body, &["name"]),
        avatar_url: avatar,
        background_url: string_at(body, &["profile_banner_url"]),
    })
}

fn parse_fanbox(bytes: &[u8]) -> Result<PlatformProfile, HentaiError> {
    let json: Value = serde_json::from_slice(bytes).map_err(parse_error)?;
    let body = &json["body"];
    Ok(PlatformProfile {
        display_name: string_at(body, &["user", "name"])
            .or_else(|| string_at(body, &["creatorId"])),
        avatar_url: string_at(body, &["user", "iconUrl"]),
        background_url: string_at(body, &["coverImageUrl"]),
    })
}

fn parse_open_graph(bytes: &[u8], base: &Url) -> Result<PlatformProfile, HentaiError> {
    let html =
        std::str::from_utf8(bytes).map_err(|error| HentaiError::validation(error.to_string()))?;
    let document = Html::parse_document(html);
    let selector = Selector::parse("meta[property], meta[name]")
        .map_err(|error| HentaiError::validation(error.to_string()))?;
    let mut title = None;
    let mut image = None;
    for element in document.select(&selector) {
        let value = element.value();
        let key = value
            .attr("property")
            .or_else(|| value.attr("name"))
            .unwrap_or_default()
            .to_ascii_lowercase();
        let content = value
            .attr("content")
            .map(str::trim)
            .filter(|v| !v.is_empty());
        match key.as_str() {
            "og:title" | "twitter:title" if title.is_none() => title = content.map(str::to_string),
            "og:image" | "twitter:image" if image.is_none() => {
                image = content
                    .and_then(|raw| base.join(raw).ok())
                    .map(|url| url.to_string())
            }
            _ => {}
        }
    }
    Ok(PlatformProfile {
        display_name: title,
        avatar_url: image.clone(),
        background_url: image,
    })
}

fn string_at(value: &Value, path: &[&str]) -> Option<String> {
    let mut current = value;
    for part in path {
        current = current.get(*part)?;
    }
    current
        .as_str()
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .map(str::to_string)
}

fn default_headers(accept: &'static str) -> HeaderMap {
    let mut headers = HeaderMap::new();
    headers.insert(USER_AGENT, HeaderValue::from_static(APP_USER_AGENT));
    headers.insert(ACCEPT, HeaderValue::from_static(accept));
    headers
}

fn domain_matches(host: &str, domain: &str) -> bool {
    host == domain || host.ends_with(&format!(".{domain}"))
}

fn valid_handle(value: &str) -> bool {
    !value.is_empty()
        && value.len() <= 15
        && value.chars().all(|c| c.is_ascii_alphanumeric() || c == '_')
}

async fn validate_remote_url(url: &Url) -> Result<(), HentaiError> {
    if !matches!(url.scheme(), "http" | "https") {
        return Err(HentaiError::validation("only HTTP(S) URLs are allowed"));
    }
    if !url.username().is_empty() || url.password().is_some() {
        return Err(HentaiError::validation(
            "credentials in URLs are not allowed",
        ));
    }
    let host = url
        .host_str()
        .ok_or_else(|| HentaiError::validation("remote URL has no host"))?;
    if host.eq_ignore_ascii_case("localhost") {
        return Err(HentaiError::validation("local addresses are not allowed"));
    }
    Ok(())
}

async fn public_socket_for(host: &str, port: u16) -> Result<SocketAddr, HentaiError> {
    let addresses = tokio::net::lookup_host((host, port))
        .await
        .map_err(map_network_error)?;
    addresses
        .into_iter()
        .find(|address| is_public_ip(address.ip()))
        .ok_or_else(|| HentaiError::validation("local or private addresses are not allowed"))
}

fn is_public_ip(ip: IpAddr) -> bool {
    match ip {
        IpAddr::V4(ip) => {
            !(ip.is_private()
                || ip.is_loopback()
                || ip.is_link_local()
                || ip.is_broadcast()
                || ip.is_documentation()
                || ip.is_unspecified()
                || ip.octets()[0] == 0
                || ip.octets()[0] >= 224)
        }
        IpAddr::V6(ip) => {
            !(ip.is_loopback()
                || ip.is_unspecified()
                || ip.is_unique_local()
                || ip.is_unicast_link_local()
                || ip.is_multicast())
        }
    }
}

fn parse_error(error: serde_json::Error) -> HentaiError {
    HentaiError::validation(format!("invalid platform profile response: {error}"))
}

fn map_network_error(error: impl std::fmt::Display) -> HentaiError {
    let message = error.to_string();
    if message.to_ascii_lowercase().contains("timeout") {
        HentaiError::timed_out(message)
    } else {
        HentaiError::remote_unreachable(message)
    }
}

#[cfg(test)]
mod tests {
    use std::sync::atomic::{AtomicUsize, Ordering};

    use super::*;

    #[derive(Debug)]
    struct FixtureTransport {
        response: FetchResponse,
        calls: AtomicUsize,
    }

    impl FixtureTransport {
        fn new(response: FetchResponse) -> Self {
            Self {
                response,
                calls: AtomicUsize::new(0),
            }
        }

        fn calls(&self) -> usize {
            self.calls.load(Ordering::SeqCst)
        }
    }

    fn fixture_response(url: &str, content_type: &str, bytes: Vec<u8>) -> FetchResponse {
        FetchResponse {
            final_url: Url::parse(url).unwrap(),
            content_type: Some(content_type.to_string()),
            bytes,
        }
    }

    #[async_trait]
    impl HttpTransport for FixtureTransport {
        async fn get(
            &self,
            _url: &Url,
            _headers: HeaderMap,
            _max_bytes: usize,
        ) -> Result<FetchResponse, HentaiError> {
            self.calls.fetch_add(1, Ordering::SeqCst);
            Ok(self.response.clone())
        }
    }

    fn request_ok(platform: AuthorLinkPlatform, url: &str) -> bool {
        profile_request(platform, &Url::parse(url).unwrap())
            .unwrap()
            .is_some()
    }

    #[test]
    fn pixiv_profile_url_shapes_are_explicit() {
        assert!(request_ok(
            AuthorLinkPlatform::Pixiv,
            "https://www.pixiv.net/users/42"
        ));
        assert!(request_ok(
            AuthorLinkPlatform::Pixiv,
            "https://pixiv.net/users/42"
        ));
        // 作品页 / 首页 / 非资料页 => Unsupported，原 link 保留。
        assert!(!request_ok(
            AuthorLinkPlatform::Pixiv,
            "https://www.pixiv.net/artworks/42"
        ));
        assert!(!request_ok(
            AuthorLinkPlatform::Pixiv,
            "https://www.pixiv.net/"
        ));
        assert!(!request_ok(
            AuthorLinkPlatform::Pixiv,
            "https://www.pixiv.net/en/users/42"
        ));
        // 非 pixiv 主机不被误判。
        assert!(!request_ok(
            AuthorLinkPlatform::Pixiv,
            "https://example.com/users/42"
        ));
    }

    #[test]
    fn x_profile_url_shapes_are_explicit() {
        assert!(request_ok(AuthorLinkPlatform::X, "https://x.com/handle"));
        assert!(request_ok(
            AuthorLinkPlatform::X,
            "https://www.twitter.com/handle"
        ));
        // 帖子页 / 多段路径 => Unsupported。
        assert!(!request_ok(
            AuthorLinkPlatform::X,
            "https://x.com/handle/status/42"
        ));
        assert!(!request_ok(AuthorLinkPlatform::X, "https://x.com/"));
        // 超长或非法 handle => Unsupported。
        assert!(!request_ok(
            AuthorLinkPlatform::X,
            "https://x.com/this_handle_is_far_too_long"
        ));
    }

    #[test]
    fn patreon_only_creator_profiles_are_supported() {
        assert!(request_ok(
            AuthorLinkPlatform::Patreon,
            "https://www.patreon.com/c/creator"
        ));
        assert!(request_ok(
            AuthorLinkPlatform::Patreon,
            "https://www.patreon.com/creator"
        ));
        assert!(request_ok(
            AuthorLinkPlatform::Patreon,
            "https://www.patreon.com/user?u=42"
        ));
        // 帖子页 / 缺 slug / 缺 u 参数 / 首页 => Unsupported。
        assert!(!request_ok(
            AuthorLinkPlatform::Patreon,
            "https://www.patreon.com/posts/42"
        ));
        assert!(!request_ok(
            AuthorLinkPlatform::Patreon,
            "https://www.patreon.com/c"
        ));
        assert!(!request_ok(
            AuthorLinkPlatform::Patreon,
            "https://www.patreon.com/user"
        ));
        assert!(!request_ok(
            AuthorLinkPlatform::Patreon,
            "https://patreon.com/"
        ));
    }

    #[test]
    fn fanbox_and_pixiv_profiles_are_not_confused() {
        assert!(request_ok(
            AuthorLinkPlatform::Fanbox,
            "https://maker.fanbox.cc/"
        ));
        assert!(request_ok(
            AuthorLinkPlatform::Fanbox,
            "https://www.pixiv.net/fanbox/creator/42"
        ));
        // 普通 Pixiv profile 不是 FANBOX。
        assert!(!request_ok(
            AuthorLinkPlatform::Fanbox,
            "https://www.pixiv.net/users/42"
        ));
        assert!(!request_ok(
            AuthorLinkPlatform::Fanbox,
            "https://www.fanbox.cc/"
        ));
        assert!(!request_ok(
            AuthorLinkPlatform::Fanbox,
            "https://example.com/"
        ));
    }

    #[test]
    fn discord_links_are_validated_but_never_fetched() {
        // Discord 无公开用户资料 API：合法链接形状仅用于校验，不产生解析请求。
        assert!(discord_link_shape_supported(
            &Url::parse("https://discord.gg/example").unwrap()
        ));
        assert!(discord_link_shape_supported(
            &Url::parse("https://discord.com/invite/example").unwrap()
        ));
        assert!(discord_link_shape_supported(
            &Url::parse("https://discord.com/users/42").unwrap()
        ));
        // 频道页 / 根路径 / 非 Discord 主机 => 不是合法公开链接。
        assert!(!discord_link_shape_supported(
            &Url::parse("https://discord.com/channels/1/2").unwrap()
        ));
        assert!(!discord_link_shape_supported(
            &Url::parse("https://discord.com/").unwrap()
        ));
        assert!(!discord_link_shape_supported(
            &Url::parse("https://example.com/example").unwrap()
        ));
        // profile_request 对 Discord 一律返回 None。
        assert!(!request_ok(
            AuthorLinkPlatform::Discord,
            "https://discord.gg/example"
        ));
    }

    #[tokio::test]
    async fn discord_profile_fetch_skips_network_entirely() {
        let transport = FixtureTransport::new(fixture_response(
            "https://cdn.example/x.png",
            "image/png",
            Vec::new(),
        ));
        assert!(fetch_platform_profile(
            &transport,
            AuthorLinkPlatform::Discord,
            "https://discord.gg/example"
        )
        .await
        .unwrap()
        .is_none());
        assert_eq!(transport.calls(), 0);
    }

    #[test]
    fn parsers_extract_all_supported_fields_from_fixtures() {
        let pixiv = parse_pixiv(
            br#"{"body":{"name":"Pixiv Name","imageBig":"https://img/a.jpg","background":{"url":"https://img/b.jpg"}}}"#,
        )
        .unwrap();
        assert_eq!(pixiv.display_name.as_deref(), Some("Pixiv Name"));
        assert_eq!(pixiv.avatar_url.as_deref(), Some("https://img/a.jpg"));
        assert_eq!(pixiv.background_url.as_deref(), Some("https://img/b.jpg"));

        let x = parse_x(
            br#"[{"name":"X Name","profile_image_url_https":"https://img/a_normal.jpg","profile_banner_url":"https://img/b.jpg"}]"#,
        )
        .unwrap();
        assert_eq!(x.avatar_url.as_deref(), Some("https://img/a.jpg"));

        let fanbox = parse_fanbox(
            br#"{"body":{"creatorId":"maker","user":{"name":"Maker","iconUrl":"https://img/a.png"},"coverImageUrl":"https://img/b.png"}}"#,
        )
        .unwrap();
        assert_eq!(fanbox.display_name.as_deref(), Some("Maker"));

        let patreon = parse_open_graph(
            br#"<html><head><meta property="og:title" content="Creator"><meta property="og:image" content="/image.jpg"></head></html>"#,
            &Url::parse("https://www.patreon.com/c/creator").unwrap(),
        )
        .unwrap();
        assert_eq!(patreon.display_name.as_deref(), Some("Creator"));
        assert_eq!(
            patreon.avatar_url.as_deref(),
            Some("https://www.patreon.com/image.jpg")
        );
    }

    #[test]
    fn private_addresses_are_rejected() {
        assert!(!is_public_ip("127.0.0.1".parse().unwrap()));
        assert!(!is_public_ip("10.0.0.1".parse().unwrap()));
        assert!(!is_public_ip("::1".parse().unwrap()));
        assert!(is_public_ip("1.1.1.1".parse().unwrap()));
    }

    #[tokio::test]
    async fn downloader_rejects_unsafe_urls_content_and_size() {
        assert!(
            validate_remote_url(&Url::parse("ftp://example.com/image.png").unwrap())
                .await
                .is_err()
        );
        assert!(validate_remote_url(
            &Url::parse("https://user:pass@example.com/image.png").unwrap()
        )
        .await
        .is_err());
        assert!(
            validate_remote_url(&Url::parse("https://localhost/image.png").unwrap())
                .await
                .is_err()
        );

        let not_image = FixtureTransport::new(fixture_response(
            "https://cdn.example/image.png",
            "text/html",
            b"not an image".to_vec(),
        ));
        assert!(
            download_platform_image(&not_image, "https://cdn.example/image.png")
                .await
                .is_err()
        );

        let oversized = FixtureTransport::new(fixture_response(
            "https://cdn.example/image.png",
            "image/png",
            vec![0; IMAGE_MAX_BYTES + 1],
        ));
        assert!(
            download_platform_image(&oversized, "https://cdn.example/image.png")
                .await
                .is_err()
        );
    }
}
