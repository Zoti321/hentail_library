use std::collections::HashMap;
use std::sync::{Arc, Mutex, OnceLock};
use std::time::{SystemTime, UNIX_EPOCH};

use sea_orm::{ConnectionTrait, Statement, Value};

use crate::db::{connection, map_db_err};
use crate::error::HentaiError;
use crate::image_cache::{ImageCache, PlatformImageKey};
use crate::runtime::runtime;

use super::platform::{
    download_platform_image, fetch_platform_profile, HttpTransport, RestrictedHttpTransport,
};
use super::{AuthorImageSlot, AuthorLinkPlatform};

const CACHE_TTL_SECONDS: i64 = 7 * 24 * 60 * 60;

fn refresh_locks() -> &'static Mutex<HashMap<i64, Arc<tokio::sync::Mutex<()>>>> {
    static LOCKS: OnceLock<Mutex<HashMap<i64, Arc<tokio::sync::Mutex<()>>>>> = OnceLock::new();
    LOCKS.get_or_init(|| Mutex::new(HashMap::new()))
}

pub(crate) fn author_refresh_lock(author_id: i64) -> Arc<tokio::sync::Mutex<()>> {
    let mut locks = refresh_locks().lock().expect("author refresh locks");
    locks
        .entry(author_id)
        .or_insert_with(|| Arc::new(tokio::sync::Mutex::new(())))
        .clone()
}

#[derive(Debug, Clone, Default)]
pub struct CachedAuthorImages {
    pub avatar_link_id: Option<i64>,
    pub background_link_id: Option<i64>,
}

#[derive(Debug, Clone)]
struct LinkRow {
    id: i64,
    platform: AuthorLinkPlatform,
    url: String,
    version: i64,
}

pub fn schedule_author_image_refresh(author_id: i64) {
    let lock = author_refresh_lock(author_id);
    std::mem::drop(runtime().spawn(async move {
        let _guard = lock.lock().await;
        if let Err(error) = refresh_author_images(author_id).await {
            tracing::debug!(author_id, error = %error, "author platform image refresh skipped");
        }
    }));
}

pub async fn resolve_cached_author_image(
    author_id: i64,
) -> Result<CachedAuthorImages, HentaiError> {
    let db = connection()?;
    let cache = ImageCache::app()?;
    resolve_cached_author_image_on(&db, &cache, author_id).await
}

async fn resolve_cached_author_image_on<C: ConnectionTrait>(
    db: &C,
    cache: &ImageCache,
    author_id: i64,
) -> Result<CachedAuthorImages, HentaiError> {
    let links = creative_links(db, author_id).await?;
    let mut result = CachedAuthorImages::default();
    for slot in [AuthorImageSlot::Avatar, AuthorImageSlot::Background] {
        for link in &links {
            let Some(cache_row) = cache_row(db, link.id, slot).await? else {
                continue;
            };
            if cache_row.link_version != link.version
                || cache_row.profile_url != link.url
                || cache_row.image_url.is_none()
                || cache_row.cache_key.is_none()
            {
                continue;
            }
            let key = PlatformImageKey {
                author_link_id: link.id,
                slot: slot.as_str(),
            };
            if cache.read_platform_image(&key).is_some() {
                match slot {
                    AuthorImageSlot::Avatar => result.avatar_link_id = Some(link.id),
                    AuthorImageSlot::Background => result.background_link_id = Some(link.id),
                }
                break;
            }
        }
    }
    Ok(result)
}

pub fn load_cached_platform_image(
    link_id: i64,
    slot: AuthorImageSlot,
) -> Result<Option<Vec<u8>>, HentaiError> {
    let cache = ImageCache::app()?;
    let Some(bytes) = cache.read_platform_image(&PlatformImageKey {
        author_link_id: link_id,
        slot: slot.as_str(),
    }) else {
        return Ok(None);
    };
    if image::load_from_memory(&bytes).is_err() {
        return Ok(None);
    }
    Ok(Some(bytes))
}

async fn refresh_author_images(author_id: i64) -> Result<(), HentaiError> {
    let db = connection()?;
    let transport = RestrictedHttpTransport;
    let cache = ImageCache::app()?;
    refresh_author_images_with(&db, &cache, &transport, author_id, unix_now()).await
}

