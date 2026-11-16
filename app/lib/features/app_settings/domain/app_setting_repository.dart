import 'package:hentai_library/features/app_settings/domain/app_setting.dart';

abstract class AppSettingRepository {
  Future<AppSetting> load();

  Future<void> save(AppSetting setting);

  /// Legacy app-level autoScan before per-library Scan on startup migration.
  Future<bool?> peekLegacyAutoScan();

  /// Reads the opaque legacy format payload before per-library migration.
  ///
  /// `null` means no payload is available; a record with a null field means
  /// the legacy payload omitted the setting. The Library owner interprets it.
  Future<({Object? enabledFormatGroups})?> peekLegacyResourceFormatPayload();

  /// Clears staged legacy import keys after one-shot library migrations.
  Future<void> clearLegacyImportPayload();
}
