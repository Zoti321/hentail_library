/// Smart facet match：Comic metadata form 是否启用 Smart facet match。
///
/// 默认开启；由 MD3E 应用设置页开关读写（App preference）。
abstract final class SmartFacetMatchPreference {
  static const String storageKey = 'smart_facet_match_enabled';

  static const bool defaultValue = true;

  static bool fromStorage(bool? raw) => raw ?? defaultValue;
}
