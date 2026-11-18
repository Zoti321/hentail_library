//! Image set catalog query (filter / sort / group / page), owned by the Image set library.
//!
//! SQL narrows by filter; order and Author grouping are applied in memory because display
//! name and relative path sort naturally, which SQLite collation cannot express.

use std::cmp::Ordering;
use std::collections::HashMap;

use sea_orm::{ConnectionTrait, DatabaseConnection, QueryResult, Statement, Value};

use crate::comic::{paginate, PageRequestDto};
use crate::db::{connection, map_db_err};
use crate::error::HentaiError;
use crate::metadata_lock::normalize_match_tokens;
use crate::named_facet::JunctionNamedFacet;
use crate::util::natural_sort::compare_filename_natural;

use super::dto::{
    ImageSetAuthorGroupDto, ImageSetCarrierShapeDto, ImageSetCatalogItemDto, ImageSetDto,
    ImageSetFacetFilterDto, ImageSetFilterDto, ImageSetGroupingDto, ImageSetSortFieldDto,
    ImageSetSortOptionDto, PagedImageSetCatalogDto,
};

const ROOT_ARCHIVE_SQL: &str = "EXISTS (SELECT 1 FROM image_set_carriers k \
     WHERE k.library_id = s.library_id AND k.carrier_relative_path = s.relative_path)";
const AUTHOR_BOUND_SQL: &str =
    "EXISTS (SELECT 1 FROM image_set_authors ja WHERE ja.image_set_id = s.image_set_id)";

/// One page of the Image set catalog. Out-of-range pages clamp to the last page.
pub async fn fetch_image_sets_page(
    request: PageRequestDto,
    filter: ImageSetFilterDto,
    sort: ImageSetSortOptionDto,
    grouping: ImageSetGroupingDto,
) -> Result<PagedImageSetCatalogDto, HentaiError> {
    let filter = normalized(filter);
    let db = connection()?;
    let mut items = load_items(&db, &filter).await?;
    items.sort_by(|a, b| compare_items(a, b, sort));
    if grouping == ImageSetGroupingDto::ByAuthor {
        items = group_by_author(&db, &filter, items).await?;
    }
    let total_count = items.len() as i64;
    let window = paginate(request, total_count).clamped();
    if total_count == 0 {
        return Ok(PagedImageSetCatalogDto {
            items: vec![],
            total_count,
            page: 1,
            page_size: window.page_size,
        });
    }
    let items = items
        .into_iter()
        .skip(window.offset as usize)
        .take(window.page_size as usize)
        .collect();
    Ok(PagedImageSetCatalogDto {
        items,
        total_count,
        page: window.page,
        page_size: window.page_size,
    })
}

fn normalized(filter: ImageSetFilterDto) -> ImageSetFilterDto {
    let facet = |f: ImageSetFacetFilterDto| ImageSetFacetFilterDto {
        any: normalize_match_tokens(&f.any),
        unassigned: f.unassigned,
    };
    ImageSetFilterDto {
        library_id: filter.library_id.trim().to_string(),
        authors: facet(filter.authors),
        tags: facet(filter.tags),
        parodies: facet(filter.parodies),
        characters: facet(filter.characters),
        ..filter
    }
}

async fn load_items(
    db: &DatabaseConnection,
    filter: &ImageSetFilterDto,
) -> Result<Vec<ImageSetCatalogItemDto>, HentaiError> {
    let mut values = vec![text(&filter.library_id)];
    let where_clause = where_clause(filter, &mut values);
    let sql = format!(
        "SELECT s.image_set_id, s.library_id, s.relative_path, s.name, s.is_root, s.name_locked, \
         s.created_at, \
         (SELECT COUNT(*) FROM image_set_images i WHERE i.image_set_id = s.image_set_id) AS image_count, \
         {ROOT_ARCHIVE_SQL} AS root_archive \
         FROM image_sets s WHERE {where_clause}"
    );
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            sql,
            values,
        ))
        .await
        .map_err(map_db_err)?;
    rows.iter().map(item_from_row).collect()
}

fn item_from_row(row: &QueryResult) -> Result<ImageSetCatalogItemDto, HentaiError> {
    let get_err = |e: sea_orm::DbErr| HentaiError::db_query_failed(e.to_string(), None);
    let root_archive: bool = row.try_get("", "root_archive").map_err(get_err)?;
    Ok(ImageSetCatalogItemDto {
        image_set: ImageSetDto {
            image_set_id: row.try_get("", "image_set_id").map_err(get_err)?,
            library_id: row.try_get("", "library_id").map_err(get_err)?,
            relative_path: row.try_get("", "relative_path").map_err(get_err)?,
            name: row.try_get("", "name").map_err(get_err)?,
            is_root: row.try_get("", "is_root").map_err(get_err)?,
            name_locked: row.try_get("", "name_locked").map_err(get_err)?,
        },
        image_count: row.try_get("", "image_count").map_err(get_err)?,
        created_at: row.try_get("", "created_at").map_err(get_err)?,
        carrier_shape: if root_archive {
            ImageSetCarrierShapeDto::RootArchive
        } else {
            ImageSetCarrierShapeDto::Directory
        },
        group_author: None,
    })
}

