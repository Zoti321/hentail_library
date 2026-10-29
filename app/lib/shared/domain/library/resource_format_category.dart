/// Supported resource formats 的资源格式类别（设置页勾选单位）。
enum ResourceFormatCategory {
  folder,
  pdf,
  epub,
  archive;

  static const List<ResourceFormatCategory> all = <ResourceFormatCategory>[
    ResourceFormatCategory.folder,
    ResourceFormatCategory.pdf,
    ResourceFormatCategory.epub,
    ResourceFormatCategory.archive,
  ];

  static ResourceFormatCategory? tryParse(String name) {
    for (final ResourceFormatCategory group in ResourceFormatCategory.values) {
      if (group.name == name) {
        return group;
      }
    }
    return null;
  }
}

/// 从持久化列表恢复启用分组；缺省或非法时回退为全部启用。
List<ResourceFormatCategory> resourceFormatCategoriesFromStorage(Object? raw) {
  if (raw == null) {
    return List<ResourceFormatCategory>.from(ResourceFormatCategory.all);
  }
  if (raw is! List<dynamic>) {
    return List<ResourceFormatCategory>.from(ResourceFormatCategory.all);
  }
  final List<String> names = raw.map((Object? e) => e.toString()).toList();
  final List<ResourceFormatCategory> parsed = names
      .map(ResourceFormatCategory.tryParse)
      .whereType<ResourceFormatCategory>()
      .toList();
  if (parsed.isEmpty && names.isNotEmpty) {
    // 全部无法识别 → 回退默认，避免意外全关。
    return List<ResourceFormatCategory>.from(ResourceFormatCategory.all);
  }
  // 允许显式空列表（用户确认后的全关）。
  final Set<ResourceFormatCategory> unique = parsed.toSet();
  return ResourceFormatCategory.all.where(unique.contains).toList();
}

List<String> resourceFormatCategoriesToStorage(List<ResourceFormatCategory> groups) =>
    groups.map((ResourceFormatCategory g) => g.name).toList();

/// 保存全关启用分组前是否需要强确认。
bool requiresDisableAllResourceFormatCategoriesConfirm(Iterable<ResourceFormatCategory> enabled) =>
    enabled.isEmpty;
