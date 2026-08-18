use std::collections::{HashMap, HashSet};

use sea_orm::{ColumnTrait, EntityTrait, QueryFilter, Set, TransactionTrait};

use crate::db::{connection, map_db_err};
use crate::entity::{prelude::*, tags};
use crate::error::HentaiError;

const ALLOWED_NAMESPACES: &[&str] = &["female", "male", "mixed", "other"];

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct TagDictionaryImportResult {
    pub added: u32,
    pub skipped_existing: u32,
    pub skipped_filtered_or_empty_or_dedupe: u32,
}

#[derive(Debug, serde::Deserialize)]
struct EhTagDatabase {
    data: Vec<EhTagNamespaceBlock>,
}

#[derive(Debug, serde::Deserialize)]
struct EhTagNamespaceBlock {
    namespace: String,
    data: HashMap<String, EhTagEntry>,
}

#[derive(Debug, serde::Deserialize)]
struct EhTagEntry {
    name: Option<String>,
}

pub async fn import_ehtag_dictionary(
    json_bytes: &[u8],
) -> Result<TagDictionaryImportResult, HentaiError> {
    let parsed: EhTagDatabase = serde_json::from_slice(json_bytes)
        .map_err(|err| HentaiError::validation(format!("无效的 db.text.json: {err}")))?;

    let (candidates, skipped_filtered_or_empty_or_dedupe) = collect_candidate_names(&parsed);
    if candidates.is_empty() {
        return Ok(TagDictionaryImportResult {
            added: 0,
            skipped_existing: 0,
            skipped_filtered_or_empty_or_dedupe,
        });
    }

    let db = connection()?;
    let existing_rows = Tags::find()
        .filter(tags::Column::Name.is_in(candidates.clone()))
        .all(&db)
        .await
        .map_err(map_db_err)?;
    let existing: HashSet<String> = existing_rows.into_iter().map(|row| row.name).collect();

    let mut to_insert = Vec::new();
    let mut skipped_existing = 0u32;
    for name in candidates {
        if existing.contains(&name) {
            skipped_existing += 1;
        } else {
            to_insert.push(name);
        }
    }

    let added = to_insert.len() as u32;
    if !to_insert.is_empty() {
        let txn = db.begin().await.map_err(map_db_err)?;
        for name in to_insert {
            let active = tags::ActiveModel {
                name: Set(name),
            };
            Tags::insert(active)
                .on_conflict(
                    sea_orm::sea_query::OnConflict::column(tags::Column::Name)
                        .do_nothing()
                        .to_owned(),
                )
                .do_nothing()
                .exec(&txn)
                .await
                .map_err(map_db_err)?;
        }
        txn.commit().await.map_err(map_db_err)?;
    }

    Ok(TagDictionaryImportResult {
        added,
        skipped_existing,
        skipped_filtered_or_empty_or_dedupe,
    })
}

fn collect_candidate_names(db: &EhTagDatabase) -> (Vec<String>, u32) {
    let mut seen = HashSet::new();
    let mut candidates = Vec::new();
    let mut skipped = 0u32;

    for block in &db.data {
        if !ALLOWED_NAMESPACES.contains(&block.namespace.as_str()) {
            skipped += block.data.len() as u32;
            continue;
        }
        for entry in block.data.values() {
            let Some(raw) = entry.name.as_ref() else {
                skipped += 1;
                continue;
            };
            let name = raw.trim();
            if name.is_empty() {
                skipped += 1;
                continue;
            }
            let owned = name.to_string();
            if !seen.insert(owned.clone()) {
                skipped += 1;
                continue;
            }
            candidates.push(owned);
        }
    }

    (candidates, skipped)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn collect_candidate_names_filters_and_dedupes() {
        let db: EhTagDatabase = serde_json::from_str(
            r#"{
              "data": [
                {
                  "namespace": "female",
                  "data": {
                    "big breasts": { "name": "巨乳" },
                    "empty tag": { "name": "" },
                    "no name": {}
                  }
                },
                {
                  "namespace": "male",
                  "data": {
                    "muscle": { "name": "肌肉" }
                  }
                },
                {
                  "namespace": "artist",
                  "data": {
                    "some artist": { "name": "某画师" }
                  }
                },
                {
                  "namespace": "female",
                  "data": {
                    "duplicate": { "name": "巨乳" }
                  }
                }
              ]
            }"#,
        )
        .expect("fixture");

        let (names, skipped) = collect_candidate_names(&db);
        assert_eq!(names, vec!["巨乳".to_string(), "肌肉".to_string()]);
        assert_eq!(skipped, 4);
    }
}
