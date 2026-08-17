use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SeriesFilterDto {
    pub show_r18: bool,
    pub r18_only: bool,
    pub query: Option<String>,
    pub require_items: bool,
    /// `None` = 不限；`Some` = 精确匹配 `series.serialization_status`。
    pub serialization_status: Option<String>,
    /// When `None`, browse APIs resolve to Current library.
    pub library_id: Option<String>,
}

impl Default for SeriesFilterDto {
    fn default() -> Self {
        Self {
            show_r18: true,
            r18_only: false,
            query: None,
            require_items: true,
            serialization_status: None,
            library_id: None,
        }
    }
}

impl SeriesFilterDto {
    pub fn normalized(self) -> Self {
        Self {
            show_r18: self.show_r18,
            r18_only: self.r18_only,
            query: normalize_query(self.query),
            require_items: self.require_items,
            serialization_status: normalize_serialization_status(self.serialization_status),
            library_id: self
                .library_id
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty()),
        }
    }
}

fn normalize_serialization_status(raw: Option<String>) -> Option<String> {
    raw.map(|s| s.trim().to_string()).filter(|s| !s.is_empty())
}

fn normalize_query(raw: Option<String>) -> Option<String> {
    raw.map(|s| s.trim().to_lowercase())
        .filter(|s| !s.is_empty())
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SeriesSortFieldDto {
    #[default]
    Name,
    ComicCount,
    Random,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct SeriesSortOptionDto {
    #[serde(default)]
    pub field: SeriesSortFieldDto,
    pub descending: bool,
}
