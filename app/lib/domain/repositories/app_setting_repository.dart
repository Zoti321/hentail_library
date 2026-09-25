import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/models/models.dart' show AppSetting;

abstract class AppSettingRepository {
  Future<AppSetting> load();

  Future<void> save(AppSetting setting);

  /// Legacy app-level autoScan before per-library Scan on startup migration.
  Future<bool?> peekLegacyAutoScan();

  /// Legacy app-global format groups before per-library SQLite migration.
  Future<List<FormatGroup>?> peekLegacyEnabledFormatGroups();

  /// Clears staged legacy import keys after one-shot library migrations.
  Future<void> clearLegacyImportPayload();
}
