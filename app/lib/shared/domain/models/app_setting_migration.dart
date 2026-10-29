import 'package:hentai_library/shared/domain/library/resource_format_category.dart';
import 'package:hentai_library/shared/domain/reading/auto_play_mode.dart';
import 'package:hentai_library/shared/domain/reading/reading_mode.dart';

/// Normalizes legacy `settings.json` / aggregate JSON into [AppSetting] shape.
Map<String, dynamic> migrateAppSettingJson(Map<String, dynamic> json) {
  final Map<String, dynamic> migrated = Map<String, dynamic>.from(json);
  if (migrated.containsKey('readingMode')) {
    final Object? rawMode = migrated['readingMode'];
    if (rawMode == 'continuousVertical') {
      migrated['readingMode'] = readingModeToJson(ReadingMode.webtoon);
    } else {
      migrated['readingMode'] = readingModeToJson(readingModeFromJson(rawMode));
    }
  }
  if (!migrated.containsKey('readingMode') &&
      migrated.containsKey('readerIsVertical')) {
    migrated['readingMode'] = migrated['readerIsVertical'] == true
        ? readingModeToJson(ReadingMode.webtoon)
        : readingModeToJson(kDefaultReadingMode);
  }
  migrated.remove('readerIsVertical');
  migrated.remove('readerDimLevel');
  migrated.remove('readerAutoPlayEnabled');
  migrated.remove('autoScan');
  migrated.remove('enabledFormatGroups');
  migrated.remove('libraryCatalogSortFlipEnabled');
  if (migrated.containsKey('autoPlayMode')) {
    migrated['autoPlayMode'] = autoPlayModeToJson(
      autoPlayModeFromJson(migrated['autoPlayMode']),
    );
  }
  return migrated;
}

/// Reads legacy app-global format groups before they are dropped from AppSetting.
List<ResourceFormatCategory> legacyEnabledResourceFormatCategoriesFromJson(Map<String, dynamic> json) {
  if (json.containsKey('enabledFormatGroups')) {
    return resourceFormatCategoriesFromStorage(json['enabledFormatGroups']);
  }
  return List<ResourceFormatCategory>.from(ResourceFormatCategory.all);
}

/// Reads legacy app-level autoScan before it is dropped from AppSetting.
bool? legacyAutoScanFromJson(Map<String, dynamic> json) {
  final Object? raw = json['autoScan'];
  if (raw is bool) {
    return raw;
  }
  return null;
}
