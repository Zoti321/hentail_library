use sea_orm::Value;

use super::dto::{ComicSortFieldDto, ComicSortOptionDto};

/// 库页 Comics 列表的分组方式。
///
/// 分组决定系列块之间的先后顺序；块内仍按用户选择的排序字段排列。
/// 新增分组方式时，每个方法中的 `match` 都必须补全对应分支（编译器会强制检查）。
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub enum ComicGrouping {
    #[default]
    None,
    BySeries,
}

const SERIES_JOIN_CLAUSE: &str = " LEFT JOIN series_items si ON si.comic_id = c.comic_id \
     LEFT JOIN series s ON s.series_id = si.series_id";

impl ComicGrouping {
    /// 排序是否需要 Library root 路径参与。
    pub fn needs_library_root(self) -> bool {
        match self {
            Self::None => false,
            Self::BySeries => true,
        }
    }

    /// 额外的关联（JOIN）片段；`None` 时仅由排序字段决定是否需要 JOIN。
    pub fn join_clause(self, sort_field: ComicSortFieldDto, retention_cutoff_ms: i64) -> String {
        match self {
            Self::None => sort_field_join_clause(sort_field, retention_cutoff_ms),
            Self::BySeries => {
                let mut clause = SERIES_JOIN_CLAUSE.to_string();
                let sort_join = sort_field_join_clause(sort_field, retention_cutoff_ms);
                if !sort_join.is_empty() {
                    clause.push_str(&sort_join);
                }
                clause
            }
        }
    }

    /// ORDER BY 片段（参数占位符的值追加到 `values`）。
    pub fn order_by(
        self,
        sort: &ComicSortOptionDto,
        library_root_path: Option<&str>,
        values: &mut Vec<Value>,
    ) -> String {
        match self {
            Self::None => sort_order_by(sort),
            Self::BySeries => {
                let prefix = series_block_prefix_order_by(library_root_path, values);
                let within = sort_order_by(sort);
                format!("{prefix}, {within}")
            }
        }
    }
}

fn sort_field_join_clause(field: ComicSortFieldDto, retention_cutoff_ms: i64) -> String {
    match field {
        ComicSortFieldDto::ReadAt => format!(
            " LEFT JOIN comic_reading_histories rh ON rh.comic_id = c.comic_id \
             AND rh.last_read_time >= {retention_cutoff_ms}"
        ),
        _ => String::new(),
    }
}

fn sort_order_by(sort: &ComicSortOptionDto) -> String {
    let direction = if sort.descending { "DESC" } else { "ASC" };
    match sort.field {
        ComicSortFieldDto::Title => {
            format!("m.title_sort_key {direction}, c.comic_id ASC")
        }
        other => {
            let primary = match other {
                ComicSortFieldDto::Title => unreachable!(),
                ComicSortFieldDto::CreatedAt => format!("c.created_at {direction}"),
                ComicSortFieldDto::LastUpdatedAt => format!("c.last_updated_at {direction}"),
                ComicSortFieldDto::PublishedAt => {
                    format!("m.published_at {direction} NULLS LAST")
                }
                ComicSortFieldDto::ReadAt => {
                    format!("rh.last_read_time {direction} NULLS LAST")
                }
                ComicSortFieldDto::FileSize => format!("c.resource_size {direction}"),
                ComicSortFieldDto::PageCount => format!("m.page_count {direction}"),
            };
            format!("{primary}, m.title_sort_key ASC, c.comic_id ASC")
        }
    }
}

/// 系列块之间的 ORDER BY 前缀（不含块内用户排序）。
fn series_block_prefix_order_by(
    library_root_path: Option<&str>,
    values: &mut Vec<Value>,
) -> String {
    if let Some(root) = library_root_path {
        values.push(Value::String(Some(Box::new(root.to_string()))));
    }
    let root_priority = if library_root_path.is_some() {
        "CASE \
             WHEN s.series_id IS NULL THEN 2 \
             WHEN s.folder_path = ? THEN 0 \
             ELSE 1 \
         END"
    } else {
        "CASE WHEN s.series_id IS NULL THEN 1 ELSE 0 END"
    };
    format!(
        "{root_priority} ASC, \
         CASE WHEN s.series_id IS NULL THEN NULL ELSE s.name_sort_key END ASC NULLS LAST, \
         CASE WHEN s.series_id IS NULL THEN NULL ELSE s.series_id END ASC NULLS LAST"
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn none_grouping_does_not_need_root() {
        assert!(!ComicGrouping::None.needs_library_root());
    }

    #[test]
    fn by_series_grouping_needs_root() {
        assert!(ComicGrouping::BySeries.needs_library_root());
    }

    #[test]
    fn by_series_order_by_combines_block_prefix_with_user_sort() {
        let sort = ComicSortOptionDto {
            field: ComicSortFieldDto::CreatedAt,
            descending: true,
        };
        let mut with_root = Vec::new();
        let sql = ComicGrouping::BySeries.order_by(&sort, Some("E:/lib"), &mut with_root);
        assert!(sql.contains("s.folder_path = ?"));
        assert!(sql.contains("c.created_at DESC"));
        assert!(sql.contains("s.name_sort_key END ASC NULLS LAST"));
        assert!(!sql.contains("si.sort_order"));
        assert_eq!(with_root.len(), 1);
    }

    #[test]
    fn by_series_order_by_binds_root_only_when_provided() {
        let sort = ComicSortOptionDto::default();
        let mut without_root = Vec::new();
        let sql = ComicGrouping::BySeries.order_by(&sort, None, &mut without_root);
        assert!(!sql.contains("s.folder_path = ?"));
        assert!(sql.contains("m.title_sort_key ASC"));
        assert!(without_root.is_empty());
    }

    #[test]
    fn by_series_join_includes_read_at_when_sort_requires_it() {
        let clause =
            ComicGrouping::BySeries.join_clause(ComicSortFieldDto::ReadAt, 1_700_000_000_000);
        assert!(clause.contains("series_items si"));
        assert!(clause.contains("comic_reading_histories rh"));
    }
}
