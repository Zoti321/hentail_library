/// 库页 Series 列表的分组方式。
///
/// 分组决定块之间的先后顺序；块内仍按用户选择的排序字段排列。
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub enum SeriesGrouping {
    #[default]
    None,
    BySerializationStatus,
}

impl SeriesGrouping {
    /// ORDER BY 中、用户排序之前的分组前缀（不含 prefer root）。
    pub fn order_prefix(self) -> Option<&'static str> {
        match self {
            Self::None => None,
            Self::BySerializationStatus => Some(
                "CASE s.serialization_status \
                 WHEN 'ongoing' THEN 0 \
                 WHEN 'ended' THEN 1 \
                 WHEN 'hiatus' THEN 2 \
                 ELSE 3 \
                 END ASC",
            ),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn by_serialization_status_emits_status_case_order() {
        let prefix = SeriesGrouping::BySerializationStatus
            .order_prefix()
            .expect("prefix");
        assert!(prefix.contains("serialization_status"));
        assert!(prefix.contains("'ongoing'"));
    }

    #[test]
    fn none_has_no_prefix() {
        assert!(SeriesGrouping::None.order_prefix().is_none());
    }
}
