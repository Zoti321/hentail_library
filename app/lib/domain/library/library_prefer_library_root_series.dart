/// Prefer library root series：Series 列表是否将 Library root series 固定排在最前。
///
/// 默认开启；仅 Series Tab 使用。
abstract final class LibraryPreferLibraryRootSeries {
  static const String storageKey = 'library_prefer_library_root_series';

  static const bool defaultValue = true;

  static bool fromStorage(bool? raw) => raw ?? defaultValue;
}
