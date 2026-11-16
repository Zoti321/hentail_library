/// Comics 列表分组方式（扁平列表，无分组标题、无折叠）。
///
/// 分组只决定系列块之间的顺序；块内仍按库浏览页当前排序字段排列。
/// 新增分组键时：在此增加枚举值，并同步 Rust 侧 `ComicGroupingDto` 映射
///（见 `comic_repository_impl.dart`）。
enum LibraryComicGrouping {
  none,
  bySeries;

  static const String storageKey = 'library_comic_grouping';

  /// 旧版「按系列展开」布尔偏好键，仅用于一次性迁移。
  static const String legacyExpandBySeriesStorageKey =
      'library_expand_by_series';

  static const LibraryComicGrouping defaultValue =
      LibraryComicGrouping.bySeries;

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
