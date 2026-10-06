use std::collections::HashMap;
use std::sync::{Arc, Mutex, OnceLock};
use std::time::{SystemTime, UNIX_EPOCH};

use sea_orm::{ConnectionTrait, Statement, Value};

use crate::db::{connection, map_db_err};
use crate::error::HentaiError;
use crate::image_cache::{ImageCache, PlatformImageKey};
use crate::runtime::runtime;

use super::platform::{download_platform_image, fetch_platform_profile, RestrictedHttpTransport};
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
    let links = creative_links(&db, author_id).await?;
    let cache = ImageCache::app()?;
    let mut result = CachedAuthorImages::default();
    for slot in [AuthorImageSlot::Avatar, AuthorImageSlot::Background] {
        for link in &links {
            let Some(cache_row) = cache_row(&db, link.id, slot).await? else {
                continue;
            };
            if cache_row.link_version != link.version
                || cache_row.profile_url != link.url
                || cache_row.image_url.is_none()
                || cache_row.cache_key.is_none()
            {
                continue;
            }
            if cache_row.checked_at + CACHE_TTL_SECONDS < unix_now() {
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
    let links = creative_links(&db, author_id).await?;
    let transport = RestrictedHttpTransport;
    let cache = ImageCache::app()?;
    for link in links {
        if link_cache_is_fresh(&db, &cache, &link).await? {
            continue;
        }
        let Some(profile) = fetch_platform_profile(&transport, link.platform, &link.url)
            .await
            .ok()
            .flatten()
        else {
            continue;
        };
        let display_name = profile.display_name.clone();
        if display_name.is_some() {
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "UPDATE author_links SET platform_display_name = ? WHERE id = ? AND version = ?",
                [
                    Value::from(display_name),
                    Value::from(link.id),
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
                upsert_cache_row(&db, link.id, slot, &link.url, None, link.version).await?;
                continue;
            };
            let existing = cache_row(&db, link.id, slot).await?;
            if existing.as_ref().and_then(|row| row.image_url.as_deref())
                == Some(image_url.as_str())
                && existing
                    .as_ref()
                    .and_then(|row| row.cache_key.as_deref())
                    .is_some()
            {
                update_checked_at(&db, link.id, slot, link.version).await?;
                continue;
            }
            let Ok(bytes) = download_platform_image(&transport, &image_url).await else {
                continue;
            };
            cache.write_platform_image(
                &PlatformImageKey {
                    author_link_id: link.id,
                    slot: slot.as_str(),
                },
                &bytes,
            )?;
            upsert_cache_row(
                &db,
                link.id,
                slot,
                &link.url,
                Some(&image_url),
                link.version,
            )
            .await?;
        }
    }
    Ok(())
}

async fn link_cache_is_fresh<C: ConnectionTrait>(
    db: &C,
    cache: &ImageCache,
    link: &LinkRow,
) -> Result<bool, HentaiError> {
    for slot in [AuthorImageSlot::Avatar, AuthorImageSlot::Background] {
        let Some(row) = cache_row(db, link.id, slot).await? else {
            return Ok(false);
        };
        if row.link_version != link.version
            || row.profile_url != link.url
            || row.checked_at + CACHE_TTL_SECONDS < unix_now()
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
    link_id: i64,
    slot: AuthorImageSlot,
    version: i64,
) -> Result<(), HentaiError> {
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "UPDATE author_image_cache SET checked_at = ?, link_version = ? \
         WHERE author_link_id = ? AND slot = ?",
        [
            Value::from(unix_now()),
            Value::from(version),
            Value::from(link_id),
            Value::from(slot.as_str().to_string()),
        ],
    ))
    .await
    .map_err(map_db_err)?;
    Ok(())
}

async fn upsert_cache_row<C: ConnectionTrait>(
    db: &C,
    link_id: i64,
    slot: AuthorImageSlot,
    profile_url: &str,
    image_url: Option<&str>,
    version: i64,
) -> Result<(), HentaiError> {
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
            Value::from(link_id),
            Value::from(slot.as_str().to_string()),
            Value::from(profile_url.to_string()),
            Value::from(image_url.map(str::to_owned)),
            Value::from(unix_now()),
            Value::from(unix_now()),
            Value::from(format!("{link_id}:{}:{version}", slot.as_str())),
            Value::from(version),
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
