#[derive(Debug, Clone)]
pub struct ReaderPageListDto {
    pub resource_type: String,
    pub page_count: i32,
    pub dir_page_paths: Vec<String>,
}
