use std::collections::HashMap;

use sea_orm::{ConnectionTrait, DatabaseConnection, Statement, Value};

use crate::comic::repository::load_comics_ordered;
use crate::db::{connection, map_db_err};
use crate::error::HentaiError;
use crate::named_facet::JunctionNamedFacet;

use super::path_util::compute_relative_path;
use super::types::{
    ComicExportRecord, ComicMetaExportRecord, ExportOptionsRecord, MetadataBackupPayload,
    OrphanFacetsRecord, SCHEMA_VERSION,
};

#[derive(Debug, Clone, Default)]
pub struct ExportComicMetadataOptions {
    pub library_id: Option<String>,
    pub include_orphan_facets: bool,
}

pub async fn export_comic_metadata(
    options: ExportComicMetadataOptions,
) -> Result<Vec<u8>, HentaiError> {
    let library_id = options
        .library_id
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(str::to_string);

    let db = connection()?;
    let comic_ids = load_export_comic_ids(&db, library_id.as_deref()).await?;
    let comics = load_comics_ordered(&db, comic_ids).await?;
    let library_roots = load_library_roots(&db).await?;

    let export_comics = comics
        .into_iter()
        .map(|comic| {
            let relative_path = library_roots
                .get(&comic.library_id)
                .and_then(|root| compute_relative_path(&comic.path, root));
            ComicExportRecord {
                comic_id: comic.comic_id,
                path: comic.path,
                library_id: comic.library_id,
                relative_path,
                meta: ComicMetaExportRecord {
                    title: comic.title,
                    description: comic.description,
                    published_at: comic.published_at,
                    content_rating: comic.content_rating,
                    languages: comic.languages,
                    locks: comic.locks,
                },
                authors: comic.authors,
                tags: comic.tags,
                parodies: comic.parodies,
                characters: comic.characters,
            }
        })
        .collect();

    let orphan_facets = if options.include_orphan_facets {
        load_orphan_facets(&db).await?
    } else {
        OrphanFacetsRecord::default()
    };

    let payload = MetadataBackupPayload {
        schema_version: SCHEMA_VERSION,
        exported_at: utc_now_rfc3339(),
        app_version: env!("CARGO_PKG_VERSION").to_string(),
        options: ExportOptionsRecord {
            library_id,
            include_orphan_facets: options.include_orphan_facets,
        },
        orphan_facets,
        comics: export_comics,
    };

    serde_json::to_vec(&payload)
        .map_err(|err| HentaiError::validation(format!("元数据备份 JSON 序列化失败: {err}")))
}

async fn load_export_comic_ids(
    db: &DatabaseConnection,
    library_id: Option<&str>,
) -> Result<Vec<String>, HentaiError> {
    let (sql, values) = match library_id {
        Some(id) => (
            "SELECT comic_id FROM comics WHERE library_id = ? ORDER BY comic_id ASC".to_string(),
            vec![Value::String(Some(Box::new(id.to_string())))],
        ),
        None => (
            "SELECT comic_id FROM comics ORDER BY comic_id ASC".to_string(),
            vec![],
        ),
    };
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            sql,
            values,
        ))
        .await
        .map_err(map_db_err)?;
    rows.into_iter()
        .map(|row| {
            row.try_get_by_index::<String>(0)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
        })
        .collect()
}

async fn load_library_roots(
    db: &DatabaseConnection,
) -> Result<HashMap<String, String>, HentaiError> {
    let rows = db
        .query_all(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT library_id, root_path FROM libraries".to_string(),
        ))
        .await
        .map_err(map_db_err)?;
    rows.into_iter()
        .map(|row| {
            let library_id = row
                .try_get_by_index::<String>(0)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
            let root_path = row
                .try_get_by_index::<String>(1)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))?;
            Ok((library_id, root_path))
        })
        .collect()
}

async fn load_orphan_facets(db: &DatabaseConnection) -> Result<OrphanFacetsRecord, HentaiError> {
    Ok(OrphanFacetsRecord {
        tags: load_orphan_names(db, JunctionNamedFacet::Tag).await?,
        authors: load_orphan_names(db, JunctionNamedFacet::Author).await?,
        parodies: load_orphan_names(db, JunctionNamedFacet::Parody).await?,
        characters: load_orphan_names(db, JunctionNamedFacet::Character).await?,
    })
}

async fn load_orphan_names(
    db: &DatabaseConnection,
    facet: JunctionNamedFacet,
) -> Result<Vec<String>, HentaiError> {
    let dict = facet.dict_table();
    let junction = facet.junction_table();
    let name_col = facet.junction_name_column();
    let sql = format!(
        "SELECT d.name FROM {dict} d \
         WHERE NOT EXISTS (SELECT 1 FROM {junction} j WHERE j.{name_col} = d.name) \
         ORDER BY d.name COLLATE NOCASE ASC"
    );
    let rows = db
        .query_all(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            sql,
        ))
        .await
        .map_err(map_db_err)?;
    rows.into_iter()
        .map(|row| {
            row.try_get_by_index::<String>(0)
                .map_err(|e| HentaiError::db_query_failed(e.to_string(), None))
        })
        .collect()
}

fn utc_now_rfc3339() -> String {
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default();
    let total_secs = now.as_secs();
    let millis = now.subsec_millis();
    let days = total_secs / 86_400;
    let day_seconds = total_secs % 86_400;
    let hours = day_seconds / 3_600;
    let minutes = (day_seconds % 3_600) / 60;
    let seconds = day_seconds % 60;

    let (year, month, day) = civil_from_days(days as i64);
    format!("{year:04}-{month:02}-{day:02}T{hours:02}:{minutes:02}:{seconds:02}.{millis:03}Z")
}

/// Converts days since Unix epoch to (year, month, day) in UTC (civil calendar).
fn civil_from_days(days: i64) -> (i32, u32, u32) {
    let z = days + 719_468;
    let era = if z >= 0 { z } else { z - 146_096 } / 146_097;
    let doe = (z - era * 146_097) as u32;
    let yoe = (doe - doe / 1_460 + doe / 365 - doe / 1_460) / 365;
    let y = yoe as i32 + era as i32 * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let year = if m <= 2 { y + 1 } else { y };
    (year, m, d)
}
