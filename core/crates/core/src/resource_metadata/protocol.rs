use std::collections::{BTreeMap, BTreeSet};

use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

use crate::comic::ComicDto;
use crate::error::HentaiError;
use crate::metadata_lock::ComicMetaField;

pub const EXTENSION_NAMESPACE: &str = "https://github.com/Zoti321/hentail_library/ns/metadata";
pub const EXTENSION_VERSION: u32 = 1;

/// Portable values only: identities, locks, Reader and Series state stay in the catalog.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct MetadataSnapshot {
    pub title: String,
    pub description: Option<String>,
    pub published_at: Option<i64>,
    pub content_rating: String,
    pub authors: Vec<String>,
    pub tags: Vec<String>,
    pub language: Option<String>,
    pub parodies: Vec<String>,
    pub characters: Vec<String>,
}

impl From<&ComicDto> for MetadataSnapshot {
    fn from(comic: &ComicDto) -> Self {
        Self {
            title: comic.title.clone(),
            description: comic.description.clone(),
            published_at: comic.published_at,
            content_rating: comic.content_rating.clone(),
            authors: comic.author_names(),
            tags: comic.tags.clone(),
            language: crate::comic::single_language(&comic.languages)
                .into_iter()
                .next(),
            parodies: comic.parodies.clone(),
            characters: comic.characters.clone(),
        }
    }
}

/// The latest snapshot and the union of dirty fields; an empty value still means clear.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MetadataWriteIntent {
    pub snapshot: MetadataSnapshot,
    pub fields: BTreeSet<ComicMetaField>,
}

impl MetadataWriteIntent {
    pub fn full(snapshot: MetadataSnapshot) -> Self {
        Self {
            snapshot,
            fields: ComicMetaField::ALL.iter().copied().collect(),
        }
    }

    pub fn changed(previous: &MetadataSnapshot, snapshot: MetadataSnapshot) -> Self {
        let fields = ComicMetaField::ALL
            .iter()
            .copied()
            .filter(|field| previous.value(*field) != snapshot.value(*field))
            .collect();
        Self { snapshot, fields }
    }

    pub fn coalesce(&mut self, newer: Self) {
        self.fields.extend(newer.fields);
        self.snapshot = newer.snapshot;
    }

    /// Merge the extension object without removing fields introduced by another version.
    pub fn extension_json(&self, existing: Option<&str>) -> Result<String, HentaiError> {
        let mut extension: Extension = match existing {
            Some(raw) => serde_json::from_str(raw)
                .map_err(|_| HentaiError::validation("Malformed application metadata extension"))?,
            None => Extension {
                version: EXTENSION_VERSION,
                fields: Map::new(),
                extra: BTreeMap::new(),
            },
        };
        if extension.version != EXTENSION_VERSION {
            return Err(HentaiError::validation(
                "Cannot update an unsupported application metadata extension version",
            ));
        }
        for field in &self.fields {
            extension
                .fields
                .insert(field.as_str().to_owned(), self.snapshot.value(*field));
        }
        serde_json::to_string(&extension).map_err(|err| HentaiError::validation(err.to_string()))
    }
}

#[derive(Serialize, Deserialize)]
struct Extension {
    version: u32,
    fields: Map<String, Value>,
    #[serde(flatten)]
    extra: BTreeMap<String, Value>,
}

impl MetadataSnapshot {
    fn value(&self, field: ComicMetaField) -> Value {
        match field {
            ComicMetaField::Title => Value::String(self.title.clone()),
            ComicMetaField::Description => serde_json::json!(self.description),
            ComicMetaField::PublishedAt => serde_json::json!(self.published_at),
            ComicMetaField::ContentRating => Value::String(self.content_rating.clone()),
            ComicMetaField::Authors => serde_json::json!(self.authors),
            ComicMetaField::Tags => serde_json::json!(self.tags),
            ComicMetaField::Languages => serde_json::json!(self.language),
            ComicMetaField::Parodies => serde_json::json!(self.parodies),
            ComicMetaField::Characters => serde_json::json!(self.characters),
        }
    }

