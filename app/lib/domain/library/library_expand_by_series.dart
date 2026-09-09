/// Expand by series：Comics 列表是否按系列成员顺序扁平展开。
///
/// 默认开启；仅 Library 页的 Comics Tab 使用。
abstract final class LibraryExpandBySeries {
  static const String storageKey = 'library_expand_by_series';

  static const bool defaultValue = true;

  static bool fromStorage(bool? raw) => raw ?? defaultValue;
}
