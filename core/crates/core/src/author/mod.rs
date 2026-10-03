//! Author 稳定身份：字典、Comic 附着、Author link、详情聚合与形象端口 stub。

use std::collections::HashSet;

use sea_orm::{
    ColumnTrait, ConnectionTrait, EntityTrait, PaginatorTrait, QueryFilter, QueryOrder,
    QuerySelect, Set, Statement, Value,
};

use crate::comic::visibility::{visible_comic_id_sql, visible_comic_sql};
use crate::db::{connection, map_db_err};
use crate::entity::{author_links, authors, prelude::*};
use crate::error::HentaiError;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AuthorIdentity {
    pub id: i64,
    pub name: String,
    pub verified: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AuthorLinkPlatform {
    Pixiv,
    X,
    Patreon,
    Fanbox,
    Discord,
    Other,
}

impl AuthorLinkPlatform {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Pixiv => "pixiv",
            Self::X => "x",
            Self::Patreon => "patreon",
            Self::Fanbox => "fanbox",
            Self::Discord => "discord",
            Self::Other => "other",
        }
    }

    pub fn parse(raw: &str) -> Result<Self, HentaiError> {
        match raw.trim() {
            "pixiv" => Ok(Self::Pixiv),
            "x" => Ok(Self::X),
            "patreon" => Ok(Self::Patreon),
            "fanbox" => Ok(Self::Fanbox),
            "discord" => Ok(Self::Discord),
            "other" => Ok(Self::Other),
            other => Err(HentaiError::validation(format!("未知创作平台: {other}"))),
        }
    }

    pub fn is_creative(self) -> bool {
        !matches!(self, Self::Other)
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AuthorLinkDto {
    pub id: i64,
    pub platform: AuthorLinkPlatform,
    pub url: String,
    pub platform_display_name: Option<String>,
    pub sort_key: i64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AuthorFacetCountDto {
    pub name: String,
    pub attachment_count: i64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AuthorTopComicDto {
    pub comic_id: String,
    pub title: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AuthorDetailDto {
    pub identity: AuthorIdentity,
    pub links: Vec<AuthorLinkDto>,
    pub tags: Vec<AuthorFacetCountDto>,
    pub parodies: Vec<AuthorFacetCountDto>,
    pub characters: Vec<AuthorFacetCountDto>,
    pub top_comics: Vec<AuthorTopComicDto>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AuthorImageSource {
    PlatformCached,
    ComicCover,
    None,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AuthorImageRef {
    pub avatar_source: AuthorImageSource,
    pub avatar_comic_id: Option<String>,
    pub background_source: AuthorImageSource,
    pub background_comic_id: Option<String>,
}

pub async fn list_all_authors() -> Result<Vec<AuthorIdentity>, HentaiError> {
    let db = connection()?;
    list_all_authors_on(&db).await
}

async fn list_all_authors_on<C: ConnectionTrait>(
    db: &C,
) -> Result<Vec<AuthorIdentity>, HentaiError> {
    let rows = Authors::find()
        .order_by_asc(authors::Column::Name)
        .all(db)
        .await
        .map_err(map_db_err)?;
    let verified_ids = verified_author_ids(db).await?;
    Ok(rows
        .into_iter()
        .map(|r| AuthorIdentity {
            id: r.id,
            name: r.name,
            verified: verified_ids.contains(&r.id),
        })
        .collect())
}

pub async fn count_all_authors() -> Result<i64, HentaiError> {
    let db = connection()?;
    Authors::find()
        .count(&db)
        .await
        .map_err(map_db_err)
        .map(|c| c as i64)
}

pub async fn fetch_authors_page(
    limit: i32,
    offset: i32,
) -> Result<Vec<AuthorIdentity>, HentaiError> {
    let db = connection()?;
    let rows = Authors::find()
        .order_by_asc(authors::Column::Name)
        .limit(limit as u64)
        .offset(offset as u64)
        .all(&db)
        .await
        .map_err(map_db_err)?;
    let verified_ids = verified_author_ids(&db).await?;
    Ok(rows
        .into_iter()
        .map(|r| AuthorIdentity {
            id: r.id,
            name: r.name,
            verified: verified_ids.contains(&r.id),
        })
        .collect())
}

pub async fn add_author(name: &str) -> Result<AuthorIdentity, HentaiError> {
    let trimmed = validate_author_name(name)?;
    let db = connection()?;
    let id = ensure_author_id(&db, &trimmed).await?;
    Ok(AuthorIdentity {
        id,
        name: trimmed,
        verified: false,
    })
}

pub async fn delete_authors_by_names(names: Vec<String>) -> Result<(), HentaiError> {
    if names.is_empty() {
        return Ok(());
    }
    let db = connection()?;
    let ids = author_ids_for_names(&db, &names).await?;
    delete_authors_by_ids(&db, &ids).await
}

pub async fn delete_authors_by_ids<C: ConnectionTrait>(
    db: &C,
    ids: &[i64],
) -> Result<(), HentaiError> {
    if ids.is_empty() {
        return Ok(());
    }
    let placeholders = std::iter::repeat_n("?", ids.len())
        .collect::<Vec<_>>()
        .join(", ");
    let values: Vec<Value> = ids.iter().copied().map(Value::from).collect();
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM author_links WHERE author_id IN ({placeholders})"),
        values.clone(),
    ))
    .await
    .map_err(map_db_err)?;
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM comic_authors WHERE author_id IN ({placeholders})"),
        values.clone(),
    ))
    .await
    .map_err(map_db_err)?;
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM authors WHERE id IN ({placeholders})"),
        values,
    ))
    .await
    .map_err(map_db_err)?;
    Ok(())
}

