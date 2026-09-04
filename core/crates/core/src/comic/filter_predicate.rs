//! Typed Comic name-facet SQL predicates shared by catalog page query and
//! metadata-expression search.
//!
//! Catalog composes **typed buckets** (Tag/Author all|any|exclude, L/P/C include).
//! Search composes **cross-facet** OR of the same helpers per token.

use sea_orm::Value;

use super::dto::ComicFilterDto;

/// Name facets attached to a Comic (junction tables or `comic_meta.languages` JSON).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ComicNameFacet {
    Tag,
    Author,
    Parody,
    Character,
    Language,
}

const ALL_NAME_FACETS: [ComicNameFacet; 5] = [
    ComicNameFacet::Tag,
    ComicNameFacet::Author,
    ComicNameFacet::Parody,
    ComicNameFacet::Character,
    ComicNameFacet::Language,
];

impl ComicNameFacet {
    fn exists_eq_sql(self) -> &'static str {
        match self {
            Self::Tag => {
                "EXISTS (SELECT 1 FROM comic_tags ct \
                 WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) = ?)"
            }
            Self::Author => {
                "EXISTS (SELECT 1 FROM comic_authors ca \
                 WHERE ca.comic_id = c.comic_id AND lower(ca.author_name) = ?)"
            }
            Self::Parody => {
                "EXISTS (SELECT 1 FROM comic_parodies cp \
                 WHERE cp.comic_id = c.comic_id AND lower(cp.parody_name) = ?)"
            }
            Self::Character => {
                "EXISTS (SELECT 1 FROM comic_characters cc \
                 WHERE cc.comic_id = c.comic_id AND lower(cc.character_name) = ?)"
            }
            Self::Language => {
                "EXISTS (SELECT 1 FROM json_each(m.languages) je \
                 WHERE lower(je.value) = ?)"
            }
        }
    }

    fn exists_in_sql(self, placeholders: &str) -> String {
        match self {
            Self::Tag => format!(
                "EXISTS (SELECT 1 FROM comic_tags ct \
                 WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) IN ({placeholders}))"
            ),
            Self::Author => format!(
                "EXISTS (SELECT 1 FROM comic_authors ca \
                 WHERE ca.comic_id = c.comic_id AND lower(ca.author_name) IN ({placeholders}))"
            ),
            Self::Parody => format!(
                "EXISTS (SELECT 1 FROM comic_parodies cp \
                 WHERE cp.comic_id = c.comic_id AND lower(cp.parody_name) IN ({placeholders}))"
            ),
            Self::Character => format!(
                "EXISTS (SELECT 1 FROM comic_characters cc \
                 WHERE cc.comic_id = c.comic_id AND lower(cc.character_name) IN ({placeholders}))"
            ),
            Self::Language => format!(
                "EXISTS (SELECT 1 FROM json_each(m.languages) je \
                 WHERE lower(je.value) IN ({placeholders}))"
            ),
        }
    }

    fn not_exists_in_sql(self, placeholders: &str) -> String {
        format!("NOT {}", self.exists_in_sql(placeholders))
    }
}

fn placeholders(count: usize) -> String {
    std::iter::repeat_n("?", count)
        .collect::<Vec<_>>()
        .join(",")
}

fn push_sqlite_text(values: &mut Vec<Value>, text: String) {
    values.push(Value::String(Some(Box::new(text))));
}

fn push_facet_eq(parts: &mut Vec<String>, values: &mut Vec<Value>, facet: ComicNameFacet, name: &str) {
    parts.push(facet.exists_eq_sql().to_string());
    push_sqlite_text(values, name.to_string());
}

fn push_facet_any_in(
    parts: &mut Vec<String>,
    values: &mut Vec<Value>,
    facet: ComicNameFacet,
    names: &[String],
) {
    if names.is_empty() {
        return;
    }
    let ph = placeholders(names.len());
    parts.push(facet.exists_in_sql(&ph));
    for name in names {
        push_sqlite_text(values, name.clone());
    }
}

fn push_facet_exclude_in(
    parts: &mut Vec<String>,
    values: &mut Vec<Value>,
    facet: ComicNameFacet,
    names: &[String],
) {
    if names.is_empty() {
        return;
    }
    let ph = placeholders(names.len());
    parts.push(facet.not_exists_in_sql(&ph));
    for name in names {
        push_sqlite_text(values, name.clone());
    }
}