fn where_clause(filter: &ImageSetFilterDto, values: &mut Vec<Value>) -> String {
    let mut parts = vec!["s.library_id = ?".to_string()];
    push_facet(
        &mut parts,
        values,
        &filter.authors,
        |ph| {
            format!(
                "EXISTS (SELECT 1 FROM image_set_authors ja \
                 INNER JOIN authors au ON au.id = ja.author_id \
                 WHERE ja.image_set_id = s.image_set_id AND lower(au.name) IN ({ph}))"
            )
        },
        AUTHOR_BOUND_SQL,
    );
    for (facet, bucket) in [
        (JunctionNamedFacet::Tag, &filter.tags),
        (JunctionNamedFacet::Parody, &filter.parodies),
        (JunctionNamedFacet::Character, &filter.characters),
    ] {
        let junction = facet.image_set_junction_table();
        let name_col = facet.junction_name_column();
        let bound =
            format!("EXISTS (SELECT 1 FROM {junction} j WHERE j.image_set_id = s.image_set_id");
        push_facet(
            &mut parts,
            values,
            bucket,
            |ph| format!("{bound} AND lower(j.{name_col}) IN ({ph}))"),
            &format!("{bound})"),
        );
    }
    match filter.carrier_shape {
        Some(ImageSetCarrierShapeDto::RootArchive) => parts.push(ROOT_ARCHIVE_SQL.to_string()),
        Some(ImageSetCarrierShapeDto::Directory) => parts.push(format!("NOT {ROOT_ARCHIVE_SQL}")),
        None => {}
    }
    if filter.require_images {
        parts.push(
            "EXISTS (SELECT 1 FROM image_set_images i WHERE i.image_set_id = s.image_set_id)"
                .to_string(),
        );
    }
    parts.join(" AND ")
}

/// `any_sql` renders the name match for the given `IN` placeholders; `bound_sql` tests for any binding.
fn push_facet(
    parts: &mut Vec<String>,
    values: &mut Vec<Value>,
    bucket: &ImageSetFacetFilterDto,
    any_sql: impl Fn(&str) -> String,
    bound_sql: &str,
) {
    let mut alternatives = Vec::new();
    if !bucket.any.is_empty() {
        alternatives.push(any_sql(&vec!["?"; bucket.any.len()].join(",")));
        values.extend(bucket.any.iter().map(|name| text(name)));
    }
    if bucket.unassigned {
        alternatives.push(format!("NOT {bound_sql}"));
    }
    if !alternatives.is_empty() {
        parts.push(format!("({})", alternatives.join(" OR ")));
    }
}

fn compare_items(
    a: &ImageSetCatalogItemDto,
    b: &ImageSetCatalogItemDto,
    sort: ImageSetSortOptionDto,
) -> Ordering {
    let by_name = || compare_filename_natural(&a.image_set.name, &b.image_set.name);
    let by_path =
        || compare_filename_natural(&a.image_set.relative_path, &b.image_set.relative_path);
    let primary = match sort.field {
        ImageSetSortFieldDto::Name => by_name(),
        ImageSetSortFieldDto::ImageCount => a.image_count.cmp(&b.image_count),
        ImageSetSortFieldDto::CreatedAt => a.created_at.cmp(&b.created_at),
        ImageSetSortFieldDto::RelativePath => by_path(),
    };
    let primary = if sort.descending {
        primary.reverse()
    } else {
        primary
    };
    primary
        .then_with(by_name)
        .then_with(by_path)
        .then_with(|| a.image_set.image_set_id.cmp(&b.image_set.image_set_id))
}

/// Expands sorted items into Author groups; group membership is any bound Author matching the
/// Author filter (all bound Authors when that filter names none).
async fn group_by_author(
    db: &DatabaseConnection,
    filter: &ImageSetFilterDto,
    items: Vec<ImageSetCatalogItemDto>,
) -> Result<Vec<ImageSetCatalogItemDto>, HentaiError> {
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT ja.image_set_id, au.id, au.name FROM image_set_authors ja \
             INNER JOIN authors au ON au.id = ja.author_id \
             INNER JOIN image_sets s ON s.image_set_id = ja.image_set_id \
             WHERE s.library_id = ?",
            [text(&filter.library_id)],
        ))
        .await
        .map_err(map_db_err)?;
    let mut authors_by_set: HashMap<String, Vec<ImageSetAuthorGroupDto>> = HashMap::new();
    for row in rows {
        let get_err = |e: sea_orm::DbErr| HentaiError::db_query_failed(e.to_string(), None);
        let set_id: String = row.try_get_by_index(0).map_err(get_err)?;
        authors_by_set
            .entry(set_id)
            .or_default()
            .push(ImageSetAuthorGroupDto {
                author_id: row.try_get_by_index(1).map_err(get_err)?,
                name: row.try_get_by_index(2).map_err(get_err)?,
            });
    }
    let mut groups: Vec<(Option<ImageSetAuthorGroupDto>, ImageSetCatalogItemDto)> = Vec::new();
    for item in items {
        let bound = authors_by_set
            .get(&item.image_set.image_set_id)
            .map(Vec::as_slice)
            .unwrap_or(&[]);
        if bound.is_empty() {
            groups.push((None, item));
            continue;
        }
        for author in bound.iter().filter(|author| {
            filter.authors.any.is_empty()
                || filter.authors.any.contains(&author.name.to_lowercase())
        }) {
            groups.push((Some(author.clone()), item.clone()));
        }
    }
    // Stable sort keeps the user order inside each group.
    groups.sort_by(|(a, _), (b, _)| match (a, b) {
        (Some(a), Some(b)) => {
            compare_filename_natural(&a.name, &b.name).then_with(|| a.author_id.cmp(&b.author_id))
        }
        (Some(_), None) => Ordering::Less,
        (None, Some(_)) => Ordering::Greater,
        (None, None) => Ordering::Equal,
    });
    Ok(groups
        .into_iter()
        .map(|(group_author, item)| ImageSetCatalogItemDto {
            group_author,
            ..item
        })
        .collect())
}

fn text(value: &str) -> Value {
    Value::String(Some(Box::new(value.to_string())))
}
