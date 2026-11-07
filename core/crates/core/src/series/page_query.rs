use sea_orm::Value;

use super::dto::{SeriesFilterDto, SeriesSortFieldDto, SeriesSortOptionDto};
use super::grouping::SeriesGrouping;
use crate::comic::visibility::{
    series_browsable_sql, series_has_visible_member_sql, visible_comic_sql,
};

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
    grouping: SeriesGrouping,
    prefer_root_folder_path: Option<&str>,
    limit: i32,
    offset: i32,
) -> PageSqlQuery {
    let mut values = Vec::new();
    let where_clause = build_where_clause(filter, &mut values);
    let order_by = build_order_by_clause(sort, grouping, prefer_root_folder_path, &mut values);
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

fn build_order_by_clause(
    sort: &SeriesSortOptionDto,
    grouping: SeriesGrouping,
    prefer_root_folder_path: Option<&str>,
    values: &mut Vec<Value>,
) -> String {
    let secondary = user_sort_order_by(sort);
    let mut parts: Vec<String> = Vec::new();
    if let Some(root) = prefer_root_folder_path {
        push_sqlite_text(values, root.to_string());
        parts.push("CASE WHEN s.folder_path = ? THEN 0 ELSE 1 END ASC".to_string());
    }
    if let Some(prefix) = grouping.order_prefix() {
        parts.push(prefix.to_string());
    }
    parts.push(secondary);
    parts.join(", ")
}

fn user_sort_order_by(sort: &SeriesSortOptionDto) -> String {
    match sort.field {
        SeriesSortFieldDto::Name => {
            let direction = if sort.descending { "DESC" } else { "ASC" };
            format!("s.name_sort_key {direction}, s.series_id ASC")
        }
        SeriesSortFieldDto::ComicCount => {
            let direction = if sort.descending { "DESC" } else { "ASC" };
            format!(
                "(SELECT COUNT(*) FROM series_items si \
                 INNER JOIN comics sc ON sc.comic_id = si.comic_id \
                 WHERE si.series_id = s.series_id AND {}) {direction}, \
                 s.name_sort_key ASC, s.series_id ASC",
                visible_comic_sql("sc")
            )
        }
        SeriesSortFieldDto::Random => {
            let direction = if sort.descending { "DESC" } else { "ASC" };
            format!("RANDOM() {direction}, s.series_id ASC")
        }
    }
}

fn build_where_clause(filter: &SeriesFilterDto, values: &mut Vec<Value>) -> String {
    let mut parts = vec![series_browsable_sql("s.series_id")];
    if let Some(library_id) = &filter.library_id {
        parts.push("s.library_id = ?".to_string());
        push_sqlite_text(values, library_id.clone());
    }
    if filter.require_items {
        parts.push(series_has_visible_member_sql("s.series_id"));
    }
    let visible_r18_member = format!(
        "EXISTS (\
         SELECT 1 FROM series_items si \
         INNER JOIN comics sc ON sc.comic_id = si.comic_id \
         INNER JOIN comic_meta cm ON cm.comic_id = si.comic_id \
         WHERE si.series_id = s.series_id AND {} \
         AND cm.content_rating = 'r18')",
        visible_comic_sql("sc")
    );
    if filter.r18_only {
        parts.push(visible_r18_member);
    } else if !filter.show_r18 {
        parts.push(format!("NOT {visible_r18_member}"));
    }
    if let Some(query) = &filter.query {
        parts.push("(lower(s.name) LIKE ? OR lower(s.folder_path) LIKE ?)".to_string());
        push_sqlite_text(values, format!("%{query}%"));
        push_sqlite_text(values, format!("%{query}%"));
    }
    if let Some(status) = &filter.serialization_status {
        parts.push("s.serialization_status = ?".to_string());
        push_sqlite_text(values, status.clone());
    }
    parts.join(" AND ")
}

fn push_sqlite_text(values: &mut Vec<Value>, text: String) {
    values.push(Value::String(Some(Box::new(text))));
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::series::grouping::SeriesGrouping;

    #[test]
    fn random_order_uses_sql_random() {
        let query = build_ids_page_query(
            &SeriesFilterDto::default(),
            &SeriesSortOptionDto {
                field: SeriesSortFieldDto::Random,
                descending: true,
            },
            SeriesGrouping::None,
            None,
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
            },
            SeriesGrouping::None,
            None,
            10,
            0,
        );
        assert!(query.sql.contains("COUNT(*)"));
        assert!(query.sql.contains("DESC"));
    }

    #[test]
    fn prefer_root_folder_path_prefixes_order_by_case() {
        let query = build_ids_page_query(
            &SeriesFilterDto::default(),
            &SeriesSortOptionDto {
                field: SeriesSortFieldDto::Name,
                descending: false,
            },
            SeriesGrouping::None,
            Some("E:/lib"),
            20,
            0,
        );
        assert!(query
            .sql
            .contains("CASE WHEN s.folder_path = ? THEN 0 ELSE 1 END ASC"));
        assert!(query.sql.contains("s.name_sort_key ASC"));
        // prefer root path is bound before LIMIT/OFFSET
        assert_eq!(query.values.len(), 3);
        match &query.values[0] {
            Value::String(Some(s)) => assert_eq!(s.as_str(), "E:/lib"),
            other => panic!("expected root path binding, got {other:?}"),
        }
    }

    #[test]
    fn without_prefer_root_folder_path_keeps_plain_order() {
        let query = build_ids_page_query(
            &SeriesFilterDto::default(),
            &SeriesSortOptionDto {
                field: SeriesSortFieldDto::Name,
                descending: false,
            },
            SeriesGrouping::None,
            None,
            20,
            0,
        );
        assert!(!query.sql.contains("CASE WHEN s.folder_path"));
        assert_eq!(query.values.len(), 2);
    }

    #[test]
    fn by_serialization_status_grouping_prefixes_order_by() {
        let query = build_ids_page_query(
            &SeriesFilterDto::default(),
            &SeriesSortOptionDto::default(),
            SeriesGrouping::BySerializationStatus,
            None,
            10,
            0,
        );
        assert!(query.sql.contains("s.serialization_status"));
        assert!(query.sql.contains("'ongoing'"));
    }
}
