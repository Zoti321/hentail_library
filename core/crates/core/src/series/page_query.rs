use sea_orm::Value;

use super::dto::SeriesFilterDto;

pub struct PageSqlQuery {
    pub sql: String,
    pub values: Vec<Value>,
}

pub fn build_count_query(filter: &SeriesFilterDto) -> PageSqlQuery {
    let mut values = Vec::new();
    let where_clause = build_where_clause(filter, &mut values);
    PageSqlQuery {
        sql: format!("SELECT COUNT(*) AS c FROM series s WHERE {where_clause}"),
        values,
    }
}

pub fn build_ids_page_query(
    filter: &SeriesFilterDto,
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
            "SELECT s.series_id FROM series s \
             WHERE {where_clause} \
             ORDER BY lower(s.name) {order} \
             LIMIT ? OFFSET ?"
        ),
        values,
    }
}

fn build_where_clause(filter: &SeriesFilterDto, values: &mut Vec<Value>) -> String {
    let mut parts = vec!["1=1".to_string()];
    if filter.require_items {
        parts.push(
            "EXISTS (SELECT 1 FROM series_items si WHERE si.series_id = s.series_id)".to_string(),
        );
    }
    if filter.r18_only {
        parts.push(
            "EXISTS (\
             SELECT 1 FROM series_items si \
             INNER JOIN comic_meta cm ON cm.comic_id = si.comic_id \
             WHERE si.series_id = s.series_id AND cm.content_rating = 'r18')"
                .to_string(),
        );
    } else if !filter.show_r18 {
        parts.push(
            "NOT EXISTS (\
             SELECT 1 FROM series_items si \
             INNER JOIN comic_meta cm ON cm.comic_id = si.comic_id \
             WHERE si.series_id = s.series_id AND cm.content_rating = 'r18')"
                .to_string(),
        );
    }
    if let Some(query) = &filter.query {
        parts.push("(lower(s.name) LIKE ? OR lower(s.folder_path) LIKE ?)".to_string());
        push_sqlite_text(values, format!("%{query}%"));
        push_sqlite_text(values, format!("%{query}%"));
    }
    parts.join(" AND ")
}

fn push_sqlite_text(values: &mut Vec<Value>, text: String) {
    values.push(Value::String(Some(Box::new(text))));
}
