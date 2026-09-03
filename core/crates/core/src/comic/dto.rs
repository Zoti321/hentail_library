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
    pub authors_all: Vec<String>,
    pub authors_any: Vec<String>,
    pub authors_exclude: Vec<String>,
    /// When `None`, browse APIs resolve to Current library.
    pub library_id: Option<String>,
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
            authors_all: vec![],
            authors_any: vec![],
            authors_exclude: vec![],
            library_id: None,
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
            authors_all: normalize_tags(self.authors_all),
            authors_any: normalize_tags(self.authors_any),
            authors_exclude: normalize_tags(self.authors_exclude),
            library_id: self
                .library_id
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty()),
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

/// Per-field locks for Comic metadata (Komga-style). Default: all unlocked.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct ComicMetaLocks {
    pub title: bool,
    pub description: bool,
    pub published_at: bool,
    pub content_rating: bool,
    pub authors: bool,
    pub tags: bool,
    pub languages: bool,
    pub parodies: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComicDto {
    pub comic_id: String,
    pub path: String,
    pub resource_type: String,
    pub resource_size: i64,
    pub created_at: i64,
    pub last_updated_at: i64,
    pub title: String,
    pub content_rating: String,
    pub page_count: i32,
    pub description: Option<String>,
    pub published_at: Option<i64>,
    pub last_read_time_ms: Option<i64>,
    pub authors: Vec<String>,
    pub tags: Vec<String>,
    /// Ordered canonical English language names; empty = unset.
    #[serde(default)]
    pub languages: Vec<String>,
    /// Parody (IP / franchise) names attached to this Comic; empty = none.
    #[serde(default)]
    pub parodies: Vec<String>,
    #[serde(default)]
    pub locks: ComicMetaLocks,
    #[serde(default)]
    pub library_id: String,
}

/// Serialize Language list for `comic_meta.languages` JSON column.
pub fn serialize_languages(languages: &[String]) -> String {
    serde_json::to_string(languages).unwrap_or_else(|_| "[]".to_string())
}

/// Parse Language list; invalid JSON → empty (unset).
pub fn parse_languages_json(raw: &str) -> Vec<String> {
    let Ok(values) = serde_json::from_str::<Vec<String>>(raw) else {
        return Vec::new();
    };
    values
        .into_iter()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect()
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PageRequestDto {
    pub page: i32,
    pub page_size: i32,
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ComicSortFieldDto {
    #[default]
    Title,
    CreatedAt,
    LastUpdatedAt,
    PublishedAt,
    ReadAt,
    FileSize,
    PageCount,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ComicSortOptionDto {
    #[serde(default)]
    pub field: ComicSortFieldDto,
    pub descending: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PagedComicResultDto {
    pub items: Vec<ComicDto>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

pub fn now_ms() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0)
}
