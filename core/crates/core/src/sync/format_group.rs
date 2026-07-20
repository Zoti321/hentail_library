/// Supported resource formats 的格式分组（设置页勾选单位）。
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum FormatGroup {
    Folder,
    Pdf,
    Epub,
    Archive,
}

impl FormatGroup {
    pub const ALL: [FormatGroup; 4] = [
        FormatGroup::Folder,
        FormatGroup::Pdf,
        FormatGroup::Epub,
        FormatGroup::Archive,
    ];

    pub fn resource_types(self) -> &'static [&'static str] {
        match self {
            FormatGroup::Folder => &["dir"],
            FormatGroup::Pdf => &["pdf"],
            FormatGroup::Epub => &["epub"],
            FormatGroup::Archive => &["zip", "cbz", "cbr", "rar", "cb7", "sevenz"],
        }
    }
}

pub fn resource_type_enabled(resource_type: &str, enabled_groups: &[FormatGroup]) -> bool {
    enabled_groups
        .iter()
        .any(|group| group.resource_types().contains(&resource_type))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn format_group_archive_expands_to_all_archive_resource_types() {
        let types = FormatGroup::Archive.resource_types();
        assert!(types.contains(&"zip"));
        assert!(types.contains(&"cbz"));
        assert!(types.contains(&"cbr"));
        assert!(types.contains(&"rar"));
        assert!(types.contains(&"cb7"));
        assert!(types.contains(&"sevenz"));
        assert!(!types.contains(&"dir"));
        assert!(!types.contains(&"pdf"));
        assert!(!types.contains(&"epub"));
    }

    #[test]
    fn format_group_folder_expands_to_dir_only() {
        assert_eq!(FormatGroup::Folder.resource_types(), &["dir"]);
    }
}
