/// Comics 列表分组方式：扁平列表上的排序覆盖规则（不展示分组标题、不折叠）。
///
/// 新增分组键时：在此增加枚举值，补全 [overridesSort]，并同步 Rust 侧
/// `ComicGroupingDto` 映射（见 `comic_repository_impl.dart`）。
enum LibraryComicGrouping {
  none,
  bySeries;

  static const String storageKey = 'library_comic_grouping';

  /// 旧版「按系列展开」布尔偏好键，仅用于一次性迁移。
  static const String legacyExpandBySeriesStorageKey =
      'library_expand_by_series';

  static const LibraryComicGrouping defaultValue =
      LibraryComicGrouping.bySeries;

  /// 分组是否覆盖用户选择的排序字段（分组时排序控件禁用）。
  bool get overridesSort => switch (this) {
    LibraryComicGrouping.none => false,
    LibraryComicGrouping.bySeries => true,
  };

  /// 缺失时使用 [defaultValue]；未知名称回退为 [none]。
  static LibraryComicGrouping fromStorage(String? raw) {
    if (raw == null) {
      return defaultValue;
    }
    for (final LibraryComicGrouping value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    return none;
  }
}
