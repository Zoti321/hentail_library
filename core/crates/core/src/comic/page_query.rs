use sea_orm::Value;

use super::dto::{ComicFilterDto, ComicSortOptionDto};
use super::filter_predicate::build_catalog_where_clause;
use super::grouping::ComicGrouping;

pub struct PageSqlQuery {
    pub sql: String,
    pub values: Vec<Value>,
}

const COMIC_META_JOIN: &str = "INNER JOIN comic_meta m ON m.comic_id = c.comic_id";

pub fn build_count_query(filter: &ComicFilterDto) -> PageSqlQuery {
    let mut values = Vec::new();
    let where_clause = build_catalog_where_clause(filter, &mut values);
    PageSqlQuery {
        sql: format!("SELECT COUNT(*) AS c FROM comics c {COMIC_META_JOIN} WHERE {where_clause}"),
        values,
    }
}

pub fn build_ids_page_query(
    filter: &ComicFilterDto,
    sort: &ComicSortOptionDto,
    grouping: ComicGrouping,
    library_root_path: Option<&str>,
    limit: i32,
    offset: i32,
) -> PageSqlQuery {
    let mut values = Vec::new();
    let where_clause = build_catalog_where_clause(filter, &mut values);
    let join_clause = grouping.join_clause(sort.field);
    let order_by = grouping.order_by(sort, library_root_path, &mut values);
    values.push(Value::Int(Some(limit)));
    values.push(Value::Int(Some(offset)));
    PageSqlQuery {
        sql: format!(
            "SELECT c.comic_id AS comic_id FROM comics c {COMIC_META_JOIN}{join_clause}              WHERE {where_clause}              ORDER BY {order_by}              LIMIT ? OFFSET ?"
        ),
        values,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::comic::dto::ComicSortFieldDto;

    #[test]
    fn order_by_read_at_joins_history_and_nulls_last() {
        let sql = build_ids_page_query(
            &ComicFilterDto::default(),
            &ComicSortOptionDto {
                field: ComicSortFieldDto::ReadAt,
                descending: true,
            },
            ComicGrouping::None,
            None,
            20,
            0,
        );
        assert!(sql.sql.contains("LEFT JOIN comic_reading_histories rh"));
        assert!(sql
            .sql
            .contains("ORDER BY rh.last_read_time DESC NULLS LAST"));
        assert!(sql.sql.contains(", m.title_sort_key ASC, c.comic_id ASC"));
    }

    #[test]
    fn order_by_page_count_asc() {
        let sql = build_ids_page_query(
            &ComicFilterDto::default(),
            &ComicSortOptionDto {
                field: ComicSortFieldDto::PageCount,
                descending: false,
            },
            ComicGrouping::None,
            None,
            10,
            5,
        );
        assert!(sql
            .sql
            .contains("ORDER BY m.page_count ASC, m.title_sort_key ASC, c.comic_id ASC"));
        assert!(!sql.sql.contains("comic_reading_histories"));
    }

    #[test]
    fn order_by_title_uses_sort_key() {
        let sql = build_ids_page_query(
            &ComicFilterDto::default(),
            &ComicSortOptionDto {
                field: ComicSortFieldDto::Title,
                descending: false,
            },
            ComicGrouping::None,
            None,
            10,
            0,
        );
        assert!(sql
            .sql
            .contains("ORDER BY m.title_sort_key ASC, c.comic_id ASC"));
    }

    #[test]
    fn order_by_published_at_nulls_last() {
        let sql = build_ids_page_query(
            &ComicFilterDto::default(),
            &ComicSortOptionDto {
                field: ComicSortFieldDto::PublishedAt,
                descending: false,
            },
            ComicGrouping::None,
            None,
            10,
            0,
        );
        assert!(sql.sql.contains("ORDER BY m.published_at ASC NULLS LAST"));
    }

    #[test]
    fn authors_all_filter_joins_comic_authors() {
        let sql = build_ids_page_query(
            &ComicFilterDto {
                authors_all: vec!["artist a".to_string()],
                library_id: Some("lib1".to_string()),
                ..Default::default()
            },
            &ComicSortOptionDto::default(),
            ComicGrouping::None,
            None,
            10,
            0,
        );
        assert!(sql.sql.contains("comic_authors ca"));
        assert!(sql.sql.contains("ca.author_id = ?"));
    }

    #[test]
    fn languages_filter_uses_json_each() {
        let sql = build_ids_page_query(
            &ComicFilterDto {
                languages: vec!["chinese".to_string(), "japanese".to_string()],
                ..Default::default()
            },
            &ComicSortOptionDto::default(),
            ComicGrouping::None,
            None,
            10,
            0,
        );
        assert!(sql.sql.contains("json_each(m.languages)"));
        assert!(sql.sql.contains("lower(je.value) IN"));
    }

    #[test]
    fn parodies_filter_joins_comic_parodies() {
        let sql = build_ids_page_query(
            &ComicFilterDto {
                parodies: vec!["naruto".to_string()],
                ..Default::default()
            },
            &ComicSortOptionDto::default(),
            ComicGrouping::None,
            None,
            10,
            0,
        );
        assert!(sql.sql.contains("comic_parodies cp"));
        assert!(sql.sql.contains("lower(cp.parody_name) IN"));
    }

    #[test]
    fn characters_filter_joins_comic_characters() {
        let sql = build_ids_page_query(
            &ComicFilterDto {
                characters: vec!["sakura".to_string()],
                ..Default::default()
            },
            &ComicSortOptionDto::default(),
            ComicGrouping::None,
            None,
            10,
            0,
        );
        assert!(sql.sql.contains("comic_characters cc"));
        assert!(sql.sql.contains("lower(cc.character_name) IN"));
    }

    #[test]
    fn query_searches_parody_and_character() {
        let sql = build_ids_page_query(
            &ComicFilterDto {
                query: Some("naruto".to_string()),
                ..Default::default()
            },
            &ComicSortOptionDto::default(),
            ComicGrouping::None,
            None,
            10,
            0,
        );
        assert!(sql.sql.contains("comic_parodies"));
        assert!(sql.sql.contains("comic_characters"));
    }

    #[test]
    fn library_id_filter_scopes_comics_where() {
        let sql = build_ids_page_query(
            &ComicFilterDto {
                library_id: Some("lib-abc".to_string()),
                ..Default::default()
            },
            &ComicSortOptionDto::default(),
            ComicGrouping::None,
            None,
            10,
            0,
        );
        assert!(sql.sql.contains("c.library_id = ?"));
        assert!(sql.values.iter().any(|v| matches!(
            v,
            Value::String(Some(s)) if s.as_str() == "lib-abc"
        )));
    }

    #[test]
    fn by_series_grouping_orders_root_then_series_then_unassigned() {
        let sql = build_ids_page_query(
            &ComicFilterDto::default(),
            &ComicSortOptionDto::default(),
            ComicGrouping::BySeries,
            Some("E:/lib"),
            10,
            0,
        );
        assert!(sql
            .sql
            .contains("LEFT JOIN series_items si ON si.comic_id = c.comic_id"));
        assert!(sql
            .sql
            .contains("LEFT JOIN series s ON s.series_id = si.series_id"));
        assert!(sql.sql.contains("WHEN s.folder_path = ? THEN 0"));
        assert!(sql.sql.contains("s.name_sort_key END ASC NULLS LAST"));
        assert!(sql.sql.contains("si.sort_order END ASC NULLS LAST"));
        assert!(sql.sql.contains("m.title_sort_key ASC, c.comic_id ASC"));
        assert!(matches!(
            sql.values[0],
            Value::String(Some(ref s)) if s.as_str() == "E:/lib"
        ));
    }
}
