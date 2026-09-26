use std::collections::{HashMap, HashSet};

use sea_orm::{ConnectionTrait, DatabaseConnection, Statement, Value};

use crate::comic::write::{set_comic_meta_locks, update_comic_user_meta};
use crate::comic::{SetComicMetaLocksDto, UpdateComicUserMetaDto};
use crate::comic_id::normalize_path_for_key;
use crate::db::{connection, map_db_err};
use crate::error::HentaiError;
use crate::named_facet::JunctionNamedFacet;

use super::path_util::compute_relative_path;
use super::types::{ComicExportRecord, MetadataBackupPayload, OrphanFacetsRecord, SCHEMA_VERSION};

const MAX_SAMPLES: usize = 5;
const MAX_AMBIGUOUS_CANDIDATES: usize = 3;

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

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MatchTier {
    Path,
    LibraryRelative,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WouldApplySample {
    pub comic_id: String,
    pub path: String,
    pub title: String,
    pub matched_comic_id: String,
    pub match_tier: Option<MatchTier>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NotFoundSample {
    pub comic_id: String,
    pub path: String,
    pub title: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AmbiguousSample {
    pub comic_id: String,
    pub path: String,
    pub title: String,
    pub candidate_comic_ids: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImportPlan {
    pub would_apply: u32,
    pub skipped_not_found: u32,
    pub skipped_ambiguous: u32,
    pub would_upsert_orphan_facet_count: u32,
    pub samples_would_apply: Vec<WouldApplySample>,
    pub samples_not_found: Vec<NotFoundSample>,
    pub samples_ambiguous: Vec<AmbiguousSample>,
    applications: Vec<ComicImportApplication>,
    orphan_facets: OrphanFacetsRecord,
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct ComicImportApplication {
    matched_comic_id: String,
    record: ComicExportRecord,
}

enum MatchOutcome {
    Found {
        comic_id: String,
        tier: ResolvedMatchTier,
    },
    NotFound,
    Ambiguous {
        candidates: Vec<String>,
    },
}

enum ResolvedMatchTier {
    ComicId,
    Path,
    LibraryRelative,
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

pub async fn preview_import_comic_metadata(bytes: &[u8]) -> Result<ImportPlan, HentaiError> {
    plan_comic_metadata_import(bytes).await
}

pub async fn import_comic_metadata(bytes: &[u8]) -> Result<ImportComicMetadataResult, HentaiError> {
    let plan = plan_comic_metadata_import(bytes).await?;
    let db = connection()?;
    let mut result = ImportComicMetadataResult::default();

    for application in &plan.applications {
        match apply_comic_record(&db, &application.matched_comic_id, &application.record).await {
            Ok(()) => result.applied += 1,
            Err(err) => result.errors.push(format!(
                "comic {} 导入失败: {}",
                application.record.comic_id, err.message
            )),
        }
    }

    result.skipped_not_found = plan.skipped_not_found;
    result.skipped_ambiguous = plan.skipped_ambiguous;

    upsert_orphan_facets(&db, &plan.orphan_facets).await?;
    Ok(result)
}

async fn plan_comic_metadata_import(bytes: &[u8]) -> Result<ImportPlan, HentaiError> {
    let payload = parse_payload(bytes)?;
    let db = connection()?;
    let index = build_match_index(&db).await?;

    let mut would_apply = 0u32;
    let mut skipped_not_found = 0u32;
    let mut skipped_ambiguous = 0u32;
    let mut samples_would_apply = Vec::new();
    let mut samples_not_found = Vec::new();
    let mut samples_ambiguous = Vec::new();
    let mut applications = Vec::new();

    for record in &payload.comics {
        match resolve_match(&index, record) {
            MatchOutcome::Found { comic_id, tier } => {
                would_apply += 1;
                if samples_would_apply.len() < MAX_SAMPLES {
                    samples_would_apply.push(WouldApplySample {
                        comic_id: record.comic_id.clone(),
                        path: record.path.clone(),
                        title: record.meta.title.clone(),
                        matched_comic_id: comic_id.clone(),
                        match_tier: match tier {
                            ResolvedMatchTier::ComicId => None,
                            ResolvedMatchTier::Path => Some(MatchTier::Path),
                            ResolvedMatchTier::LibraryRelative => Some(MatchTier::LibraryRelative),
                        },
                    });
                }
                applications.push(ComicImportApplication {
                    matched_comic_id: comic_id,
                    record: record.clone(),
                });
            }
            MatchOutcome::NotFound => {
                skipped_not_found += 1;
                if samples_not_found.len() < MAX_SAMPLES {
                    samples_not_found.push(NotFoundSample {
                        comic_id: record.comic_id.clone(),
                        path: record.path.clone(),
                        title: record.meta.title.clone(),
                    });
                }
            }
            MatchOutcome::Ambiguous { candidates } => {
                skipped_ambiguous += 1;
                if samples_ambiguous.len() < MAX_SAMPLES {
                    samples_ambiguous.push(AmbiguousSample {
                        comic_id: record.comic_id.clone(),
                        path: record.path.clone(),
                        title: record.meta.title.clone(),
                        candidate_comic_ids: candidates
                            .into_iter()
                            .take(MAX_AMBIGUOUS_CANDIDATES)
                            .collect(),
                    });
                }
            }
        }
    }

    let would_upsert_orphan_facet_count =
        count_would_upsert_orphan_facets(&db, &payload.orphan_facets).await?;

    Ok(ImportPlan {
        would_apply,
        skipped_not_found,
        skipped_ambiguous,
        would_upsert_orphan_facet_count,
        samples_would_apply,
        samples_not_found,
        samples_ambiguous,
        applications,
        orphan_facets: payload.orphan_facets,
    })
}

fn parse_payload(bytes: &[u8]) -> Result<MetadataBackupPayload, HentaiError> {
    let payload: MetadataBackupPayload = serde_json::from_slice(bytes)
        .map_err(|err| HentaiError::validation(format!("无效的元数据备份 JSON: {err}")))?;
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
        return MatchOutcome::Found {
            comic_id: record.comic_id.clone(),
            tier: ResolvedMatchTier::ComicId,
        };
    }

    let normalized_path = normalize_path_for_key(&record.path);
    if !normalized_path.is_empty() {
        match index.by_normalized_path.get(&normalized_path) {
            Some(ids) if ids.len() == 1 => {
                return MatchOutcome::Found {
                    comic_id: ids[0].clone(),
                    tier: ResolvedMatchTier::Path,
                };
            }
            Some(ids) if ids.len() > 1 => {
                return MatchOutcome::Ambiguous {
                    candidates: ids.clone(),
                };
            }
            _ => {}
        }
    }

    if let Some(relative_path) = record.relative_path.as_deref().filter(|s| !s.is_empty()) {
        if !record.library_id.is_empty() {
            let key = (record.library_id.clone(), relative_path.to_string());
            match index.by_library_relative.get(&key) {
                Some(ids) if ids.len() == 1 => {
                    return MatchOutcome::Found {
                        comic_id: ids[0].clone(),
                        tier: ResolvedMatchTier::LibraryRelative,
                    };
                }
                Some(ids) if ids.len() > 1 => {
                    return MatchOutcome::Ambiguous {
                        candidates: ids.clone(),
                    };
                }
                _ => {}
            }
        }
    }

    MatchOutcome::NotFound
}

async fn count_would_upsert_orphan_facets(
    db: &DatabaseConnection,
    orphans: &OrphanFacetsRecord,
) -> Result<u32, HentaiError> {
    let mut total = 0u32;
    total += count_new_orphan_names(db, JunctionNamedFacet::Tag, &orphans.tags).await?;
    total += count_new_orphan_names(db, JunctionNamedFacet::Author, &orphans.authors).await?;
    total += count_new_orphan_names(db, JunctionNamedFacet::Parody, &orphans.parodies).await?;
    total += count_new_orphan_names(db, JunctionNamedFacet::Character, &orphans.characters).await?;
    Ok(total)
}

async fn count_new_orphan_names<C: ConnectionTrait>(
    db: &C,
    facet: JunctionNamedFacet,
    names: &[String],
) -> Result<u32, HentaiError> {
    let mut unique = HashSet::new();
    for name in names {
        let trimmed = name.trim();
        if !trimmed.is_empty() {
            unique.insert(trimmed.to_string());
        }
    }
    if unique.is_empty() {
        return Ok(0);
    }

    let dict = facet.dict_table();
    let rows = db
        .query_all(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!("SELECT name FROM {dict}"),
        ))
        .await
        .map_err(map_db_err)?;

    let existing: HashSet<String> = rows
        .into_iter()
        .filter_map(|row| row.try_get_by_index::<String>(0).ok())
        .collect();

    Ok(unique
        .into_iter()
        .filter(|name| !existing.contains(name))
        .count() as u32)
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

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_record(comic_id: &str, path: &str) -> ComicExportRecord {
        ComicExportRecord {
            comic_id: comic_id.to_string(),
            path: path.to_string(),
            library_id: "lib1".to_string(),
            relative_path: Some("series/a.cbz".to_string()),
            meta: super::super::types::ComicMetaExportRecord {
                title: format!("Title {comic_id}"),
                description: None,
                published_at: None,
                content_rating: "unknown".to_string(),
                languages: vec![],
                locks: Default::default(),
            },
            authors: vec![],
            tags: vec![],
            parodies: vec![],
            characters: vec![],
        }
    }

    fn index_with(ids: &[(&str, &str, &str, Option<&str>)]) -> ComicMatchIndex {
        let mut existing_ids = HashMap::new();
        let mut by_normalized_path: HashMap<String, Vec<String>> = HashMap::new();
        let mut by_library_relative: HashMap<(String, String), Vec<String>> = HashMap::new();

        for (comic_id, path, library_id, relative) in ids {
            existing_ids.insert(comic_id.to_string(), ());
            let normalized = normalize_path_for_key(path);
            if !normalized.is_empty() {
                by_normalized_path
                    .entry(normalized)
                    .or_default()
                    .push(comic_id.to_string());
            }
            if let Some(relative_path) = relative {
                by_library_relative
                    .entry((library_id.to_string(), relative_path.to_string()))
                    .or_default()
                    .push(comic_id.to_string());
            }
        }

        ComicMatchIndex {
            existing_ids,
            by_normalized_path,
            by_library_relative,
        }
    }

    #[test]
    fn resolve_match_prefers_comic_id() {
        let index = index_with(&[("c1", "E:/lib/a.cbz", "lib1", Some("a.cbz"))]);
        let record = sample_record("c1", "E:/other/a.cbz");
        let MatchOutcome::Found { tier, .. } = resolve_match(&index, &record) else {
            panic!("expected found");
        };
        assert!(matches!(tier, ResolvedMatchTier::ComicId));
    }

    #[test]
    fn resolve_match_falls_back_to_normalized_path() {
        let index = index_with(&[("c2", "E:/lib/series/a.cbz", "lib1", None)]);
        let record = sample_record("missing", "E:/lib/series/a.cbz");
        let MatchOutcome::Found { comic_id, tier } = resolve_match(&index, &record) else {
            panic!("expected found");
        };
        assert_eq!(comic_id, "c2");
        assert!(matches!(tier, ResolvedMatchTier::Path));
    }

    #[test]
    fn resolve_match_falls_back_to_library_relative() {
        let index = index_with(&[("c3", "E:/lib/series/a.cbz", "lib1", Some("series/a.cbz"))]);
        let mut record = sample_record("missing", "E:/moved/series/a.cbz");
        record.relative_path = Some("series/a.cbz".to_string());
        record.library_id = "lib1".to_string();
        let MatchOutcome::Found { comic_id, tier } = resolve_match(&index, &record) else {
            panic!("expected found");
        };
        assert_eq!(comic_id, "c3");
        assert!(matches!(tier, ResolvedMatchTier::LibraryRelative));
    }

    #[test]
    fn resolve_match_reports_ambiguous_candidates() {
        let index = index_with(&[
            ("c4", "E:/lib/dup.cbz", "lib1", None),
            ("c5", "E:/lib/dup.cbz", "lib1", None),
        ]);
        let record = sample_record("missing", "E:/lib/dup.cbz");
        let MatchOutcome::Ambiguous { candidates } = resolve_match(&index, &record) else {
            panic!("expected ambiguous");
        };
        assert_eq!(candidates.len(), 2);
    }

    #[test]
    fn resolve_match_not_found_when_no_tier_matches() {
        let index = index_with(&[]);
        let record = sample_record("missing", "E:/lib/none.cbz");
        assert!(matches!(
            resolve_match(&index, &record),
            MatchOutcome::NotFound
        ));
    }
}