async fn refresh_author_images_with<C: ConnectionTrait>(
    db: &C,
    cache: &ImageCache,
    transport: &dyn HttpTransport,
    author_id: i64,
    now: i64,
) -> Result<(), HentaiError> {
    let links = creative_links(db, author_id).await?;
    for link in links {
        if link_cache_is_fresh(db, cache, &link, now).await? {
            continue;
        }
        let profile = match fetch_platform_profile(transport, link.platform, &link.url).await {
            Ok(Some(profile)) => profile,
            Ok(None) => continue,
            Err(error) => {
                tracing::debug!(
                    author_id,
                    link_id = link.id,
                    platform = link.platform.as_str(),
                    error = %error,
                    "author platform profile refresh failed"
                );
                continue;
            }
        };
        if !link_is_current(db, &link).await? {
            continue;
        }
        let display_name = profile.display_name.clone();
        if display_name.is_some() {
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "UPDATE author_links SET platform_display_name = ? \
                 WHERE id = ? AND url = ? AND version = ?",
                [
                    Value::from(display_name),
                    Value::from(link.id),
                    Value::from(link.url.clone()),
                    Value::from(link.version),
                ],
            ))
            .await
            .map_err(map_db_err)?;
        }
        for (slot, image_url) in [
            (AuthorImageSlot::Avatar, profile.avatar_url),
            (AuthorImageSlot::Background, profile.background_url),
        ] {
            let Some(image_url) = image_url else {
                upsert_cache_row(db, &link, slot, None, now).await?;
                continue;
            };
            let existing = cache_row(db, link.id, slot).await?;
            let key = PlatformImageKey {
                author_link_id: link.id,
                slot: slot.as_str(),
            };
            if existing.as_ref().and_then(|row| row.image_url.as_deref())
                == Some(image_url.as_str())
                && existing
                    .as_ref()
                    .and_then(|row| row.cache_key.as_deref())
                    .is_some()
                && cache.read_platform_image(&key).is_some()
            {
                update_checked_at(db, &link, slot, now).await?;
                continue;
            }
            let bytes = match download_platform_image(transport, &image_url).await {
                Ok(bytes) => bytes,
                Err(error) => {
                    tracing::debug!(
                        author_id,
                        link_id = link.id,
                        platform = link.platform.as_str(),
                        slot = slot.as_str(),
                        error = %error,
                        "author platform image refresh failed"
                    );
                    continue;
                }
            };
            if !link_is_current(db, &link).await? {
                continue;
            }
            cache.write_platform_image(&key, &bytes)?;
            upsert_cache_row(db, &link, slot, Some(&image_url), now).await?;
        }
    }
    Ok(())
}

async fn link_cache_is_fresh<C: ConnectionTrait>(
    db: &C,
    cache: &ImageCache,
    link: &LinkRow,
    now: i64,
) -> Result<bool, HentaiError> {
    for slot in [AuthorImageSlot::Avatar, AuthorImageSlot::Background] {
        let Some(row) = cache_row(db, link.id, slot).await? else {
            return Ok(false);
        };
        if row.link_version != link.version
            || row.profile_url != link.url
            || row.checked_at + CACHE_TTL_SECONDS < now
        {
            return Ok(false);
        }
        if row.image_url.is_some()
            && cache
                .read_platform_image(&PlatformImageKey {
                    author_link_id: link.id,
                    slot: slot.as_str(),
                })
                .is_none()
        {
            return Ok(false);
        }
    }
    Ok(true)
}

async fn link_is_current<C: ConnectionTrait>(db: &C, link: &LinkRow) -> Result<bool, HentaiError> {
    let row = db
        .query_one(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT 1 FROM author_links WHERE id = ? AND url = ? AND version = ?",
            [
                Value::from(link.id),
                Value::from(link.url.clone()),
                Value::from(link.version),
            ],
        ))
        .await
        .map_err(map_db_err)?;
    Ok(row.is_some())
}

async fn creative_links<C: ConnectionTrait>(
    db: &C,
    author_id: i64,
) -> Result<Vec<LinkRow>, HentaiError> {
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT id, platform, url, version FROM author_links \
             WHERE author_id = ? AND platform != 'other' ORDER BY \
             CASE platform WHEN 'pixiv' THEN 0 WHEN 'x' THEN 1 WHEN 'patreon' THEN 2 \
             WHEN 'fanbox' THEN 3 WHEN 'discord' THEN 4 ELSE 5 END, sort_key ASC, id ASC",
            [Value::from(author_id)],
        ))
        .await
        .map_err(map_db_err)?;
    rows.into_iter()
        .map(|row| {
            let platform = row
                .try_get_by_index::<String>(1)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
            Ok(LinkRow {
                id: row
                    .try_get_by_index(0)
                    .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
                platform: AuthorLinkPlatform::parse(&platform)?,
                url: row
                    .try_get_by_index(2)
                    .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
                version: row.try_get_by_index(3).unwrap_or(1),
            })
        })
        .collect()
}

