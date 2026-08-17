import 'package:hentai_library/domain/models/models.dart' show AppSetting;

abstract class AppSettingRepository {
  Future<AppSetting> load();

  Future<void> save(AppSetting setting);

  /// Reads leftover `autoScan` from settings.json once (null if absent).
  Future<bool?> peekLegacyAutoScan();
}
