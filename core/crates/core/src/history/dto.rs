#[derive(Debug, Clone)]
pub struct ReadingHistoryDto {
    pub comic_id: String,
    pub title: String,
    pub last_read_time_ms: i64,
    pub page_index: Option<i32>,
}

#[derive(Debug, Clone)]
pub struct SeriesReadingHistoryDto {
    pub series_name: String,
    pub last_read_comic_id: String,
    pub last_read_time_ms: i64,
    pub page_index: Option<i32>,
}

#[derive(Debug, Clone)]
pub struct PagedReadingHistoryDto {
    pub items: Vec<ReadingHistoryDto>,
    pub total_count: i64,
}

#[derive(Debug, Clone)]
pub struct PagedSeriesReadingHistoryDto {
    pub items: Vec<SeriesReadingHistoryDto>,
    pub total_count: i64,
}
