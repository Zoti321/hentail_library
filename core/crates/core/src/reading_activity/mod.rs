//! Reading activity stats: Finished comic marks + Reading duration total.

use sea_orm::{ConnectionTrait, DatabaseConnection, Statement};

use crate::comic::visibility::comic_id_not_trashed_sql;
use crate::db::{connection, map_db_err};
use crate::error::HentaiError;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ReadingActivityStatsDto {
    pub finished_count: i32,
    pub total_duration_ms: i64,
}

pub async fn load_reading_activity_stats(
    db: &DatabaseConnection,
) -> Result<ReadingActivityStatsDto, HentaiError> {
    let finished_sql = format!(
        "SELECT COUNT(*) AS finished_count FROM comic_finished_marks m \
         WHERE {}",
        comic_id_not_trashed_sql("m.comic_id")
    );
    let finished_row = db
        .query_one(Statement::from_string(
            db.get_database_backend(),
            finished_sql,
        ))
        .await
        .map_err(map_db_err)?;
    let finished_count = finished_row
        .map(|row| row.try_get::<i64>("", "finished_count").unwrap_or(0) as i32)
        .unwrap_or(0);

    let duration_row = db
        .query_one(Statement::from_string(
            db.get_database_backend(),
            "SELECT total_ms FROM reading_duration_total WHERE id = 1".to_string(),
        ))
        .await
        .map_err(map_db_err)?;
    let total_duration_ms = duration_row
        .map(|row| row.try_get::<i64>("", "total_ms").unwrap_or(0))
        .unwrap_or(0);

    Ok(ReadingActivityStatsDto {
        finished_count,
        total_duration_ms,
    })
}

pub async fn watch_reading_activity_stats(
    mut emit: impl FnMut(ReadingActivityStatsDto) -> Result<(), HentaiError>,
) -> Result<(), HentaiError> {
    let db = connection()?;
    let mut changes = crate::revision::subscribe();
    emit(load_reading_activity_stats(&db).await?)?;
    while changes.changed().await.is_ok() {
        emit(load_reading_activity_stats(&db).await?)?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use sea_orm::{Database, DbBackend};

    #[tokio::test]
    async fn empty_tables_yield_zero_snapshot() {
        let db = Database::connect("sqlite::memory:")
            .await
            .expect("memory db");
        assert_eq!(db.get_database_backend(), DbBackend::Sqlite);
        db.execute_unprepared(
            "CREATE TABLE comic_finished_marks (
                comic_id TEXT NOT NULL PRIMARY KEY,
                finished_at_ms INTEGER NOT NULL
            )",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "CREATE TABLE reading_duration_total (
                id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
                total_ms INTEGER NOT NULL CHECK (total_ms >= 0),
                updated_at_ms INTEGER NOT NULL
            )",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "INSERT INTO reading_duration_total (id, total_ms, updated_at_ms) VALUES (1, 0, 0)",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "CREATE TABLE comics (
                comic_id TEXT PRIMARY KEY,
                deleted_at INTEGER
            )",
        )
        .await
        .unwrap();

        let snap = load_reading_activity_stats(&db).await.unwrap();
        assert_eq!(snap.finished_count, 0);
        assert_eq!(snap.total_duration_ms, 0);
    }

    #[tokio::test]
    async fn finished_count_excludes_trashed_comics() {
        let db = Database::connect("sqlite::memory:")
            .await
            .expect("memory db");
        db.execute_unprepared(
            "CREATE TABLE comics (
                comic_id TEXT PRIMARY KEY,
                deleted_at INTEGER
            )",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "CREATE TABLE comic_finished_marks (
                comic_id TEXT NOT NULL PRIMARY KEY,
                finished_at_ms INTEGER NOT NULL
            )",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "CREATE TABLE reading_duration_total (
                id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
                total_ms INTEGER NOT NULL CHECK (total_ms >= 0),
                updated_at_ms INTEGER NOT NULL
            )",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "INSERT INTO reading_duration_total (id, total_ms, updated_at_ms) VALUES (1, 60000, 1)",
        )
        .await
        .unwrap();
        db.execute_unprepared("INSERT INTO comics (comic_id, deleted_at) VALUES ('a', NULL)")
            .await
            .unwrap();
        db.execute_unprepared("INSERT INTO comics (comic_id, deleted_at) VALUES ('b', 1)")
            .await
            .unwrap();
        db.execute_unprepared(
            "INSERT INTO comic_finished_marks (comic_id, finished_at_ms) VALUES ('a', 1), ('b', 2)",
        )
        .await
        .unwrap();

        let snap = load_reading_activity_stats(&db).await.unwrap();
        assert_eq!(snap.finished_count, 1);
        assert_eq!(snap.total_duration_ms, 60000);
    }
}