    /// Unsupported/malformed extension fields fall back to their standard projection.
    pub fn with_extension(mut self, raw: &str) -> Self {
        let Ok(extension) = serde_json::from_str::<Extension>(raw) else {
            return self;
        };
        if extension.version != EXTENSION_VERSION {
            return self;
        }
        for field in ComicMetaField::ALL {
            let Some(value) = extension.fields.get(field.as_str()) else {
                continue;
            };
            match field {
                ComicMetaField::Title => {
                    if let Some(value) = value.as_str() {
                        self.title = value.to_owned();
                    }
                }
                ComicMetaField::Description => {
                    if let Ok(value) = serde_json::from_value::<Option<String>>(value.clone()) {
                        self.description = value;
                    }
                }
                ComicMetaField::PublishedAt => {
                    if let Ok(value) = serde_json::from_value::<Option<i64>>(value.clone()) {
                        self.published_at = value;
                    }
                }
                ComicMetaField::ContentRating => {
                    if let Some(value @ ("unknown" | "safe" | "r18")) = value.as_str() {
                        self.content_rating = value.to_owned();
                    }
                }
                ComicMetaField::Languages => {
                    if let Ok(value) = serde_json::from_value::<Option<String>>(value.clone()) {
                        self.language = value;
                    }
                }
                ComicMetaField::Authors
                | ComicMetaField::Tags
                | ComicMetaField::Parodies
                | ComicMetaField::Characters => {
                    if let Ok(value) = serde_json::from_value::<Vec<String>>(value.clone()) {
                        match field {
                            ComicMetaField::Authors => self.authors = value,
                            ComicMetaField::Tags => self.tags = value,
                            ComicMetaField::Parodies => self.parodies = value,
                            ComicMetaField::Characters => self.characters = value,
                            _ => unreachable!(),
                        }
                    }
                }
            }
        }
        self
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn full_extension_restores_exact_values_without_application_identity() {
        let original = MetadataSnapshot {
            title: "标题 <&>".into(),
            description: Some("line 1\nline 2".into()),
            published_at: Some(-86_400_000),
            content_rating: "safe".into(),
            authors: vec!["A, B".into(), "C;D".into()],
            tags: vec!["tag,with,commas".into()],
            language: Some("Esperanto".into()),
            parodies: vec!["IP".into()],
            characters: vec!["Character".into()],
        };
        let raw = MetadataWriteIntent::full(original.clone())
            .extension_json(None)
            .unwrap();
        assert_eq!(MetadataSnapshot::default().with_extension(&raw), original);
        assert!(!raw.contains("comic_id"));
        assert!(!raw.contains("locks"));
    }

    #[test]
    fn coalescing_keeps_disjoint_fields_and_explicit_clears() {
        let original = MetadataSnapshot::default();
        let mut author_edit = original.clone();
        author_edit.authors = vec!["A".into()];
        let mut tag_edit = author_edit.clone();
        tag_edit.tags = vec!["T".into()];
        let mut cleared = tag_edit.clone();
        cleared.authors.clear();
        let mut intent = MetadataWriteIntent::changed(&original, author_edit.clone());
        intent.coalesce(MetadataWriteIntent::changed(&author_edit, tag_edit.clone()));
        intent.coalesce(MetadataWriteIntent::changed(&tag_edit, cleared));
        assert_eq!(intent.fields.len(), 2);
        let raw = intent.extension_json(None).unwrap();
        let value: Value = serde_json::from_str(&raw).unwrap();
        assert_eq!(value["fields"]["authors"], serde_json::json!([]));
        assert_eq!(value["fields"]["tags"], serde_json::json!(["T"]));
        assert!(value["fields"].get("title").is_none());
    }

    #[test]
    fn extension_updates_preserve_unknown_values_and_read_falls_back_per_field() {
        let existing = r#"{"version":1,"future":"keep","fields":{"future_field":[1],"title":"old","languages":7}}"#;
        let snapshot = MetadataSnapshot {
            title: "standard title".into(),
            language: Some("Japanese".into()),
            ..Default::default()
        };
        let imported = snapshot.clone().with_extension(existing);
        assert_eq!(imported.title, "old");
        assert_eq!(imported.language, snapshot.language);
        let intent = MetadataWriteIntent {
            snapshot,
            fields: [ComicMetaField::Description].into(),
        };
        let updated: Value =
            serde_json::from_str(&intent.extension_json(Some(existing)).unwrap()).unwrap();
        assert_eq!(updated["future"], "keep");
        assert_eq!(updated["fields"]["future_field"], serde_json::json!([1]));
        assert_eq!(updated["fields"]["title"], "old");
        assert!(updated["fields"]["description"].is_null());
    }

    #[test]
    fn unsupported_extensions_are_read_only_and_do_not_override_standard_fields() {
        let snapshot = MetadataSnapshot {
            title: "standard".into(),
            ..Default::default()
        };
        for raw in ["broken", r#"{"version":2,"fields":{"title":"future"}}"#] {
            assert_eq!(snapshot.clone().with_extension(raw), snapshot);
            assert!(MetadataWriteIntent::full(snapshot.clone())
                .extension_json(Some(raw))
                .is_err());
        }
    }
}
