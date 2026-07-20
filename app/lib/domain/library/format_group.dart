/// Supported resource formats 的格式分组（设置页勾选单位）。
enum FormatGroup {
  folder,
  pdf,
  epub,
  archive;

  static const List<FormatGroup> all = <FormatGroup>[
    FormatGroup.folder,
    FormatGroup.pdf,
    FormatGroup.epub,
    FormatGroup.archive,
  ];

  static FormatGroup? tryParse(String name) {
    for (final FormatGroup group in FormatGroup.values) {
      if (group.name == name) {
        return group;
      }
    }
    return null;
  }
}

/// 从持久化列表恢复启用分组；缺省或非法时回退为全部启用。
List<FormatGroup> formatGroupsFromStorage(Object? raw) {
  if (raw == null) {
    return List<FormatGroup>.from(FormatGroup.all);
  }
  if (raw is! List<dynamic>) {
    return List<FormatGroup>.from(FormatGroup.all);
  }
  final List<String> names = raw.map((Object? e) => e.toString()).toList();
  final List<FormatGroup> parsed = names
      .map(FormatGroup.tryParse)
      .whereType<FormatGroup>()
      .toList();
  if (parsed.isEmpty && names.isNotEmpty) {
    // 全部无法识别 → 回退默认，避免意外全关。
    return List<FormatGroup>.from(FormatGroup.all);
  }
  // 允许显式空列表（用户确认后的全关）。
  final Set<FormatGroup> unique = parsed.toSet();
  return FormatGroup.all.where(unique.contains).toList();
}

List<String> formatGroupsToStorage(List<FormatGroup> groups) =>
    groups.map((FormatGroup g) => g.name).toList();

/// 保存全关启用分组前是否需要强确认。
bool requiresDisableAllFormatGroupsConfirm(Iterable<FormatGroup> enabled) =>
    enabled.isEmpty;