#[derive(Debug)]
struct CacheRow {
    profile_url: String,
    image_url: Option<String>,
    checked_at: i64,
    cache_key: Option<String>,
    link_version: i64,
}

async fn cache_row<C: ConnectionTrait>(
    db: &C,
    link_id: i64,
    slot: AuthorImageSlot,
) -> Result<Option<CacheRow>, HentaiError> {
    let row = db
        .query_one(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT profile_url, image_url, checked_at, cache_key, link_version \
             FROM author_image_cache WHERE author_link_id = ? AND slot = ?",
            [Value::from(link_id), Value::from(slot.as_str().to_string())],
        ))
        .await
        .map_err(map_db_err)?;
    row.map(|row| {
        Ok(CacheRow {
            profile_url: row
                .try_get_by_index(0)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
            image_url: row.try_get_by_index(1).unwrap_or(None),
            checked_at: row
                .try_get_by_index(2)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
            cache_key: row.try_get_by_index(3).unwrap_or(None),
            link_version: row
                .try_get_by_index(4)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
        })
    })
    .transpose()
}

async fn update_checked_at<C: ConnectionTrait>(
    db: &C,
    link: &LinkRow,
    slot: AuthorImageSlot,
    now: i64,
) -> Result<(), HentaiError> {
    if !link_is_current(db, link).await? {
        return Ok(());
    }
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "UPDATE author_image_cache SET checked_at = ?, link_version = ? \
         WHERE author_link_id = ? AND slot = ?",
        [
            Value::from(now),
            Value::from(link.version),
            Value::from(link.id),
            Value::from(slot.as_str().to_string()),
        ],
    ))
    .await
    .map_err(map_db_err)?;
    Ok(())
}

async fn upsert_cache_row<C: ConnectionTrait>(
    db: &C,
    link: &LinkRow,
    slot: AuthorImageSlot,
    image_url: Option<&str>,
    now: i64,
) -> Result<(), HentaiError> {
    if !link_is_current(db, link).await? {
        return Ok(());
    }
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO author_image_cache \
         (author_link_id, slot, profile_url, image_url, checked_at, fetched_at, cache_key, link_version) \
         VALUES (?, ?, ?, ?, ?, ?, ?, ?) \
         ON CONFLICT(author_link_id, slot) DO UPDATE SET \
         profile_url = excluded.profile_url, image_url = excluded.image_url, \
         checked_at = excluded.checked_at, fetched_at = excluded.fetched_at, \
         cache_key = excluded.cache_key, link_version = excluded.link_version",
        [
            Value::from(link.id),
            Value::from(slot.as_str().to_string()),
            Value::from(link.url.clone()),
            Value::from(image_url.map(str::to_owned)),
            Value::from(now),
            Value::from(now),
            Value::from(format!("{}:{}:{}", link.id, slot.as_str(), link.version)),
            Value::from(link.version),
        ],
    ))
    .await
    .map_err(map_db_err)?;
    Ok(())
}

fn unix_now() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_secs() as i64)
        .unwrap_or(0)
}

impl AuthorImageSlot {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Avatar => "avatar",
            Self::Background => "background",
        }
    }
}

#[cfg(test)]
mod tests {
    use std::collections::{HashMap, HashSet};
    use std::io::Cursor;
    use std::sync::atomic::{AtomicUsize, Ordering};

    use async_trait::async_trait;
    use image::{DynamicImage, ImageFormat, Rgba, RgbaImage};
    use reqwest::header::HeaderMap;
    use sea_orm::{Database, DatabaseConnection};
    use tokio::sync::{Notify, Semaphore};
    use url::Url;

    use super::super::platform::FetchResponse;
    use super::*;

    #[derive(Default)]
    struct FixtureTransport {
        responses: HashMap<String, FetchResponse>,
        failures: HashSet<String>,
        calls: Mutex<Vec<String>>,
        blocked_url: Option<String>,
        entered: Option<Arc<Semaphore>>,
        release: Option<Arc<Notify>>,
        profile_calls: AtomicUsize,
    }

