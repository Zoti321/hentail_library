use std::collections::{HashSet};

use sea_orm::{ColumnTrait, EntityTrait, QueryFilter, Set, TransactionTrait};

use crate::db::{connection, map_db_err};
use crate::entity::{prelude::*, tags};
use crate::error::HentaiError;

const TAG_INSERT_BATCH_SIZE: usize = 500;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct TagDictionaryImportResult {
    pub added: u32,
    pub skipped_existing: u32,
    pub skipped_filtered_or_empty_or_dedupe: u32,
}

#[derive(Debug, serde::Deserialize)]
#[serde(untagged)]
enum TagDictionaryPayload {
    Wrapped { tags: Vec<String> },
    Flat(Vec<String>),
}

pub async fn import_tag_dictionary(
    json_bytes: &[u8],
) -> Result<TagDictionaryImportResult, HentaiError> {
    let parsed: TagDictionaryPayload = serde_json::from_slice(json_bytes).map_err(|err| {
        HentaiError::validation(format!(
            "无效的标签字典 JSON（期望 {{\"tags\": [...]}} 或 [...]）: {err}"
        ))
    })?;

    let (candidates, skipped_filtered_or_empty_or_dedupe) = collect_candidate_names(parsed);
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
        insert_tag_names_ignore_conflict(&txn, &to_insert).await?;
        txn.commit().await.map_err(map_db_err)?;
    }

    Ok(TagDictionaryImportResult {
        added,
        skipped_existing,
        skipped_filtered_or_empty_or_dedupe,
    })
}

async fn insert_tag_names_ignore_conflict(
    conn: &impl sea_orm::ConnectionTrait,
    names: &[String],
) -> Result<(), HentaiError> {
    if names.is_empty() {
        return Ok(());
    }

    for chunk in names.chunks(TAG_INSERT_BATCH_SIZE) {
        let models: Vec<tags::ActiveModel> = chunk
            .iter()
            .map(|name| tags::ActiveModel {
                name: Set(name.clone()),
            })
            .collect();
        Tags::insert_many(models)
            .on_conflict(
                sea_orm::sea_query::OnConflict::column(tags::Column::Name)
                    .do_nothing()
                    .to_owned(),
            )
            .do_nothing()
            .exec(conn)
            .await
            .map_err(map_db_err)?;
    }

    Ok(())
}

fn collect_candidate_names(payload: TagDictionaryPayload) -> (Vec<String>, u32) {
    let raw_tags = match payload {
        TagDictionaryPayload::Wrapped { tags } => tags,
        TagDictionaryPayload::Flat(tags) => tags,
    };

    let mut seen = HashSet::new();
    let mut candidates = Vec::new();
    let mut skipped = 0u32;

    for raw in raw_tags {
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

    (candidates, skipped)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn collect_candidate_names_accepts_wrapped_and_flat_payloads() {
        let wrapped: TagDictionaryPayload = serde_json::from_str(
            r#"{"tags": ["全彩", "  ", "NTR", "NTR"]}"#,
        )
        .expect("wrapped fixture");
        let (wrapped_names, wrapped_skipped) = collect_candidate_names(wrapped);
        assert_eq!(wrapped_names, vec!["全彩".to_string(), "NTR".to_string()]);
        assert_eq!(wrapped_skipped, 2);

        let flat: TagDictionaryPayload =
            serde_json::from_str(r#"["巨乳", "肌肉"]"#).expect("flat fixture");
        let (flat_names, flat_skipped) = collect_candidate_names(flat);
        assert_eq!(flat_names, vec!["巨乳".to_string(), "肌肉".to_string()]);
        assert_eq!(flat_skipped, 0);
    }
}
