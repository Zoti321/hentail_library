/// Smart facet match：Comic metadata form 是否启用 Smart facet match。
///
/// 默认开启；仅「作者&标签」tab 顶栏开关使用。
abstract final class SmartFacetMatchPreference {
  static const String storageKey = 'smart_facet_match_enabled';

  static const bool defaultValue = true;

  static bool fromStorage(bool? raw) => raw ?? defaultValue;
}
