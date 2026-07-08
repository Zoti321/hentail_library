use sea_orm::{ConnectionTrait, DatabaseConnection, Statement, Value};

use crate::comic::read_data_version;
use crate::db::{connection, map_db_err};
use crate::error::HentaiError;

#[derive(Debug, Clone, Default)]
pub struct HomePageCountsDto {
    pub comic_count: i32,
    pub tag_count: i32,
    pub series_count: i32,
    pub author_count: i32,
}

#[derive(Debug, Clone)]
pub struct HomeContinueReadingDto {
    pub comic_id: String,
    pub title: String,
    pub last_read_time_ms: i64,
    pub page_index: Option<i32>,
}

const SQL_COUNTS: &str = r#"
SELECT
  (SELECT COUNT(*) FROM comics) AS c_comic,
  (SELECT COUNT(*) FROM tags) AS c_tag,
  (SELECT COUNT(*) FROM series) AS c_series,
  (SELECT COUNT(*) FROM authors) AS c_author
"#;

const SQL_COUNTS_HEALTHY: &str = r#"
SELECT
  (SELECT COUNT(*) FROM comics c INNER JOIN comic_meta cm ON cm.comic_id = c.comic_id WHERE cm.content_rating != ?) AS c_comic,
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
  (SELECT COUNT(*) FROM authors) AS c_author
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

pub async fn get_home_page_counts(exclude_r18: bool) -> Result<HomePageCountsDto, HentaiError> {
    let db = connection()?;
    load_counts(&db, exclude_r18).await
}

pub async fn watch_home_page_counts(
    exclude_r18: bool,
    mut emit: impl FnMut(HomePageCountsDto) -> Result<(), HentaiError>,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let mut last = crate::comic::read_data_version().await?;
    emit(load_counts(&db, exclude_r18).await?)?;
    loop {
        tokio::time::sleep(std::time::Duration::from_millis(400)).await;
        let version = crate::comic::read_data_version().await?;
        if version != last {
            last = version;
            emit(load_counts(&db, exclude_r18).await?)?;
        }
    }
}

pub async fn get_continue_reading_top5(
    exclude_r18: bool,
) -> Result<Vec<HomeContinueReadingDto>, HentaiError> {
    let db = connection()?;
    load_continue_reading(&db, exclude_r18).await
}

pub async fn watch_continue_reading_top5(
    exclude_r18: bool,
    mut emit: impl FnMut(Vec<HomeContinueReadingDto>) -> Result<(), HentaiError>,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let mut last = read_data_version().await?;
    emit(load_continue_reading(&db, exclude_r18).await?)?;
    loop {
        tokio::time::sleep(std::time::Duration::from_millis(400)).await;
        let version = read_data_version().await?;
        if version != last {
            last = version;
            emit(load_continue_reading(&db, exclude_r18).await?)?;
        }
    }
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

async fn load_counts(db: &DatabaseConnection, exclude_r18: bool) -> Result<HomePageCountsDto, HentaiError> {
    let row = if exclude_r18 {
        let stmt = Statement::from_sql_and_values(
            db.get_database_backend(),
            SQL_COUNTS_HEALTHY,
            vec![Value::from("r18"); 2],
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
    })
}
