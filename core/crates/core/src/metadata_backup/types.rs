use serde::{Deserialize, Serialize};

use crate::comic::ComicMetaLocks;

pub const SCHEMA_VERSION: u32 = 1;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct ExportOptionsRecord {
    pub library_id: Option<String>,
    pub include_orphan_facets: bool,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize, PartialEq, Eq)]
pub struct OrphanFacetsRecord {
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub tags: Vec<String>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub authors: Vec<String>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub parodies: Vec<String>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub characters: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct ComicMetaExportRecord {
    pub title: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub published_at: Option<i64>,
    pub content_rating: String,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub languages: Vec<String>,
    pub locks: ComicMetaLocks,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct ComicExportRecord {
    pub comic_id: String,
    pub path: String,
    pub library_id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub relative_path: Option<String>,
    pub meta: ComicMetaExportRecord,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub authors: Vec<String>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub tags: Vec<String>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub parodies: Vec<String>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub characters: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct MetadataBackupPayload {
    pub schema_version: u32,
    pub exported_at: String,
    pub app_version: String,
    pub options: ExportOptionsRecord,
    #[serde(default, skip_serializing_if = "OrphanFacetsRecord::is_empty")]
    pub orphan_facets: OrphanFacetsRecord,
    pub comics: Vec<ComicExportRecord>,
}

impl OrphanFacetsRecord {
    fn is_empty(&self) -> bool {
        self.tags.is_empty()
            && self.authors.is_empty()
            && self.parodies.is_empty()
            && self.characters.is_empty()
    }
}
