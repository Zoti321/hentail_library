use std::collections::HashMap;

use sea_orm::{ConnectionTrait, DatabaseConnection, Statement, Value};

use crate::comic::write::{set_comic_meta_locks, update_comic_user_meta};
use crate::comic::{SetComicMetaLocksDto, UpdateComicUserMetaDto};
use crate::comic_id::normalize_path_for_key;
use crate::db::{connection, map_db_err};
use crate::error::HentaiError;
use crate::named_facet::JunctionNamedFacet;

use super::path_util::compute_relative_path;
use super::types::{
    ComicExportRecord, MetadataBackupPayload, OrphanFacetsRecord, SCHEMA_VERSION,
};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MetadataBackupManifest {
    pub schema_version: u32,
    pub exported_at: String,
    pub app_version: String,
    pub comic_count: u32,
    pub include_orphan_facets: bool,
    pub library_id: Option<String>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ImportComicMetadataResult {
    pub applied: u32,
    pub skipped_not_found: u32,
    pub skipped_ambiguous: u32,
    pub errors: Vec<String>,
}

enum MatchOutcome {
    Found(String),
    NotFound,
    Ambiguous,
}

struct ComicMatchIndex {
    existing_ids: HashMap<String, ()>,
    by_normalized_path: HashMap<String, Vec<String>>,
    by_library_relative: HashMap<(String, String), Vec<String>>,
}

pub fn peek_metadata_backup_manifest(bytes: &[u8]) -> Result<MetadataBackupManifest, HentaiError> {
    let payload = parse_payload(bytes)?;
    Ok(MetadataBackupManifest {
        schema_version: payload.schema_version,
        exported_at: payload.exported_at,
        app_version: payload.app_version,
        comic_count: payload.comics.len() as u32,
        include_orphan_facets: payload.options.include_orphan_facets,
        library_id: payload.options.library_id,
    })
}

pub async fn import_comic_metadata(bytes: &[u8]) -> Result<ImportComicMetadataResult, HentaiError> {
    let payload = parse_payload(bytes)?;
    let db = connection()?;
    let index = build_match_index(&db).await?;
    let mut result = ImportComicMetadataResult::default();

    for record in &payload.comics {
        match resolve_match(&index, record) {
            MatchOutcome::Found(comic_id) => {
                if let Err(err) = apply_comic_record(&db, &comic_id, record).await {
                    result.errors.push(format!(
                        "comic {} 导入失败: {}",
                        record.comic_id, err.message
                    ));
                } else {
                    result.applied += 1;
                }
            }
            MatchOutcome::NotFound => result.skipped_not_found += 1,
            MatchOutcome::Ambiguous => result.skipped_ambiguous += 1,
        }
    }

    upsert_orphan_facets(&db, &payload.orphan_facets).await?;
    Ok(result)
}

fn parse_payload(bytes: &[u8]) -> Result<MetadataBackupPayload, HentaiError> {
    let payload: MetadataBackupPayload = serde_json::from_slice(bytes).map_err(|err| {
        HentaiError::validation(format!("无效的元数据备份 JSON: {err}"))
    })?;
    if payload.schema_version != SCHEMA_VERSION {
        return Err(HentaiError::validation(format!(
            "不支持的 schema_version {}（仅支持 {SCHEMA_VERSION}）",
            payload.schema_version
        )));
    }
    Ok(payload)
}

async fn build_match_index(db: &DatabaseConnection) -> Result<ComicMatchIndex, HentaiError> {
    let rows = db
        .query_all(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT c.comic_id, c.path, c.library_id, l.root_path \
             FROM comics c \
             LEFT JOIN libraries l ON l.library_id = c.library_id"
                .to_string(),
        ))
        .await
        .map_err(map_db_err)?;

    let mut existing_ids = HashMap::new();
    let mut by_normalized_path: HashMap<String, Vec<String>> = HashMap::new();
    let mut by_library_relative: HashMap<(String, String), Vec<String>> = HashMap::new();

    for row in rows {
        let comic_id = row
            .try_get_by_index::<String>(0)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
        let path = row
            .try_get_by_index::<String>(1)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
        let library_id = row
            .try_get_by_index::<String>(2)
            .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
        let root_path = row.try_get_by_index::<Option<String>>(3).ok().flatten();

        existing_ids.insert(comic_id.clone(), ());

        let normalized_path = normalize_path_for_key(&path);
        if !normalized_path.is_empty() {
            by_normalized_path
                .entry(normalized_path)
                .or_default()
                .push(comic_id.clone());
        }

        if let Some(root_path) = root_path {
            if let Some(relative_path) = compute_relative_path(&path, &root_path) {
                by_library_relative
                    .entry((library_id, relative_path))
                    .or_default()
                    .push(comic_id);
            }
        }
    }

    Ok(ComicMatchIndex {
        existing_ids,
        by_normalized_path,
        by_library_relative,
    })
}

