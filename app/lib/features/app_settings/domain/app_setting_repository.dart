import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';

abstract class AppSettingRepository {
  Future<AppSetting> load();

  Future<void> save(AppSetting setting);

  /// Legacy app-level autoScan before per-library Scan on startup migration.
  Future<bool?> peekLegacyAutoScan();

  /// Legacy app-global format groups before per-library SQLite migration.
  Future<List<ResourceFormatCategory>?>
  peekLegacyEnabledResourceFormatCategories();

  /// Clears staged legacy import keys after one-shot library migrations.
  Future<void> clearLegacyImportPayload();
}
