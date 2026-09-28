use sea_orm::{ConnectionTrait, DatabaseConnection, EntityTrait, Statement, Value};

use crate::comic::now_ms;
use crate::db::{connection, map_db_err};
use crate::error::HentaiError;
use crate::library::ScanInterval;

#[derive(Debug, Clone, Default)]
pub struct HomePageCountsDto {
    pub comic_count: i32,
    pub tag_count: i32,
    pub series_count: i32,
    pub author_count: i32,
    pub library_count: i32,
}

#[derive(Debug, Clone)]
pub struct HomeContinueReadingDto {
    pub comic_id: String,
    pub title: String,
    pub last_read_time_ms: i64,
    pub page_index: Option<i32>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum HomeLibraryAlertKindDto {
    RemoteUnreachable,
    SyncFailed,
    StaleSync,
}

#[derive(Debug, Clone)]
pub struct HomeLibraryAlertDto {
    pub library_id: String,
    pub display_name: String,
    pub kind: HomeLibraryAlertKindDto,
    pub last_success_at_ms: Option<i64>,
    pub last_error_message: Option<String>,
    pub stale_days: Option<i32>,
}

#[derive(Debug, Clone)]
pub struct HomeRecentlyAddedDto {
    pub comic_id: String,
    pub title: String,
    pub library_id: String,
    pub library_display_name: String,
    pub created_at_ms: i64,
}

const SQL_COUNTS: &str = r#"
SELECT
  (SELECT COUNT(*) FROM comics) AS c_comic,
  (SELECT COUNT(*) FROM tags) AS c_tag,
  (SELECT COUNT(*) FROM series) AS c_series,
  (SELECT COUNT(*) FROM authors) AS c_author,
  (SELECT COUNT(*) FROM libraries) AS c_library
"#;

const SQL_COUNTS_HEALTHY: &str = r#"
SELECT
  (SELECT COUNT(*) FROM comics c INNER JOIN comic_meta cm ON cm.comic_id = c.comic_id
     WHERE cm.content_rating != ?) AS c_comic,
  (SELECT COUNT(*) FROM tags) AS c_tag,
  (
    SELECT COUNT(*)
    FROM series s
    WHERE EXISTS (SELECT 1 FROM series_items si0 WHERE si0.series_id = s.series_id)
    AND NOT EXISTS (
      SELECT 1
      FROM series_items si1
      INNER JOIN comic_meta cm1 ON cm1.comic_id = si1.comic_id
      WHERE si1.series_id = s.series_id AND cm1.content_rating = ?
    )
  ) AS c_series,
  (SELECT COUNT(*) FROM authors) AS c_author,
  (SELECT COUNT(*) FROM libraries) AS c_library
"#;

const SQL_TOP5: &str = r#"
SELECT h.last_read_time, h.comic_id, h.title, h.page_index
FROM comic_reading_histories h
ORDER BY h.last_read_time DESC
LIMIT 5
"#;

const SQL_TOP5_HEALTHY: &str = r#"
SELECT h.last_read_time, h.comic_id, h.title, h.page_index
FROM comic_reading_histories h
INNER JOIN comic_meta cm ON cm.comic_id = h.comic_id
WHERE cm.content_rating != ?
ORDER BY h.last_read_time DESC
LIMIT 5
"#;

const SQL_RECENTLY_ADDED: &str = r#"
SELECT c.comic_id, cm.title, c.library_id, l.name AS library_name, c.created_at
FROM comics c
INNER JOIN comic_meta cm ON cm.comic_id = c.comic_id
INNER JOIN libraries l ON l.library_id = c.library_id
ORDER BY c.created_at DESC
LIMIT 8
"#;

const SQL_RECENTLY_ADDED_HEALTHY: &str = r#"
SELECT c.comic_id, cm.title, c.library_id, l.name AS library_name, c.created_at
FROM comics c
INNER JOIN comic_meta cm ON cm.comic_id = c.comic_id
INNER JOIN libraries l ON l.library_id = c.library_id
WHERE cm.content_rating != ?
ORDER BY c.created_at DESC
LIMIT 8
"#;

pub async fn watch_home_page_counts(
    exclude_r18: bool,
    mut emit: impl FnMut(HomePageCountsDto) -> Result<(), HentaiError>,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let mut changes = crate::revision::subscribe();
    emit(load_counts(&db, exclude_r18).await?)?;
    while changes.changed().await.is_ok() {
        emit(load_counts(&db, exclude_r18).await?)?;
    }
    Ok(())
}

pub async fn watch_continue_reading_top5(
    exclude_r18: bool,
    mut emit: impl FnMut(Vec<HomeContinueReadingDto>) -> Result<(), HentaiError>,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let mut changes = crate::revision::subscribe();
    emit(load_continue_reading(&db, exclude_r18).await?)?;
    while changes.changed().await.is_ok() {
        emit(load_continue_reading(&db, exclude_r18).await?)?;
    }
    Ok(())
}

pub async fn watch_recently_added_on_home(
    exclude_r18: bool,
    mut emit: impl FnMut(Vec<HomeRecentlyAddedDto>) -> Result<(), HentaiError>,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let mut changes = crate::revision::subscribe();
    emit(load_recently_added(&db, exclude_r18).await?)?;
    while changes.changed().await.is_ok() {
        emit(load_recently_added(&db, exclude_r18).await?)?;
    }
    Ok(())
}

pub async fn watch_home_library_alerts(
    mut emit: impl FnMut(Vec<HomeLibraryAlertDto>) -> Result<(), HentaiError>,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let mut changes = crate::revision::subscribe();
    emit(load_home_library_alerts(&db).await?)?;
    while changes.changed().await.is_ok() {
        emit(load_home_library_alerts(&db).await?)?;
    }
    Ok(())
}

async fn load_continue_reading(
    db: &DatabaseConnection,
    exclude_r18: bool,
) -> Result<Vec<HomeContinueReadingDto>, HentaiError> {
    let rows = if exclude_r18 {
        let stmt = Statement::from_sql_and_values(
            db.get_database_backend(),
            SQL_TOP5_HEALTHY,
            vec![Value::from("r18")],
        );
        db.query_all(stmt).await.map_err(map_db_err)?
    } else {
        let stmt = Statement::from_sql_and_values(db.get_database_backend(), SQL_TOP5, []);
        db.query_all(stmt).await.map_err(map_db_err)?
    };
    rows.into_iter()
        .map(|row| {
            Ok(HomeContinueReadingDto {
                last_read_time_ms: row.try_get("", "last_read_time").unwrap_or(0),
                comic_id: row.try_get("", "comic_id").unwrap_or_default(),
                title: row.try_get("", "title").unwrap_or_default(),
                page_index: row.try_get("", "page_index").ok(),
            })
        })
        .collect()
}

async fn load_recently_added(
    db: &DatabaseConnection,
    exclude_r18: bool,
) -> Result<Vec<HomeRecentlyAddedDto>, HentaiError> {
    let rows = if exclude_r18 {
        let stmt = Statement::from_sql_and_values(
            db.get_database_backend(),
            SQL_RECENTLY_ADDED_HEALTHY,
            vec![Value::from("r18")],
        );
        db.query_all(stmt).await.map_err(map_db_err)?
    } else {
        let stmt =
            Statement::from_sql_and_values(db.get_database_backend(), SQL_RECENTLY_ADDED, []);
        db.query_all(stmt).await.map_err(map_db_err)?
    };
    rows.into_iter()
        .map(|row| {
            Ok(HomeRecentlyAddedDto {
                comic_id: row.try_get("", "comic_id").unwrap_or_default(),
                title: row.try_get("", "title").unwrap_or_default(),
                library_id: row.try_get("", "library_id").unwrap_or_default(),
                library_display_name: row.try_get("", "library_name").unwrap_or_default(),
                created_at_ms: row.try_get("", "created_at").unwrap_or(0),
            })
        })
        .collect()
}

async fn load_counts(
    db: &DatabaseConnection,
    exclude_r18: bool,
) -> Result<HomePageCountsDto, HentaiError> {
    let row = if exclude_r18 {
        let stmt = Statement::from_sql_and_values(
            db.get_database_backend(),
            SQL_COUNTS_HEALTHY,
            vec![Value::from("r18"), Value::from("r18")],
        );
        db.query_one(stmt).await.map_err(map_db_err)?
    } else {
        let stmt = Statement::from_sql_and_values(db.get_database_backend(), SQL_COUNTS, []);
        db.query_one(stmt).await.map_err(map_db_err)?
    };
    let Some(row) = row else {
        return Ok(HomePageCountsDto::default());
    };
    Ok(HomePageCountsDto {
        comic_count: row.try_get::<i32>("", "c_comic").unwrap_or(0),
        tag_count: row.try_get::<i32>("", "c_tag").unwrap_or(0),
        series_count: row.try_get::<i32>("", "c_series").unwrap_or(0),
        author_count: row.try_get::<i32>("", "c_author").unwrap_or(0),
        library_count: row.try_get::<i32>("", "c_library").unwrap_or(0),
    })
}

async fn load_home_library_alerts(
    db: &DatabaseConnection,
) -> Result<Vec<HomeLibraryAlertDto>, HentaiError> {
    let models = crate::entity::prelude::Libraries::find()
        .all(db)
        .await
        .map_err(map_db_err)?;
    let now = now_ms();
    let mut alerts = Vec::new();
    for model in models {
        if let Some(kind) = classify_sync_alert(&model, now, db).await? {
            alerts.push(HomeLibraryAlertDto {
                library_id: model.library_id.clone(),
                display_name: model.name.clone(),
                kind,
                last_success_at_ms: model.last_successful_sync_at,
                last_error_message: model.last_sync_error.clone(),
                stale_days: stale_days_for(&model, now),
            });
        }
    }
    Ok(alerts)
}

async fn classify_sync_alert(
    model: &crate::entity::libraries::Model,
    now_ms: i64,
    db: &DatabaseConnection,
) -> Result<Option<HomeLibraryAlertKindDto>, HentaiError> {
    if let Some(error) = model.last_sync_error.as_deref().filter(|s| !s.is_empty()) {
        return Ok(Some(if is_remote_unreachable_message(error) {
            HomeLibraryAlertKindDto::RemoteUnreachable
        } else {
            HomeLibraryAlertKindDto::SyncFailed
        }));
    }
    if is_stale_sync(model, now_ms, db).await? {
        return Ok(Some(HomeLibraryAlertKindDto::StaleSync));
    }
    Ok(None)
}

fn is_remote_unreachable_message(message: &str) -> bool {
    let lower = message.to_ascii_lowercase();
    lower.contains("不可达")
        || lower.contains("不可读")
        || lower.contains("凭证")
        || lower.contains("认证")
        || lower.contains("连接")
        || lower.contains("401")
        || lower.contains("403")
        || lower.contains("unreachable")
        || lower.contains("auth")
}

async fn is_stale_sync(
    model: &crate::entity::libraries::Model,
    now_ms: i64,
    db: &DatabaseConnection,
) -> Result<bool, HentaiError> {
    let scan_interval =
        crate::library::parse_scan_interval(&model.scan_interval).unwrap_or(ScanInterval::Disabled);
    let Some(threshold_ms) = scan_interval.staleness_threshold_ms() else {
        return Ok(false);
    };
    if let Some(last_success) = model.last_successful_sync_at {
        return Ok(now_ms.saturating_sub(last_success) > threshold_ms);
    }
    let comic_count = count_comics_for_library(db, &model.library_id).await?;
    Ok(comic_count > 0)
}

fn stale_days_for(model: &crate::entity::libraries::Model, now_ms: i64) -> Option<i32> {
    let last = model.last_successful_sync_at?;
    let days = ((now_ms - last).max(0) as f64 / (24.0 * 60.0 * 60.0 * 1000.0)).floor() as i32;
    Some(days.max(1))
}

async fn count_comics_for_library(
    db: &DatabaseConnection,
    library_id: &str,
) -> Result<i32, HentaiError> {
    let row = db
        .query_one(Statement::from_sql_and_values(
            db.get_database_backend(),
            "SELECT COUNT(*) AS c FROM comics WHERE library_id = ?",
            vec![Value::from(library_id)],
        ))
        .await
        .map_err(map_db_err)?;
    Ok(row
        .and_then(|r| r.try_get::<i32>("", "c").ok())
        .unwrap_or(0))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn library_model(
        last_sync_error: Option<&str>,
        last_successful_sync_at: Option<i64>,
        scan_interval: &str,
    ) -> crate::entity::libraries::Model {
        crate::entity::libraries::Model {
            library_id: "lib-1".to_string(),
            name: "Test".to_string(),
            kind: "local".to_string(),
            root_path: "/tmp/lib".to_string(),
            username: String::new(),
            allow_http: 0,
            scan_on_startup: 0,
            scan_interval: scan_interval.to_string(),
            enabled_format_groups: "[]".to_string(),
            created_at: 0,
            pinned: 0,
            sidebar_order: 0,
            last_successful_sync_at,
            last_sync_error: last_sync_error.map(str::to_string),
        }
    }

    #[test]
    fn remote_unreachable_classified_from_error_message() {
        let model = library_model(Some("远程库不可达: timeout"), None, "disabled");
        assert!(is_remote_unreachable_message(
            model.last_sync_error.as_deref().unwrap()
        ));
    }

    #[test]
    fn sync_failed_when_error_not_unreachable() {
        let model = library_model(Some("解析 CBZ 失败"), None, "disabled");
        let error = model.last_sync_error.as_deref().unwrap();
        assert!(!is_remote_unreachable_message(error));
    }

    #[test]
    fn stale_days_at_least_one() {
        let model = library_model(None, Some(0), "weekly");
        let days = stale_days_for(&model, 3 * 24 * 60 * 60 * 1000).unwrap();
        assert!(days >= 1);
    }
}
