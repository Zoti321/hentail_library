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
