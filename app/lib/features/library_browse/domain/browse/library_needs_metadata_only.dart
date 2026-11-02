/// Comics Tab「仅显示待补元数据」：只列出处于 Needs metadata 状态的 Comic。
///
/// 默认关闭；仅 Library 页的 Comics Tab 使用，跨 Library 共享。
abstract final class LibraryNeedsMetadataOnly {
  static const String storageKey = 'library_needs_metadata_only';

  static const bool defaultValue = false;

  static bool fromStorage(bool? raw) => raw ?? defaultValue;
}
