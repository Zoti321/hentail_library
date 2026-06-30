use sea_orm::Value;

use super::dto::ComicFilterDto;

pub struct PageSqlQuery {
    pub sql: String,
    pub values: Vec<Value>,
}

pub fn build_count_query(filter: &ComicFilterDto) -> PageSqlQuery {
    let mut values = Vec::new();
    let where_clause = build_where_clause(filter, &mut values);
    PageSqlQuery {
        sql: format!("SELECT COUNT(*) AS c FROM comics c WHERE {where_clause}"),
        values,
    }
}

pub fn build_ids_page_query(
    filter: &ComicFilterDto,
    sort_descending: bool,
    limit: i32,
    offset: i32,
) -> PageSqlQuery {
    let mut values = Vec::new();
    let where_clause = build_where_clause(filter, &mut values);
    let order = if sort_descending { "DESC" } else { "ASC" };
    values.push(Value::Int(Some(limit)));
    values.push(Value::Int(Some(offset)));
    PageSqlQuery {
        sql: format!(
            "SELECT c.comic_id AS comic_id FROM comics c \
             WHERE {where_clause} \
             ORDER BY lower(c.title) {order} \
             LIMIT ? OFFSET ?"
        ),
        values,
    }
}

fn build_where_clause(filter: &ComicFilterDto, values: &mut Vec<Value>) -> String {
    let mut parts = vec!["1=1".to_string()];
    if !filter.show_r18 {
        parts.push("c.content_rating != 'r18'".to_string());
    }
    if let Some(query) = &filter.query {
        let pattern = format!("%{query}%");
        parts.push(
            "(lower(c.title) LIKE ? OR EXISTS (\
             SELECT 1 FROM comic_authors ca \
             WHERE ca.comic_id = c.comic_id AND lower(ca.author_name) LIKE ?))"
                .to_string(),
        );
        push_sqlite_text(values, pattern.clone());
        push_sqlite_text(values, pattern);
    }
    if !filter.resource_types.is_empty() {
        let placeholders = placeholders(filter.resource_types.len());
        parts.push(format!("c.resource_type IN ({placeholders})"));
        for rt in &filter.resource_types {
            push_sqlite_text(values, rt.clone());
        }
    }
    if !filter.content_ratings.is_empty() {
        let placeholders = placeholders(filter.content_ratings.len());
        parts.push(format!("c.content_rating IN ({placeholders})"));
        for rating in &filter.content_ratings {
            push_sqlite_text(values, rating.clone());
        }
    }
    for tag in &filter.tags_all {
        parts.push(
            "EXISTS (SELECT 1 FROM comic_tags ct \
             WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) = ?)"
                .to_string(),
        );
        push_sqlite_text(values, tag.clone());
    }
    if !filter.tags_any.is_empty() {
        let placeholders = placeholders(filter.tags_any.len());
        parts.push(format!(
            "EXISTS (SELECT 1 FROM comic_tags ct \
             WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) IN ({placeholders}))"
        ));
        for tag in &filter.tags_any {
            push_sqlite_text(values, tag.clone());
        }
    }
    if !filter.tags_exclude.is_empty() {
        let placeholders = placeholders(filter.tags_exclude.len());
        parts.push(format!(
            "NOT EXISTS (SELECT 1 FROM comic_tags ct \
             WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) IN ({placeholders}))"
        ));
        for tag in &filter.tags_exclude {
            push_sqlite_text(values, tag.clone());
        }
    }
    if filter.exclude_comics_in_any_series {
        parts.push(
            "NOT EXISTS (SELECT 1 FROM series_items si WHERE si.comic_id = c.comic_id)"
                .to_string(),
        );
    }
    parts.join(" AND ")
}

fn placeholders(count: usize) -> String {
    std::iter::repeat("?")
        .take(count)
        .collect::<Vec<_>>()
        .join(",")
}

fn push_sqlite_text(values: &mut Vec<Value>, text: String) {
    values.push(Value::String(Some(Box::new(text))));
}