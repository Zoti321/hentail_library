use sea_orm::Value;

use super::dto::{ComicSortFieldDto, ComicSortOptionDto};

/// 库页 Comics 列表的分组方式。
///
/// 分组是扁平列表上的排序覆盖规则：不展示分组标题，也不折叠。
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
    /// 分组是否覆盖用户选择的排序字段。
    pub fn overrides_sort(self) -> bool {
        match self {
            Self::None => false,
            Self::BySeries => true,
        }
    }

    /// 排序是否需要 Library root 路径参与。
    pub fn needs_library_root(self) -> bool {
        match self {
            Self::None => false,
            Self::BySeries => true,
        }
    }

    /// 额外的关联（JOIN）片段；`None` 时仅由排序字段决定是否需要 JOIN。
    pub fn join_clause(self, sort_field: ComicSortFieldDto) -> &'static str {
        match self {
            Self::None => sort_field_join_clause(sort_field),
            Self::BySeries => SERIES_JOIN_CLAUSE,
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
            Self::BySeries => series_block_order_by(library_root_path, values),
        }
    }
}

fn sort_field_join_clause(field: ComicSortFieldDto) -> &'static str {
    match field {
        ComicSortFieldDto::ReadAt => {
            " LEFT JOIN comic_reading_histories rh ON rh.comic_id = c.comic_id"
        }
        _ => "",
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

fn series_block_order_by(library_root_path: Option<&str>, values: &mut Vec<Value>) -> String {
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
         CASE WHEN s.series_id IS NULL THEN NULL ELSE si.sort_order END ASC NULLS LAST, \
         m.title_sort_key ASC, c.comic_id ASC"
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn none_grouping_does_not_override_sort_or_need_root() {
        assert!(!ComicGrouping::None.overrides_sort());
        assert!(!ComicGrouping::None.needs_library_root());
    }

    #[test]
    fn by_series_grouping_overrides_sort_and_needs_root() {
        assert!(ComicGrouping::BySeries.overrides_sort());
        assert!(ComicGrouping::BySeries.needs_library_root());
    }

    #[test]
    fn by_series_order_by_binds_root_only_when_provided() {
        let sort = ComicSortOptionDto::default();
        let mut with_root = Vec::new();
        let sql = ComicGrouping::BySeries.order_by(&sort, Some("E:/lib"), &mut with_root);
        assert!(sql.contains("s.folder_path = ?"));
        assert_eq!(with_root.len(), 1);

        let mut without_root = Vec::new();
        let sql = ComicGrouping::BySeries.order_by(&sort, None, &mut without_root);
        assert!(!sql.contains("s.folder_path = ?"));
        assert!(without_root.is_empty());
    }
}
