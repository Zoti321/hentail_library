/// 旧版「Series 列表固定 Library root series 优先」偏好键。
///
/// 迁移逻辑归 `app_settings`（ADR-0042）：Series 只消费已解析的
/// `preferLibraryRootSeries` 布尔，不再反向提供存储键常量。
abstract final class LegacyLibraryPreferLibraryRootSeries {
  static const String storageKey = 'library_prefer_library_root_series';

  static const bool defaultValue = true;

  static bool fromStorage(bool? raw) => raw ?? defaultValue;
}
