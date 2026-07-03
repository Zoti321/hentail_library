use sea_orm::{ConnectionTrait, DatabaseConnection, Statement, Value};

use crate::db::{connection, map_db_err};
use crate::error::HentaiError;

#[derive(Debug, Clone, Default)]
pub struct HomePageCountsDto {
    pub comic_count: i32,
    pub tag_count: i32,
    pub series_count: i32,
    pub reading_record_count: i32,
}

const SQL_COUNTS: &str = r#"
SELECT
  (SELECT COUNT(*) FROM comics) AS c_comic,
  (SELECT COUNT(*) FROM tags) AS c_tag,
  (SELECT COUNT(*) FROM series) AS c_series,
  (SELECT COUNT(*) FROM comic_reading_histories) AS c_comic_h,
  (SELECT COUNT(*) FROM series_reading_histories) AS c_series_h
"#;

const SQL_COUNTS_HEALTHY: &str = r#"
SELECT
  (SELECT COUNT(*) FROM comics WHERE content_rating != ?) AS c_comic,
  (SELECT COUNT(*) FROM tags) AS c_tag,
  (
    SELECT COUNT(*)
    FROM series s
    WHERE EXISTS (SELECT 1 FROM series_items si0 WHERE si0.series_name = s.name)
    AND NOT EXISTS (
      SELECT 1
      FROM series_items si1
      INNER JOIN comics c1 ON c1.comic_id = si1.comic_id
      WHERE si1.series_name = s.name AND c1.content_rating = ?
    )
  ) AS c_series,
  (
    SELECT COUNT(*)
    FROM comic_reading_histories h
    INNER JOIN comics c ON c.comic_id = h.comic_id
    WHERE c.content_rating != ?
  ) AS c_comic_h,
  (
    SELECT COUNT(*)
    FROM series_reading_histories srh
    WHERE NOT EXISTS (
      SELECT 1
      FROM series_items si2
      INNER JOIN comics c2 ON c2.comic_id = si2.comic_id
      WHERE si2.series_name = srh.series_name AND c2.content_rating = ?
    )
  ) AS c_series_h
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

async fn load_counts(db: &DatabaseConnection, exclude_r18: bool) -> Result<HomePageCountsDto, HentaiError> {
    let row = if exclude_r18 {
        let stmt = Statement::from_sql_and_values(
            db.get_database_backend(),
            SQL_COUNTS_HEALTHY,
            vec![Value::from("r18"); 4],
        );
        db.query_one(stmt).await.map_err(map_db_err)?
    } else {
        let stmt = Statement::from_sql_and_values(db.get_database_backend(), SQL_COUNTS, []);
        db.query_one(stmt).await.map_err(map_db_err)?
    };
    let Some(row) = row else {
        return Ok(HomePageCountsDto::default());
    };
    let comic_h: i64 = row.try_get("", "c_comic_h").unwrap_or(0);
    let series_h: i64 = row.try_get("", "c_series_h").unwrap_or(0);
    Ok(HomePageCountsDto {
        comic_count: row.try_get::<i32>("", "c_comic").unwrap_or(0),
        tag_count: row.try_get::<i32>("", "c_tag").unwrap_or(0),
        series_count: row.try_get::<i32>("", "c_series").unwrap_or(0),
        reading_record_count: (comic_h + series_h) as i32,
    })
}
