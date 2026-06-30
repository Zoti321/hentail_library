use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComicFilterDto {
    pub show_r18: bool,
    pub query: Option<String>,
    pub resource_types: Vec<String>,
    pub content_ratings: Vec<String>,
    pub tags_all: Vec<String>,
    pub tags_any: Vec<String>,
    pub tags_exclude: Vec<String>,
    pub exclude_comics_in_any_series: bool,
}

impl Default for ComicFilterDto {
    fn default() -> Self {
        Self {
            show_r18: true,
            query: None,
            resource_types: vec![],
            content_ratings: vec![],
            tags_all: vec![],
            tags_any: vec![],
            tags_exclude: vec![],
            exclude_comics_in_any_series: false,
        }
    }
}

impl ComicFilterDto {
    pub fn normalized(self) -> Self {
        Self {
            show_r18: self.show_r18,
            query: normalize_query(self.query),
            resource_types: self.resource_types,
            content_ratings: self.content_ratings,
            tags_all: normalize_tags(self.tags_all),
            tags_any: normalize_tags(self.tags_any),
            tags_exclude: normalize_tags(self.tags_exclude),
            exclude_comics_in_any_series: self.exclude_comics_in_any_series,
        }
    }
}

fn normalize_query(raw: Option<String>) -> Option<String> {
    raw.map(|s| s.trim().to_lowercase())
        .filter(|s| !s.is_empty())
}

fn normalize_tags(tags: Vec<String>) -> Vec<String> {
    tags.into_iter()
        .map(|t| t.trim().to_lowercase())
        .filter(|t| !t.is_empty())
        .collect()
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComicDto {
    pub comic_id: String,
    pub path: String,
    pub resource_type: String,
    pub title: String,
    pub content_rating: String,
    pub page_count: Option<i32>,
    pub authors: Vec<String>,
    pub tags: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PageRequestDto {
    pub page: i32,
    pub page_size: i32,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ComicSortOptionDto {
    pub descending: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PagedComicResultDto {
    pub items: Vec<ComicDto>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}
