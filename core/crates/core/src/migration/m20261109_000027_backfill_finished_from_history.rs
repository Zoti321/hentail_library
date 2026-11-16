use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

/// 与 `reading_activity::BACKFILL_FINISHED_FROM_HISTORY_SQL` 保持一致（避免 migration↔activity 循环依赖）。
const BACKFILL_SQL: &str = "\
INSERT OR IGNORE INTO comic_finished_marks (comic_id, finished_at_ms)
SELECT h.comic_id,
       COALESCE(h.last_read_time, CAST(strftime('%s','now') AS INTEGER) * 1000)
FROM comic_reading_histories h
INNER JOIN comic_meta m ON m.comic_id = h.comic_id
WHERE h.page_index IS NOT NULL
  AND m.page_count > 0
  AND h.page_index >= m.page_count";

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        let conn = manager.get_connection();
        // 幂等：表已由 000026 创建；仅从已达末页的 history 补 mark，不碰时长。
        conn.execute_unprepared(BACKFILL_SQL).await?;
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        // 回填不可逆：不清空 marks（可能含后续真实阅读写入）。
        Ok(())
    }
}