    impl FixtureTransport {
        fn response(mut self, url: &str, content_type: &str, bytes: Vec<u8>) -> Self {
            self.responses.insert(
                url.to_string(),
                FetchResponse {
                    final_url: Url::parse(url).expect("fixture URL"),
                    content_type: Some(content_type.to_string()),
                    bytes,
                },
            );
            self
        }

        fn failure(mut self, url: &str) -> Self {
            self.failures.insert(url.to_string());
            self
        }

        fn blocked(mut self, url: &str, entered: Arc<Semaphore>, release: Arc<Notify>) -> Self {
            self.blocked_url = Some(url.to_string());
            self.entered = Some(entered);
            self.release = Some(release);
            self
        }

        fn calls(&self) -> Vec<String> {
            self.calls.lock().expect("calls").clone()
        }
    }

    #[async_trait]
    impl HttpTransport for FixtureTransport {
        async fn get(
            &self,
            url: &Url,
            _headers: HeaderMap,
            max_bytes: usize,
        ) -> Result<FetchResponse, HentaiError> {
            let key = url.as_str().to_string();
            self.calls.lock().expect("calls").push(key.clone());
            if key.contains("/ajax/user/") {
                self.profile_calls.fetch_add(1, Ordering::SeqCst);
            }
            if self.blocked_url.as_deref() == Some(key.as_str()) {
                self.entered.as_ref().expect("entered").add_permits(1);
                self.release.as_ref().expect("release").notified().await;
            }
            if self.failures.contains(&key) {
                return Err(HentaiError::remote_unreachable("fixture failure"));
            }
            let response = self
                .responses
                .get(&key)
                .cloned()
                .ok_or_else(|| HentaiError::remote_unreachable("missing fixture response"))?;
            if response.bytes.len() > max_bytes {
                return Err(HentaiError::validation("fixture response too large"));
            }
            Ok(response)
        }
    }

