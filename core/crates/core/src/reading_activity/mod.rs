//! Reading activity stats: Finished comic marks + Reading duration total.

use sea_orm::{ConnectionTrait, DatabaseConnection, Statement};

use crate::comic::now_ms;
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

/// Idempotent Finished comic mark（粘性：已存在则保留原 finished_at）。
pub async fn upsert_finished_comic_mark(
    comic_id: &str,
    finished_at_ms: i64,
) -> Result<(), HentaiError> {
    let db = connection()?;
    db.execute(Statement::from_sql_and_values(
        db.get_database_backend(),
        "INSERT INTO comic_finished_marks (comic_id, finished_at_ms) VALUES (?, ?) \
         ON CONFLICT(comic_id) DO NOTHING",
        [comic_id.into(), finished_at_ms.into()],
    ))
    .await
    .map_err(map_db_err)?;
    Ok(())
}

/// 累加终身 Reading duration（只增不减）。
pub async fn add_reading_duration_ms(delta_ms: i64) -> Result<(), HentaiError> {
    if delta_ms <= 0 {
        return Ok(());
    }
    let db = connection()?;
    let updated_at = now_ms();
    db.execute(Statement::from_sql_and_values(
        db.get_database_backend(),
        "UPDATE reading_duration_total \
         SET total_ms = total_ms + ?, updated_at_ms = ? \
         WHERE id = 1",
        [delta_ms.into(), updated_at.into()],
    ))
    .await
    .map_err(map_db_err)?;
    Ok(())
}

/// 由 Dart 领域规则算好后一次性写入（可只写时长、只写 mark，或两者）。
pub async fn record_reading_activity(
    comic_id: &str,
    add_duration_ms: Option<i64>,
    mark_finished: bool,
) -> Result<(), HentaiError> {
    if let Some(delta) = add_duration_ms {
        add_reading_duration_ms(delta).await?;
    }
    if mark_finished {
        upsert_finished_comic_mark(comic_id, now_ms()).await?;
    }
    crate::revision::notify_committed();
    Ok(())
}

/// 从已达末页的 Reading history 幂等回填 Finished comic mark；不碰时长。
///
/// 返回尝试写入的候选行数（含已存在而被 `OR IGNORE` 跳过的）。
pub async fn backfill_finished_comics_from_history() -> Result<i32, HentaiError> {
    let db = connection()?;
    backfill_finished_comics_from_history_on(&db).await
}

pub async fn backfill_finished_comics_from_history_on(
    db: &DatabaseConnection,
) -> Result<i32, HentaiError> {
    let result = db
        .execute(Statement::from_string(
            db.get_database_backend(),
            BACKFILL_FINISHED_FROM_HISTORY_SQL.to_string(),
        ))
        .await
        .map_err(map_db_err)?;
    crate::revision::notify_committed();
    Ok(result.rows_affected() as i32)
}

/// 与 migration / FRB 共用的回填 SQL（`INSERT OR IGNORE` 幂等）。
pub const BACKFILL_FINISHED_FROM_HISTORY_SQL: &str = "\
INSERT OR IGNORE INTO comic_finished_marks (comic_id, finished_at_ms)
SELECT h.comic_id,
       COALESCE(h.last_read_time, CAST(strftime('%s','now') AS INTEGER) * 1000)
FROM comic_reading_histories h
INNER JOIN comic_meta m ON m.comic_id = h.comic_id
WHERE h.page_index IS NOT NULL
  AND m.page_count > 0
  AND h.page_index >= m.page_count";

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

    #[tokio::test]
    async fn backfill_marks_last_page_history_without_touching_duration() {
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
            "CREATE TABLE comic_meta (
                comic_id TEXT PRIMARY KEY,
                page_count INTEGER NOT NULL
            )",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "CREATE TABLE comic_reading_histories (
                comic_id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                last_read_time INTEGER NOT NULL,
                page_index INTEGER
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
            "INSERT INTO reading_duration_total (id, total_ms, updated_at_ms) VALUES (1, 0, 0)",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "INSERT INTO comics (comic_id, deleted_at) VALUES ('done', NULL), ('mid', NULL), ('gone', 1)",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "INSERT INTO comic_meta (comic_id, page_count) VALUES ('done', 10), ('mid', 10), ('gone', 5)",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "INSERT INTO comic_reading_histories (comic_id, title, last_read_time, page_index)
             VALUES ('done', 'Done', 100, 10), ('mid', 'Mid', 200, 5), ('gone', 'Gone', 300, 5)",
        )
        .await
        .unwrap();

        let first = backfill_finished_comics_from_history_on(&db).await.unwrap();
        assert_eq!(first, 2);
        let snap = load_reading_activity_stats(&db).await.unwrap();
        assert_eq!(snap.finished_count, 1);
        assert_eq!(snap.total_duration_ms, 0);

        let second = backfill_finished_comics_from_history_on(&db).await.unwrap();
        assert_eq!(second, 0);
        let snap2 = load_reading_activity_stats(&db).await.unwrap();
        assert_eq!(snap2.finished_count, 1);
        assert_eq!(snap2.total_duration_ms, 0);
    }

    #[tokio::test]
    async fn clearing_history_leaves_marks_and_duration() {
        let db = Database::connect("sqlite::memory:")
            .await
            .expect("memory db");
        db.execute_unprepared(
            "CREATE TABLE comics (comic_id TEXT PRIMARY KEY, deleted_at INTEGER)",
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
            "CREATE TABLE comic_reading_histories (
                comic_id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                last_read_time INTEGER NOT NULL,
                page_index INTEGER
            )",
        )
        .await
        .unwrap();
        db.execute_unprepared("INSERT INTO comics (comic_id, deleted_at) VALUES ('a', NULL)")
            .await
            .unwrap();
        db.execute_unprepared(
            "INSERT INTO comic_finished_marks (comic_id, finished_at_ms) VALUES ('a', 1)",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "INSERT INTO reading_duration_total (id, total_ms, updated_at_ms) VALUES (1, 90000, 1)",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "INSERT INTO comic_reading_histories (comic_id, title, last_read_time, page_index)
             VALUES ('a', 'A', 1, 10)",
        )
        .await
        .unwrap();

        db.execute_unprepared("DELETE FROM comic_reading_histories")
            .await
            .unwrap();

        let snap = load_reading_activity_stats(&db).await.unwrap();
        assert_eq!(snap.finished_count, 1);
        assert_eq!(snap.total_duration_ms, 90000);
    }
}