fn resolve_match(index: &ComicMatchIndex, record: &ComicExportRecord) -> MatchOutcome {
    if index.existing_ids.contains_key(&record.comic_id) {
        return MatchOutcome::Found(record.comic_id.clone());
    }

    let normalized_path = normalize_path_for_key(&record.path);
    if !normalized_path.is_empty() {
        match index.by_normalized_path.get(&normalized_path) {
            Some(ids) if ids.len() == 1 => {
                return MatchOutcome::Found(ids[0].clone());
            }
            Some(ids) if ids.len() > 1 => return MatchOutcome::Ambiguous,
            _ => {}
        }
    }

    if let Some(relative_path) = record.relative_path.as_deref().filter(|s| !s.is_empty()) {
        if !record.library_id.is_empty() {
            let key = (record.library_id.clone(), relative_path.to_string());
            match index.by_library_relative.get(&key) {
                Some(ids) if ids.len() == 1 => {
                    return MatchOutcome::Found(ids[0].clone());
                }
                Some(ids) if ids.len() > 1 => return MatchOutcome::Ambiguous,
                _ => {}
            }
        }
    }

    MatchOutcome::NotFound
}

async fn apply_comic_record(
    _db: &DatabaseConnection,
    comic_id: &str,
    record: &ComicExportRecord,
) -> Result<(), HentaiError> {
    update_comic_user_meta(
        comic_id,
        UpdateComicUserMetaDto {
            title: Some(record.meta.title.clone()),
            content_rating: Some(record.meta.content_rating.clone()),
            description: Some(record.meta.description.clone().unwrap_or_default()),
            published_at: Some(record.meta.published_at.unwrap_or(-1)),
            authors: Some(record.authors.clone()),
            tags: Some(record.tags.clone()),
            languages: Some(record.meta.languages.clone()),
            parodies: Some(record.parodies.clone()),
            characters: Some(record.characters.clone()),
        },
    )
    .await?;

    set_comic_meta_locks(
        comic_id,
        SetComicMetaLocksDto {
            title: Some(true),
            description: Some(true),
            published_at: Some(true),
            content_rating: Some(true),
            authors: Some(true),
            tags: Some(true),
            languages: Some(true),
            parodies: Some(true),
            characters: Some(true),
        },
    )
    .await?;
    Ok(())
}

async fn upsert_orphan_facets(
    db: &DatabaseConnection,
    orphans: &OrphanFacetsRecord,
) -> Result<(), HentaiError> {
    upsert_orphan_names(db, JunctionNamedFacet::Tag, &orphans.tags).await?;
    upsert_orphan_names(db, JunctionNamedFacet::Author, &orphans.authors).await?;
    upsert_orphan_names(db, JunctionNamedFacet::Parody, &orphans.parodies).await?;
    upsert_orphan_names(db, JunctionNamedFacet::Character, &orphans.characters).await?;
    Ok(())
}

async fn upsert_orphan_names<C: ConnectionTrait>(
    db: &C,
    facet: JunctionNamedFacet,
    names: &[String],
) -> Result<(), HentaiError> {
    let dict = facet.dict_table();
    for name in names {
        let trimmed = name.trim();
        if trimmed.is_empty() {
            continue;
        }
        db.execute(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!("INSERT OR IGNORE INTO {dict} (name) VALUES (?)"),
            [Value::String(Some(Box::new(trimmed.to_string())))],
        ))
        .await
        .map_err(map_db_err)?;
    }
    Ok(())
}
