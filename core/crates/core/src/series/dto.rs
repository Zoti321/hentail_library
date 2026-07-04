use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SeriesFilterDto {
    pub show_r18: bool,
    pub query: Option<String>,
    pub require_items: bool,
}

impl Default for SeriesFilterDto {
    fn default() -> Self {
        Self {
            show_r18: true,
            query: None,
            require_items: true,
        }
    }
}

impl SeriesFilterDto {
    pub fn normalized(self) -> Self {
        Self {
            show_r18: self.show_r18,
            query: normalize_query(self.query),
            require_items: self.require_items,
        }
    }
}

fn normalize_query(raw: Option<String>) -> Option<String> {
    raw.map(|s| s.trim().to_lowercase())
        .filter(|s| !s.is_empty())
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct SeriesSortOptionDto {
    pub descending: bool,
}
