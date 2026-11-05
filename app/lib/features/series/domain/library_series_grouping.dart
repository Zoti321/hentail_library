/// Series 列表分组方式（扁平列表，无分组标题、无折叠）。
///
/// 分组只决定块之间的顺序；块内仍按库浏览页当前排序字段排列。
enum LibrarySeriesGrouping {
  none,
  bySerializationStatus;

  static const String storageKey = 'library_series_grouping';

  static const LibrarySeriesGrouping defaultValue = LibrarySeriesGrouping.none;

  static LibrarySeriesGrouping fromStorage(String? raw) {
    if (raw == null) {
      return defaultValue;
    }
    for (final LibrarySeriesGrouping value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    return none;
  }
}