pub async fn rename_author(old_name: &str, new_name: &str) -> Result<(), HentaiError> {
    let new_name = validate_author_name(new_name)?;
    let db = connection()?;
    let Some(id) = find_author_id_by_name(&db, old_name).await? else {
        return Err(HentaiError::validation(format!("作者不存在: {old_name}")));
    };
    rename_author_by_id(&db, id, &new_name).await
}

pub async fn rename_author_by_id<C: ConnectionTrait>(
    db: &C,
    author_id: i64,
    new_name: &str,
) -> Result<(), HentaiError> {
    let new_name = validate_author_name(new_name)?;
    let existing = find_author_id_by_name(db, &new_name).await?;
    if let Some(existing) = existing {
        if existing != author_id {
            return Err(HentaiError::validation(format!(
                "作者显示名已存在: {new_name}"
            )));
        }
    }
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "UPDATE authors SET name = ? WHERE id = ?",
        [Value::from(new_name), Value::from(author_id)],
    ))
    .await
    .map_err(map_db_err)?;
    Ok(())
}

pub async fn watch_authors(
    mut emit: impl FnMut(Vec<AuthorIdentity>) -> Result<(), HentaiError>,
) -> Result<(), HentaiError> {
    let mut changes = crate::revision::subscribe();
    emit(list_all_authors().await?)?;
    while changes.changed().await.is_ok() {
        emit(list_all_authors().await?)?;
    }
    Ok(())
}

pub async fn replace_comic_authors<C: ConnectionTrait>(
    db: &C,
    comic_id: &str,
    author_names: &[String],
) -> Result<(), HentaiError> {
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM comic_authors WHERE comic_id = ?",
        [Value::from(comic_id.to_string())],
    ))
    .await
    .map_err(map_db_err)?;

    let unique: HashSet<&String> = author_names.iter().filter(|n| !n.is_empty()).collect();
    for name in unique {
        let id = ensure_author_id(db, name).await?;
        db.execute(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "INSERT INTO comic_authors (comic_id, author_id) VALUES (?, ?)",
            [Value::from(comic_id.to_string()), Value::from(id)],
        ))
        .await
        .map_err(map_db_err)?;
    }
    Ok(())
}

pub async fn load_author_names_for_comics<C: ConnectionTrait>(
    db: &C,
    comic_ids: &[String],
) -> Result<std::collections::HashMap<String, Vec<String>>, HentaiError> {
    let mut map = std::collections::HashMap::new();
    if comic_ids.is_empty() {
        return Ok(map);
    }
    let placeholders = std::iter::repeat_n("?", comic_ids.len())
        .collect::<Vec<_>>()
        .join(",");
    let values: Vec<Value> = comic_ids.iter().map(|id| Value::from(id.clone())).collect();
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "SELECT ca.comic_id, a.name \
                 FROM comic_authors ca \
                 INNER JOIN authors a ON a.id = ca.author_id \
                 WHERE ca.comic_id IN ({placeholders}) \
                 ORDER BY a.name ASC"
            ),
            values,
        ))
        .await
        .map_err(map_db_err)?;
    for row in rows {
        let comic_id = row
            .try_get_by_index::<String>(0)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
        let name = row
            .try_get_by_index::<String>(1)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
        map.entry(comic_id).or_default().push(name);
    }
    Ok(map)
}