/// Catalog page / count WHERE (AND-combined predicates).
pub(super) fn build_catalog_where_clause(filter: &ComicFilterDto, values: &mut Vec<Value>) -> String {
    let mut parts = vec!["1=1".to_string()];
    if let Some(library_id) = &filter.library_id {
        parts.push("c.library_id = ?".to_string());
        push_sqlite_text(values, library_id.clone());
    }
    if !filter.show_r18 {
        parts.push("m.content_rating != 'r18'".to_string());
    }
    if let Some(query) = &filter.query {
        let pattern = format!("%{query}%");
        parts.push(
            "(lower(m.title) LIKE ? OR EXISTS (\
             SELECT 1 FROM comic_authors ca \
             WHERE ca.comic_id = c.comic_id AND lower(ca.author_name) LIKE ?) OR EXISTS (\
             SELECT 1 FROM comic_parodies cp \
             WHERE cp.comic_id = c.comic_id AND lower(cp.parody_name) LIKE ?) OR EXISTS (\
             SELECT 1 FROM comic_characters cc \
             WHERE cc.comic_id = c.comic_id AND lower(cc.character_name) LIKE ?))"
                .to_string(),
        );
        push_sqlite_text(values, pattern.clone());
        push_sqlite_text(values, pattern.clone());
        push_sqlite_text(values, pattern.clone());
        push_sqlite_text(values, pattern);
    }
    if !filter.resource_types.is_empty() {
        let ph = placeholders(filter.resource_types.len());
        parts.push(format!("c.resource_type IN ({ph})"));
        for rt in &filter.resource_types {
            push_sqlite_text(values, rt.clone());
        }
    }
    if !filter.content_ratings.is_empty() {
        let ph = placeholders(filter.content_ratings.len());
        parts.push(format!("m.content_rating IN ({ph})"));
        for rating in &filter.content_ratings {
            push_sqlite_text(values, rating.clone());
        }
    }
    for tag in &filter.tags_all {
        push_facet_eq(&mut parts, values, ComicNameFacet::Tag, tag);
    }
    push_facet_any_in(&mut parts, values, ComicNameFacet::Tag, &filter.tags_any);
    push_facet_exclude_in(&mut parts, values, ComicNameFacet::Tag, &filter.tags_exclude);
    for author in &filter.authors_all {
        push_facet_eq(&mut parts, values, ComicNameFacet::Author, author);
    }
    push_facet_any_in(
        &mut parts,
        values,
        ComicNameFacet::Author,
        &filter.authors_any,
    );
    push_facet_exclude_in(
        &mut parts,
        values,
        ComicNameFacet::Author,
        &filter.authors_exclude,
    );
    push_facet_any_in(
        &mut parts,
        values,
        ComicNameFacet::Language,
        &filter.languages,
    );
    push_facet_any_in(&mut parts, values, ComicNameFacet::Parody, &filter.parodies);
    push_facet_any_in(
        &mut parts,
        values,
        ComicNameFacet::Character,
        &filter.characters,
    );
    parts.join(" AND ")
}

/// Append metadata-expression predicates onto an existing `WHERE …` SQL string.
///
/// Each `must_include` token matches **any** name facet (OR).
/// `optional_or` is one OR-group across facets.
/// `must_exclude` applies NOT EXISTS on **each** facet (AND).
pub(super) fn append_metadata_expression_predicates(
    sql: &mut String,
    values: &mut Vec<Value>,
    must_include: &[String],
    optional_or: &[String],
    must_exclude: &[String],
) {
    for name in must_include {
        let mut or_parts = Vec::new();
        for facet in ALL_NAME_FACETS {
            or_parts.push(facet.exists_eq_sql().to_string());
            push_sqlite_text(values, name.clone());
        }
        sql.push_str(" AND (");
        sql.push_str(&or_parts.join(" OR "));
        sql.push(')');
    }
    if !optional_or.is_empty() {
        let ph = placeholders(optional_or.len());
        let mut or_parts = Vec::new();
        for facet in ALL_NAME_FACETS {
            or_parts.push(facet.exists_in_sql(&ph));
            for name in optional_or {
                push_sqlite_text(values, name.clone());
            }
        }
        sql.push_str(" AND (");
        sql.push_str(&or_parts.join(" OR "));
        sql.push(')');
    }
    if !must_exclude.is_empty() {
        let ph = placeholders(must_exclude.len());
        for facet in ALL_NAME_FACETS {
            sql.push_str(" AND ");
            sql.push_str(&facet.not_exists_in_sql(&ph));
            for name in must_exclude {
                push_sqlite_text(values, name.clone());
            }
        }
    }
}

