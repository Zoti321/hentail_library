/// Supported resource formats 的资源格式类别（设置页勾选单位）。
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum ResourceFormatCategory {
    Folder,
    Pdf,
    Epub,
    Archive,
}

impl ResourceFormatCategory {
    pub const ALL: [ResourceFormatCategory; 4] = [
        ResourceFormatCategory::Folder,
        ResourceFormatCategory::Pdf,
        ResourceFormatCategory::Epub,
        ResourceFormatCategory::Archive,
    ];

    pub fn resource_types(self) -> &'static [&'static str] {
        match self {
            ResourceFormatCategory::Folder => &["dir"],
            ResourceFormatCategory::Pdf => &["pdf"],
            ResourceFormatCategory::Epub => &["epub"],
            ResourceFormatCategory::Archive => &["zip", "cbz", "cbr", "rar", "cb7", "sevenz"],
        }
    }
}

pub fn resource_type_enabled(resource_type: &str, enabled_groups: &[ResourceFormatCategory]) -> bool {
    enabled_groups
        .iter()
        .any(|group| group.resource_types().contains(&resource_type))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn resource_format_category_archive_expands_to_all_archive_resource_types() {
        let types = ResourceFormatCategory::Archive.resource_types();
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
    fn resource_format_category_folder_expands_to_dir_only() {
        assert_eq!(ResourceFormatCategory::Folder.resource_types(), &["dir"]);
    }
}