pub async fn list_author_links(author_id: i64) -> Result<Vec<AuthorLinkDto>, HentaiError> {
    let db = connection()?;
    list_author_links_on(&db, author_id).await
}

async fn list_author_links_on<C: ConnectionTrait>(
    db: &C,
    author_id: i64,
) -> Result<Vec<AuthorLinkDto>, HentaiError> {
    let rows = AuthorLinks::find()
        .filter(author_links::Column::AuthorId.eq(author_id))
        .order_by_asc(author_links::Column::SortKey)
        .order_by_asc(author_links::Column::Id)
        .all(db)
        .await
        .map_err(map_db_err)?;
    rows.into_iter()
        .map(|row| {
            Ok(AuthorLinkDto {
                id: row.id,
                platform: AuthorLinkPlatform::parse(&row.platform)?,
                url: row.url,
                platform_display_name: row.platform_display_name,
                sort_key: row.sort_key,
            })
        })
        .collect()
}

pub async fn add_author_link(
    author_id: i64,
    platform: AuthorLinkPlatform,
    url: &str,
    platform_display_name: Option<String>,
) -> Result<AuthorLinkDto, HentaiError> {
    let url = validate_http_url(url)?;
    let db = connection()?;
    ensure_author_exists(&db, author_id).await?;
    let next_key = next_link_sort_key(&db, author_id).await?;
    let display = normalize_optional_text(platform_display_name);
    let active = author_links::ActiveModel {
        id: Default::default(),
        author_id: Set(author_id),
        platform: Set(platform.as_str().to_string()),
        url: Set(url.clone()),
        platform_display_name: Set(display.clone()),
        sort_key: Set(next_key),
    };
    let inserted = AuthorLinks::insert(active)
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    Ok(AuthorLinkDto {
        id: inserted.last_insert_id,
        platform,
        url,
        platform_display_name: display,
        sort_key: next_key,
    })
}

pub async fn update_author_link(
    link_id: i64,
    platform: AuthorLinkPlatform,
    url: &str,
    platform_display_name: Option<String>,
) -> Result<(), HentaiError> {
    let url = validate_http_url(url)?;
    let db = connection()?;
    let display = normalize_optional_text(platform_display_name);
    let result = db
        .execute(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "UPDATE author_links SET platform = ?, url = ?, platform_display_name = ? WHERE id = ?",
            [
                Value::from(platform.as_str().to_string()),
                Value::from(url),
                match display {
                    Some(text) => Value::from(text),
                    None => Value::String(None),
                },
                Value::from(link_id),
            ],
        ))
        .await
        .map_err(map_db_err)?;
    if result.rows_affected() == 0 {
        return Err(HentaiError::validation("Author link 不存在"));
    }
    Ok(())
}

pub async fn delete_author_link(link_id: i64) -> Result<(), HentaiError> {
    let db = connection()?;
    AuthorLinks::delete_by_id(link_id)
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    Ok(())
}

pub async fn merge_author_links_by_name(
    db: &impl ConnectionTrait,
    author_name: &str,
    links: &[(AuthorLinkPlatform, String, Option<String>)],
) -> Result<(), HentaiError> {
    let author_id = ensure_author_id(db, author_name).await?;
    let existing = list_author_links_on(db, author_id).await?;
    let mut next_key = existing.iter().map(|l| l.sort_key).max().unwrap_or(-1) + 1;
    for (platform, url, display) in links {
        let url = validate_http_url(url)?;
        let already = existing
            .iter()
            .any(|l| l.platform == *platform && l.url == url);
        if already {
            continue;
        }
        let display = normalize_optional_text(display.clone());
        db.execute(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "INSERT INTO author_links (author_id, platform, url, platform_display_name, sort_key) \
             VALUES (?, ?, ?, ?, ?)",
            [
                Value::from(author_id),
                Value::from(platform.as_str().to_string()),
                Value::from(url),
                match display {
                    Some(text) => Value::from(text),
                    None => Value::String(None),
                },
                Value::from(next_key),
            ],
        ))
        .await
        .map_err(map_db_err)?;
        next_key += 1;
    }
    Ok(())
}