    async fn fixture_db() -> DatabaseConnection {
        let db = Database::connect("sqlite::memory:").await.expect("db");
        db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "CREATE TABLE author_links (
                id INTEGER PRIMARY KEY,
                author_id INTEGER NOT NULL,
                platform TEXT NOT NULL,
                url TEXT NOT NULL,
                platform_display_name TEXT,
                sort_key INTEGER NOT NULL,
                version INTEGER NOT NULL
             );
             CREATE TABLE author_image_cache (
                author_link_id INTEGER NOT NULL,
                slot TEXT NOT NULL,
                profile_url TEXT NOT NULL,
                image_url TEXT,
                checked_at INTEGER NOT NULL,
                fetched_at INTEGER,
                cache_key TEXT,
                link_version INTEGER NOT NULL,
                PRIMARY KEY (author_link_id, slot)
             );"
            .to_string(),
        ))
        .await
        .expect("schema");
        db
    }

    async fn insert_link(
        db: &DatabaseConnection,
        id: i64,
        author_id: i64,
        platform: &str,
        url: &str,
        sort_key: i64,
    ) {
        db.execute(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "INSERT INTO author_links (id, author_id, platform, url, sort_key, version) \
             VALUES (?, ?, ?, ?, ?, 1)",
            [
                Value::from(id),
                Value::from(author_id),
                Value::from(platform.to_string()),
                Value::from(url.to_string()),
                Value::from(sort_key),
            ],
        ))
        .await
        .expect("link");
    }

    struct CacheFixture<'a> {
        link_id: i64,
        slot: AuthorImageSlot,
        profile_url: &'a str,
        image_url: Option<&'a str>,
        checked_at: i64,
        file_bytes: Option<&'a [u8]>,
    }

    async fn insert_cache(db: &DatabaseConnection, cache: &ImageCache, fixture: CacheFixture<'_>) {
        db.execute(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "INSERT INTO author_image_cache \
             (author_link_id, slot, profile_url, image_url, checked_at, fetched_at, cache_key, link_version) \
             VALUES (?, ?, ?, ?, ?, ?, ?, 1)",
            [
                Value::from(fixture.link_id),
                Value::from(fixture.slot.as_str().to_string()),
                Value::from(fixture.profile_url.to_string()),
                Value::from(fixture.image_url.map(str::to_string)),
                Value::from(fixture.checked_at),
                Value::from(fixture.checked_at),
                Value::from(fixture.image_url.map(|_| {
                    format!("{}:{}:1", fixture.link_id, fixture.slot.as_str())
                })),
            ],
        ))
        .await
        .expect("cache row");
        if let Some(bytes) = fixture.file_bytes {
            cache
                .write_platform_image(
                    &PlatformImageKey {
                        author_link_id: fixture.link_id,
                        slot: fixture.slot.as_str(),
                    },
                    bytes,
                )
                .expect("cache file");
        }
    }

    fn png(pixel: [u8; 4]) -> Vec<u8> {
        let image = RgbaImage::from_pixel(1, 1, Rgba(pixel));
        let mut cursor = Cursor::new(Vec::new());
        DynamicImage::ImageRgba8(image)
            .write_to(&mut cursor, ImageFormat::Png)
            .expect("png");
        cursor.into_inner()
    }

    fn pixiv_profile(avatar: &str, background: &str) -> Vec<u8> {
        format!(
            r#"{{"body":{{"name":"Fixture","imageBig":"{avatar}","background":{{"url":"{background}"}}}}}}"#
        )
        .into_bytes()
    }

    #[tokio::test]
    async fn source_selection_uses_platform_then_sort_key_and_keeps_slots_independent() {
        let db = fixture_db().await;
        let temp = tempfile::TempDir::new().expect("tempdir");
        let cache = ImageCache::with_root(temp.path(), 1024 * 1024);
        insert_link(&db, 1, 7, "x", "https://x.com/x", 0).await;
        insert_link(&db, 2, 7, "pixiv", "https://www.pixiv.net/users/2", 5).await;
        insert_link(&db, 3, 7, "pixiv", "https://www.pixiv.net/users/3", 0).await;
        insert_link(&db, 4, 7, "other", "https://example.com", -1).await;
        insert_link(&db, 5, 7, "pixiv", "https://www.pixiv.net/users/5", 0).await;
        insert_link(&db, 6, 7, "patreon", "https://patreon.com/p", -10).await;
        insert_link(&db, 7, 7, "fanbox", "https://f.fanbox.cc", -10).await;
        insert_link(&db, 8, 7, "discord", "https://discord.gg/d", -10).await;
        insert_cache(
            &db,
            &cache,
            CacheFixture {
                link_id: 1,
                slot: AuthorImageSlot::Background,
                profile_url: "https://x.com/x",
                image_url: Some("https://img/x-bg.png"),
                checked_at: 1,
                file_bytes: Some(b"x background"),
            },
        )
        .await;
        for link_id in [2, 3, 5] {
            insert_cache(
                &db,
                &cache,
                CacheFixture {
                    link_id,
                    slot: AuthorImageSlot::Avatar,
                    profile_url: &format!("https://www.pixiv.net/users/{link_id}"),
                    image_url: Some("https://img/pixiv-avatar.png"),
                    checked_at: 1,
                    file_bytes: Some(b"pixiv avatar"),
                },
            )
            .await;
        }
        insert_cache(
            &db,
            &cache,
            CacheFixture {
                link_id: 4,
                slot: AuthorImageSlot::Background,
                profile_url: "https://example.com",
                image_url: Some("https://img/other.png"),
                checked_at: 1,
                file_bytes: Some(b"other"),
            },
        )
        .await;

        let selected = resolve_cached_author_image_on(&db, &cache, 7)
            .await
            .expect("resolve");
        let ordered_ids: Vec<i64> = creative_links(&db, 7)
            .await
            .expect("links")
            .into_iter()
            .map(|link| link.id)
            .collect();

        assert_eq!(selected.avatar_link_id, Some(3));
        assert_eq!(selected.background_link_id, Some(1));
        assert_eq!(ordered_ids, vec![3, 5, 2, 1, 6, 7, 8]);
    }

    #[tokio::test]
    async fn ttl_skips_fresh_network_and_expired_profile_failure_keeps_old_slots() {
        let db = fixture_db().await;
        let temp = tempfile::TempDir::new().expect("tempdir");
        let cache = ImageCache::with_root(temp.path(), 1024 * 1024);
        let profile_url = "https://www.pixiv.net/users/42";
        let request_url = "https://www.pixiv.net/ajax/user/42?full=1&lang=en";
        insert_link(&db, 42, 8, "pixiv", profile_url, 0).await;
        for slot in [AuthorImageSlot::Avatar, AuthorImageSlot::Background] {
            insert_cache(
                &db,
                &cache,
                CacheFixture {
                    link_id: 42,
                    slot,
                    profile_url,
                    image_url: Some("https://img/old.png"),
                    checked_at: 100,
                    file_bytes: Some(b"old image"),
                },
            )
            .await;
        }
        let transport = FixtureTransport::default().failure(request_url);

        refresh_author_images_with(&db, &cache, &transport, 8, 100 + CACHE_TTL_SECONDS)
            .await
            .expect("fresh");
        assert!(transport.calls().is_empty());

        refresh_author_images_with(&db, &cache, &transport, 8, 101 + CACHE_TTL_SECONDS)
            .await
            .expect("expired");
        assert_eq!(transport.calls(), vec![request_url]);
        let selected = resolve_cached_author_image_on(&db, &cache, 8)
            .await
            .expect("resolve");
        assert_eq!(selected.avatar_link_id, Some(42));
        assert_eq!(selected.background_link_id, Some(42));
    }

    #[tokio::test]
    async fn refresh_updates_successful_slot_and_preserves_failed_slot() {
        let db = fixture_db().await;
        let temp = tempfile::TempDir::new().expect("tempdir");
        let cache = ImageCache::with_root(temp.path(), 1024 * 1024);
        let profile_url = "https://www.pixiv.net/users/42";
        let request_url = "https://www.pixiv.net/ajax/user/42?full=1&lang=en";
        let avatar_url = "https://img.example/new-avatar.png";
        let background_url = "https://img.example/new-background.png";
        insert_link(&db, 42, 9, "pixiv", profile_url, 0).await;
        insert_cache(
            &db,
            &cache,
            CacheFixture {
                link_id: 42,
                slot: AuthorImageSlot::Avatar,
                profile_url,
                image_url: Some("https://img.example/old-avatar.png"),
                checked_at: 1,
                file_bytes: Some(b"old avatar"),
            },
        )
        .await;
        insert_cache(
            &db,
            &cache,
            CacheFixture {
                link_id: 42,
                slot: AuthorImageSlot::Background,
                profile_url,
                image_url: Some("https://img.example/old-background.png"),
                checked_at: 1,
                file_bytes: Some(b"old background"),
            },
        )
        .await;
        let transport = FixtureTransport::default()
            .response(
                request_url,
                "application/json",
                pixiv_profile(avatar_url, background_url),
            )
            .response(avatar_url, "image/png", png([255, 0, 0, 255]))
            .failure(background_url);

        refresh_author_images_with(&db, &cache, &transport, 9, 1_000_000)
            .await
            .expect("refresh");

        let avatar = cache
            .read_platform_image(&PlatformImageKey {
                author_link_id: 42,
                slot: "avatar",
            })
            .expect("avatar");
        let background = cache
            .read_platform_image(&PlatformImageKey {
                author_link_id: 42,
                slot: "background",
            })
            .expect("background");
        assert_ne!(avatar, b"old avatar");
        assert_eq!(background, b"old background");
        assert_eq!(
            cache_row(&db, 42, AuthorImageSlot::Avatar)
                .await
                .expect("row")
                .expect("avatar")
                .image_url
                .as_deref(),
            Some(avatar_url)
        );
        assert_eq!(
            cache_row(&db, 42, AuthorImageSlot::Background)
                .await
                .expect("row")
                .expect("background")
                .image_url
                .as_deref(),
            Some("https://img.example/old-background.png")
        );
    }

    #[tokio::test]
    async fn missing_file_with_unchanged_url_is_downloaded_again() {
        let db = fixture_db().await;
        let temp = tempfile::TempDir::new().expect("tempdir");
        let cache = ImageCache::with_root(temp.path(), 1024 * 1024);
        let profile_url = "https://www.pixiv.net/users/42";
        let request_url = "https://www.pixiv.net/ajax/user/42?full=1&lang=en";
        let avatar_url = "https://img.example/avatar.png";
        insert_link(&db, 42, 10, "pixiv", profile_url, 0).await;
        insert_cache(
            &db,
            &cache,
            CacheFixture {
                link_id: 42,
                slot: AuthorImageSlot::Avatar,
                profile_url,
                image_url: Some(avatar_url),
                checked_at: 1,
                file_bytes: None,
            },
        )
        .await;
        insert_cache(
            &db,
            &cache,
            CacheFixture {
                link_id: 42,
                slot: AuthorImageSlot::Background,
                profile_url,
                image_url: None,
                checked_at: 1,
                file_bytes: None,
            },
        )
        .await;
        let transport = FixtureTransport::default()
            .response(
                request_url,
                "application/json",
                pixiv_profile(avatar_url, ""),
            )
            .response(avatar_url, "image/png", png([0, 255, 0, 255]));

        refresh_author_images_with(&db, &cache, &transport, 10, 1_000_000)
            .await
            .expect("refresh");

        assert!(cache
            .read_platform_image(&PlatformImageKey {
                author_link_id: 42,
                slot: "avatar",
            })
            .is_some());
        assert!(transport.calls().iter().any(|url| url == avatar_url));
    }

    #[tokio::test]
    async fn stale_task_does_not_write_after_link_version_changes() {
        let db = fixture_db().await;
        let temp = tempfile::TempDir::new().expect("tempdir");
        let cache = ImageCache::with_root(temp.path(), 1024 * 1024);
        let profile_url = "https://www.pixiv.net/users/42";
        let request_url = "https://www.pixiv.net/ajax/user/42?full=1&lang=en";
        let avatar_url = "https://img.example/avatar.png";
        insert_link(&db, 42, 11, "pixiv", profile_url, 0).await;
        let entered = Arc::new(Semaphore::new(0));
        let release = Arc::new(Notify::new());
        let transport = Arc::new(
            FixtureTransport::default()
                .response(
                    request_url,
                    "application/json",
                    pixiv_profile(avatar_url, ""),
                )
                .response(avatar_url, "image/png", png([0, 0, 255, 255]))
                .blocked(avatar_url, entered.clone(), release.clone()),
        );
        let task_db = db.clone();
        let task_cache = cache.clone();
        let task_transport = transport.clone();
        let task = tokio::spawn(async move {
            refresh_author_images_with(
                &task_db,
                &task_cache,
                task_transport.as_ref(),
                11,
                1_000_000,
            )
            .await
        });
        entered.acquire().await.expect("image request").forget();
        db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "UPDATE author_links SET url = 'https://www.pixiv.net/users/99', version = 2 \
             WHERE id = 42"
                .to_string(),
        ))
        .await
        .expect("update link");
        release.notify_waiters();
        task.await.expect("join").expect("refresh");

        assert!(cache
            .read_platform_image(&PlatformImageKey {
                author_link_id: 42,
                slot: "avatar",
            })
            .is_none());
        assert!(cache_row(&db, 42, AuthorImageSlot::Avatar)
            .await
            .expect("row")
            .is_none());
    }

    #[tokio::test]
    async fn author_refresh_lock_makes_concurrent_refresh_single_flight() {
        let db = fixture_db().await;
        let temp = tempfile::TempDir::new().expect("tempdir");
        let cache = ImageCache::with_root(temp.path(), 1024 * 1024);
        let profile_url = "https://www.pixiv.net/users/42";
        let request_url = "https://www.pixiv.net/ajax/user/42?full=1&lang=en";
        let avatar_url = "https://img.example/avatar.png";
        let background_url = "https://img.example/background.png";
        insert_link(&db, 42, 12, "pixiv", profile_url, 0).await;
        let entered = Arc::new(Semaphore::new(0));
        let release = Arc::new(Notify::new());
        let transport = Arc::new(
            FixtureTransport::default()
                .response(
                    request_url,
                    "application/json",
                    pixiv_profile(avatar_url, background_url),
                )
                .response(avatar_url, "image/png", png([1, 2, 3, 255]))
                .response(background_url, "image/png", png([4, 5, 6, 255]))
                .blocked(request_url, entered.clone(), release.clone()),
        );
        let lock = author_refresh_lock(12);
        let mut tasks = Vec::new();
        for _ in 0..2 {
            let task_db = db.clone();
            let task_cache = cache.clone();
            let task_transport = transport.clone();
            let task_lock = lock.clone();
            tasks.push(tokio::spawn(async move {
                let _guard = task_lock.lock().await;
                refresh_author_images_with(
                    &task_db,
                    &task_cache,
                    task_transport.as_ref(),
                    12,
                    1_000_000,
                )
                .await
            }));
        }
        entered.acquire().await.expect("profile request").forget();
        release.notify_waiters();
        for task in tasks {
            task.await.expect("join").expect("refresh");
        }

        assert_eq!(transport.profile_calls.load(Ordering::SeqCst), 1);
    }
}