/// Build only the predicate suffix for unit tests (starts with empty base).
fn build_metadata_expression_predicate_sql(
    must_include: &[String],
    optional_or: &[String],
    must_exclude: &[String],
) -> (String, Vec<Value>) {
    let mut sql = String::new();
    let mut values = Vec::new();
    append_metadata_expression_predicates(
        &mut sql,
        &mut values,
        must_include,
        optional_or,
        must_exclude,
    );
    (sql, values)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn catalog_where_tags_all_any_exclude() {
        let mut values = Vec::new();
        let sql = build_catalog_where_clause(
            &ComicFilterDto {
                tags_all: vec!["a".to_string()],
                tags_any: vec!["b".to_string(), "c".to_string()],
                tags_exclude: vec!["d".to_string()],
                ..Default::default()
            },
            &mut values,
        );
        assert!(sql.contains("lower(ct.tag_name) = ?"));
        assert!(sql.contains("lower(ct.tag_name) IN (?,?)"));
        assert!(sql.contains("NOT EXISTS (SELECT 1 FROM comic_tags"));
        assert_eq!(values.len(), 4);
    }

    #[test]
    fn catalog_where_languages_parodies_characters() {
        let mut values = Vec::new();
        let sql = build_catalog_where_clause(
            &ComicFilterDto {
                languages: vec!["chinese".to_string()],
                parodies: vec!["naruto".to_string()],
                characters: vec!["sakura".to_string()],
                ..Default::default()
            },
            &mut values,
        );
        assert!(sql.contains("json_each(m.languages)"));
        assert!(sql.contains("comic_parodies"));
        assert!(sql.contains("comic_characters"));
        assert_eq!(values.len(), 3);
    }

    #[test]
    fn metadata_expression_must_include_ors_across_facets() {
        let (sql, values) =
            build_metadata_expression_predicate_sql(&["yuri".to_string()], &[], &[]);
        assert!(sql.contains("comic_tags"));
        assert!(sql.contains("comic_authors"));
        assert!(sql.contains("comic_parodies"));
        assert!(sql.contains("comic_characters"));
        assert!(sql.contains("json_each(m.languages)"));
        assert!(sql.matches(" OR ").count() >= 4);
        assert_eq!(values.len(), 5);
        assert!(values.iter().all(|v| matches!(
            v,
            Value::String(Some(s)) if s.as_str() == "yuri"
        )));
    }

    #[test]
    fn metadata_expression_optional_and_exclude_shapes() {
        let (sql, values) = build_metadata_expression_predicate_sql(
            &[],
            &["a".to_string(), "b".to_string()],
            &["x".to_string()],
        );
        assert!(sql.contains("IN (?,?)"));
        assert!(sql.contains("NOT EXISTS (SELECT 1 FROM comic_tags"));
        assert!(sql.contains("NOT EXISTS (SELECT 1 FROM comic_authors"));
        // optional: 5 facets × 2 names; exclude: 5 facets × 1 name
        assert_eq!(values.len(), 5 * 2 + 5);
    }

    #[test]
    fn catalog_tag_eq_reuses_same_helper_sql_as_search_include() {
        let mut catalog_values = Vec::new();
        let catalog = build_catalog_where_clause(
            &ComicFilterDto {
                tags_all: vec!["solo".to_string()],
                ..Default::default()
            },
            &mut catalog_values,
        );
        let (search, _) =
            build_metadata_expression_predicate_sql(&["solo".to_string()], &[], &[]);
        assert!(catalog.contains(ComicNameFacet::Tag.exists_eq_sql()));
        assert!(search.contains(ComicNameFacet::Tag.exists_eq_sql()));
    }
}