pub async fn list_all_author_links_for_export(
    db: &impl ConnectionTrait,
) -> Result<Vec<(String, AuthorLinkDto)>, HentaiError> {
    let rows = db
        .query_all(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT a.name, l.id, l.platform, l.url, l.platform_display_name, l.sort_key \
             FROM author_links l \
             INNER JOIN authors a ON a.id = l.author_id \
             ORDER BY a.name ASC, l.sort_key ASC, l.id ASC"
                .to_string(),
        ))
        .await
        .map_err(map_db_err)?;
    let mut out = Vec::new();
    for row in rows {
        let name = row
            .try_get_by_index::<String>(0)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
        let id = row
            .try_get_by_index::<i64>(1)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
        let platform = row
            .try_get_by_index::<String>(2)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
        let url = row
            .try_get_by_index::<String>(3)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
        let display = row.try_get_by_index::<Option<String>>(4).unwrap_or(None);
        let sort_key = row
            .try_get_by_index::<i64>(5)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
        out.push((
            name,
            AuthorLinkDto {
                id,
                platform: AuthorLinkPlatform::parse(&platform)?,
                url,
                platform_display_name: display,
                sort_key,
            },
        ));
    }
    Ok(out)
}

pub async fn get_author_detail(
    author_id: i64,
    show_r18: bool,
) -> Result<Option<AuthorDetailDto>, HentaiError> {
    let db = connection()?;
    let Some(row) = Authors::find_by_id(author_id)
        .one(&db)
        .await
        .map_err(map_db_err)?
    else {
        return Ok(None);
    };
    let links = list_author_links_on(&db, author_id).await?;
    let verified = links.iter().any(|l| l.platform.is_creative());
    let healthy = healthy_visible_sql("c", "m", show_r18);
    Ok(Some(AuthorDetailDto {
        identity: AuthorIdentity {
            id: row.id,
            name: row.name,
            verified,
        },
        links,
        tags: facet_counts_for_author(&db, author_id, "comic_tags", "tag_name", &healthy).await?,
        parodies: facet_counts_for_author(
            &db,
            author_id,
            "comic_parodies",
            "parody_name",
            &healthy,
        )
        .await?,
        characters: facet_counts_for_author(
            &db,
            author_id,
            "comic_characters",
            "character_name",
            &healthy,
        )
        .await?,
        top_comics: top_comics_for_author(&db, author_id, &healthy).await?,
    }))
}

pub async fn resolve_author_image(
    author_id: i64,
    show_r18: bool,
) -> Result<AuthorImageRef, HentaiError> {
    let db = connection()?;
    let healthy = healthy_visible_sql("c", "m", show_r18);
    let top = top_comics_for_author(&db, author_id, &healthy).await?;
    let comic_id = top.first().map(|c| c.comic_id.clone());
    match comic_id {
        Some(id) => Ok(AuthorImageRef {
            avatar_source: AuthorImageSource::ComicCover,
            avatar_comic_id: Some(id.clone()),
            background_source: AuthorImageSource::ComicCover,
            background_comic_id: Some(id),
        }),
        None => Ok(AuthorImageRef {
            avatar_source: AuthorImageSource::None,
            avatar_comic_id: None,
            background_source: AuthorImageSource::None,
            background_comic_id: None,
        }),
    }
}

pub async fn ensure_author_id<C: ConnectionTrait>(db: &C, name: &str) -> Result<i64, HentaiError> {
    let name = validate_author_name(name)?;
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT OR IGNORE INTO authors (name) VALUES (?)",
        [Value::from(name.clone())],
    ))
    .await
    .map_err(map_db_err)?;
    find_author_id_by_name(db, &name)
        .await?
        .ok_or_else(|| HentaiError::db_query_failed("author id missing after upsert", None))
}

pub async fn find_author_id_by_name<C: ConnectionTrait>(
    db: &C,
    name: &str,
) -> Result<Option<i64>, HentaiError> {
    let row = db
        .query_one(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT id FROM authors WHERE name = ?",
            [Value::from(name.to_string())],
        ))
        .await
        .map_err(map_db_err)?;
    match row {
        Some(row) => row
            .try_get_by_index::<i64>(0)
            .map(Some)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None)),
        None => Ok(None),
    }
}

fn validate_author_name(name: &str) -> Result<String, HentaiError> {
    let trimmed = name.trim().to_string();
    if trimmed.is_empty() {
        return Err(HentaiError::validation("作者显示名不能为空"));
    }
    Ok(trimmed)
}

fn validate_http_url(url: &str) -> Result<String, HentaiError> {
    let trimmed = url.trim().to_string();
    if trimmed.is_empty() {
        return Err(HentaiError::validation("链接不能为空"));
    }
    let lower = trimmed.to_ascii_lowercase();
    if !(lower.starts_with("http://") || lower.starts_with("https://")) {
        return Err(HentaiError::validation(
            "链接必须以 http:// 或 https:// 开头",
        ));
    }
    Ok(trimmed)
}

