use sea_orm::Value;

use super::dto::{ComicFilterDto, ComicSortFieldDto, ComicSortOptionDto};

pub struct PageSqlQuery {
    pub sql: String,
    pub values: Vec<Value>,
}

const COMIC_META_JOIN: &str = "INNER JOIN comic_meta m ON m.comic_id = c.comic_id";

pub fn build_count_query(filter: &ComicFilterDto) -> PageSqlQuery {
    let mut values = Vec::new();
    let where_clause = build_where_clause(filter, &mut values);
    PageSqlQuery {
        sql: format!(
            "SELECT COUNT(*) AS c FROM comics c {COMIC_META_JOIN} WHERE {where_clause}"
        ),
        values,
    }
}

pub fn build_ids_page_query(
    filter: &ComicFilterDto,
    sort: &ComicSortOptionDto,
    limit: i32,
    offset: i32,
) -> PageSqlQuery {
    let mut values = Vec::new();
    let where_clause = build_where_clause(filter, &mut values);
    let sort_join = sort_join_clause(sort.field);
    let order_by = build_order_by_clause(sort);
    values.push(Value::Int(Some(limit)));
    values.push(Value::Int(Some(offset)));
    PageSqlQuery {
        sql: format!(
            "SELECT c.comic_id AS comic_id FROM comics c {COMIC_META_JOIN}{sort_join} \
             WHERE {where_clause} \
             ORDER BY {order_by} \
             LIMIT ? OFFSET ?"
        ),
        values,
    }
}

fn sort_join_clause(field: ComicSortFieldDto) -> &'static str {
    match field {
        ComicSortFieldDto::ReadAt => {
            " LEFT JOIN comic_reading_histories rh ON rh.comic_id = c.comic_id"
        }
        _ => "",
    }
}

fn build_order_by_clause(sort: &ComicSortOptionDto) -> String {
    let direction = if sort.descending { "DESC" } else { "ASC" };
    let primary = match sort.field {
        ComicSortFieldDto::Title => format!("lower(m.title) {direction}"),
        ComicSortFieldDto::CreatedAt => format!("c.created_at {direction}"),
        ComicSortFieldDto::LastUpdatedAt => format!("c.last_updated_at {direction}"),
        ComicSortFieldDto::PublishedAt => format!("m.published_at {direction} NULLS LAST"),
        ComicSortFieldDto::ReadAt => format!("rh.last_read_time {direction} NULLS LAST"),
        ComicSortFieldDto::FileSize => format!("c.resource_size {direction}"),
        ComicSortFieldDto::PageCount => format!("m.page_count {direction}"),
    };
    format!("{primary}, lower(m.title) ASC")
}

fn build_where_clause(filter: &ComicFilterDto, values: &mut Vec<Value>) -> String {
    let mut parts = vec!["1=1".to_string()];
    if !filter.show_r18 {
        parts.push("m.content_rating != 'r18'".to_string());
    }
    if let Some(query) = &filter.query {
        let pattern = format!("%{query}%");
        parts.push(
            "(lower(m.title) LIKE ? OR EXISTS (\
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
        parts.push(format!("m.content_rating IN ({placeholders})"));
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
    std::iter::repeat_n("?", count)
        .collect::<Vec<_>>()
        .join(",")
}

fn push_sqlite_text(values: &mut Vec<Value>, text: String) {
    values.push(Value::String(Some(Box::new(text))));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn order_by_read_at_joins_history_and_nulls_last() {
        let sql = build_ids_page_query(
            &ComicFilterDto::default(),
            &ComicSortOptionDto {
                field: ComicSortFieldDto::ReadAt,
                descending: true,
            },
            20,
            0,
        );
        assert!(sql.sql.contains("LEFT JOIN comic_reading_histories rh"));
        assert!(sql.sql.contains("ORDER BY rh.last_read_time DESC NULLS LAST"));
        assert!(sql.sql.contains(", lower(m.title) ASC"));
    }

    #[test]
    fn order_by_page_count_asc() {
        let sql = build_ids_page_query(
            &ComicFilterDto::default(),
            &ComicSortOptionDto {
                field: ComicSortFieldDto::PageCount,
                descending: false,
            },
            10,
            5,
        );
        assert!(sql.sql.contains("ORDER BY m.page_count ASC, lower(m.title) ASC"));
        assert!(!sql.sql.contains("comic_reading_histories"));
    }

    #[test]
    fn order_by_published_at_nulls_last() {
        let sql = build_ids_page_query(
            &ComicFilterDto::default(),
            &ComicSortOptionDto {
                field: ComicSortFieldDto::PublishedAt,
                descending: false,
            },
            10,
            0,
        );
        assert!(sql.sql.contains("ORDER BY m.published_at ASC NULLS LAST"));
    }
}
