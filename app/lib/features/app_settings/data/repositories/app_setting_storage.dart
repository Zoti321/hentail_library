/// SharedPreferences keys for App preference persistence (ADR-0016).
abstract final class AppSettingStorageKeys {
  static const String aggregateJson = 'app_setting_json';
  static const String legacyImportAutoScan = 'legacy_import_auto_scan';
  static const String legacyImportFormatGroups =
      'legacy_import_enabled_format_groups';
}