fn normalize_optional_text(value: Option<String>) -> Option<String> {
    value.and_then(|s| {
        let t = s.trim();
        if t.is_empty() {
            None
        } else {
            Some(t.to_string())
        }
    })
}

async fn ensure_author_exists<C: ConnectionTrait>(
    db: &C,
    author_id: i64,
) -> Result<(), HentaiError> {
    let exists = Authors::find_by_id(author_id)
        .one(db)
        .await
        .map_err(map_db_err)?;
    if exists.is_none() {
        return Err(HentaiError::validation("作者不存在"));
    }
    Ok(())
}

async fn next_link_sort_key<C: ConnectionTrait>(
    db: &C,
    author_id: i64,
) -> Result<i64, HentaiError> {
    let row = db
        .query_one(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT COALESCE(MAX(sort_key), -1) FROM author_links WHERE author_id = ?",
            [Value::from(author_id)],
        ))
        .await
        .map_err(map_db_err)?;
    let max = row
        .and_then(|r| r.try_get_by_index::<i64>(0).ok())
        .unwrap_or(-1);
    Ok(max + 1)
}

async fn verified_author_ids<C: ConnectionTrait>(db: &C) -> Result<HashSet<i64>, HentaiError> {
    let rows = db
        .query_all(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT DISTINCT author_id FROM author_links WHERE platform != 'other'".to_string(),
        ))
        .await
        .map_err(map_db_err)?;
    let mut set = HashSet::new();
    for row in rows {
        set.insert(
            row.try_get_by_index::<i64>(0)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
        );
    }
    Ok(set)
}

async fn author_ids_for_names<C: ConnectionTrait>(
    db: &C,
    names: &[String],
) -> Result<Vec<i64>, HentaiError> {
    let mut ids = Vec::new();
    for name in names {
        if let Some(id) = find_author_id_by_name(db, name).await? {
            ids.push(id);
        }
    }
    Ok(ids)
}

fn healthy_visible_sql(comic_alias: &str, meta_alias: &str, show_r18: bool) -> String {
    let visible = visible_comic_sql(comic_alias);
    if show_r18 {
        visible
    } else {
        format!("{visible} AND {meta_alias}.content_rating != 'r18'")
    }
}

async fn facet_counts_for_author<C: ConnectionTrait>(
    db: &C,
    author_id: i64,
    junction: &str,
    name_col: &str,
    healthy: &str,
) -> Result<Vec<AuthorFacetCountDto>, HentaiError> {
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "SELECT j.{name_col} AS name, COUNT(*) AS n \
                 FROM comic_authors ca \
                 INNER JOIN comics c ON c.comic_id = ca.comic_id \
                 INNER JOIN comic_meta m ON m.comic_id = c.comic_id \
                 INNER JOIN {junction} j ON j.comic_id = c.comic_id \
                 WHERE ca.author_id = ? AND {healthy} \
                 GROUP BY j.{name_col} \
                 ORDER BY n DESC, j.{name_col} ASC"
            ),
            [Value::from(author_id)],
        ))
        .await
        .map_err(map_db_err)?;
    rows.into_iter()
        .map(|row| {
            Ok(AuthorFacetCountDto {
                name: row
                    .try_get_by_index::<String>(0)
                    .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
                attachment_count: row
                    .try_get_by_index::<i64>(1)
                    .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
            })
        })
        .collect()
}

async fn top_comics_for_author<C: ConnectionTrait>(
    db: &C,
    author_id: i64,
    healthy: &str,
) -> Result<Vec<AuthorTopComicDto>, HentaiError> {
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!(
                "SELECT c.comic_id, m.title \
                 FROM comic_authors ca \
                 INNER JOIN comics c ON c.comic_id = ca.comic_id \
                 INNER JOIN comic_meta m ON m.comic_id = c.comic_id \
                 WHERE ca.author_id = ? AND {healthy} \
                 ORDER BY m.title_sort_key ASC, c.comic_id ASC \
                 LIMIT 5"
            ),
            [Value::from(author_id)],
        ))
        .await
        .map_err(map_db_err)?;
    rows.into_iter()
        .map(|row| {
            Ok(AuthorTopComicDto {
                comic_id: row
                    .try_get_by_index::<String>(0)
                    .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
                title: row
                    .try_get_by_index::<String>(1)
                    .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?,
            })
        })
        .collect()
}

pub fn author_attachment_count_sql() -> String {
    format!(
        "SELECT COUNT(*) FROM comic_authors j WHERE j.author_id = \
         (SELECT id FROM authors WHERE name = ?) AND {}",
        visible_comic_id_sql("j.comic_id")
    )
}
