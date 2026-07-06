use sea_orm::Value;

use super::dto::{SeriesFilterDto, SeriesSortFieldDto, SeriesSortOptionDto};

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
    sort: &SeriesSortOptionDto,
    limit: i32,
    offset: i32,
) -> PageSqlQuery {
    let mut values = Vec::new();
    let where_clause = build_where_clause(filter, &mut values);
    let order_by = build_order_by_clause(sort, &mut values);
    values.push(Value::Int(Some(limit)));
    values.push(Value::Int(Some(offset)));
    PageSqlQuery {
        sql: format!(
            "SELECT s.series_id FROM series s \
             WHERE {where_clause} \
             ORDER BY {order_by} \
             LIMIT ? OFFSET ?"
        ),
        values,
    }
}

fn build_order_by_clause(sort: &SeriesSortOptionDto, _values: &mut Vec<Value>) -> String {
    match sort.field {
        SeriesSortFieldDto::Name => {
            let direction = if sort.descending { "DESC" } else { "ASC" };
            format!("lower(s.name) {direction}, s.series_id ASC")
        }
        SeriesSortFieldDto::ComicCount => {
            let direction = if sort.descending { "DESC" } else { "ASC" };
            format!(
                "(SELECT COUNT(*) FROM series_items si WHERE si.series_id = s.series_id) {direction}, \
                 lower(s.name) ASC, s.series_id ASC"
            )
        }
        SeriesSortFieldDto::Random => {
            let direction = if sort.descending { "DESC" } else { "ASC" };
            format!("RANDOM() {direction}, s.series_id ASC")
        }
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn random_order_uses_sql_random() {
        let query = build_ids_page_query(
            &SeriesFilterDto::default(),
            &SeriesSortOptionDto {
                field: SeriesSortFieldDto::Random,
                descending: true,
                ..Default::default()
            },
            20,
            0,
        );
        assert!(query.sql.contains("RANDOM() DESC"));
        assert_eq!(query.values.len(), 2);
    }

    #[test]
    fn comic_count_order_respects_descending_flag() {
        let query = build_ids_page_query(
            &SeriesFilterDto::default(),
            &SeriesSortOptionDto {
                field: SeriesSortFieldDto::ComicCount,
                descending: true,
                ..Default::default()
            },
            10,
            0,
        );
        assert!(query.sql.contains("COUNT(*)"));
        assert!(query.sql.contains("DESC"));
    }
}
