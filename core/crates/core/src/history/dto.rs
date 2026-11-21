#[derive(Debug, Clone)]
pub struct ReadingHistoryDto {
    pub comic_id: String,
    pub title: String,
    pub last_read_time_ms: i64,
    pub page_index: Option<i32>,
    /// Comic 元数据中的总页数；列表/查询时 join 填充，写入阅读进度时不持久化。
    pub page_count: Option<i32>,
}

#[derive(Debug, Clone)]
pub struct ReadPageIndexDto {
    pub comic_id: String,
    pub page_index: i32,
}

#[derive(Debug, Clone)]
pub struct PagedReadingHistoryDto {
    pub items: Vec<ReadingHistoryDto>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

/// Per time-section counts for the reading history list (same filters as the page query).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct ReadingHistoryTimeSectionCountsDto {
    pub today: i64,
    pub yesterday: i64,
    pub this_week: i64,
    pub this_month: i64,
    pub earlier: i64,
}

impl ReadingHistoryTimeSectionCountsDto {
    pub fn total(self) -> i64 {
        self.today + self.yesterday + self.this_week + self.this_month + self.earlier
    }
}
