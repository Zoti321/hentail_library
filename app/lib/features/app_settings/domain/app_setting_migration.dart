import 'package:hentai_library/features/app_settings/domain/reading_preferences_schema.dart';
import 'package:hentai_library/shared/domain/models/resource_format_category.dart';

/// Normalizes legacy `settings.json` / aggregate JSON into [AppSetting] shape.
///
/// 阅读偏好字段只做**纯字符串规范化**（ADR-0046）：本模块不认识阅读枚举，
/// 未知 id 原样保留，由 `reader` 的防腐层退回默认值并上报。
Map<String, dynamic> migrateAppSettingJson(Map<String, dynamic> json) {
  final Map<String, dynamic> migrated = Map<String, dynamic>.from(json);

  if (!migrated.containsKey('readingMode') &&
      migrated.containsKey('readerIsVertical')) {
    migrated['readingMode'] = migrated['readerIsVertical'] == true
        ? ReadingPreferenceSchema.readingModeWebtoonId
        : ReadingPreferenceSchema.defaultReadingModeId;
  }
  migrated['readingMode'] = ReadingPreferenceSchema.normalizeReadingModeId(
    migrated['readingMode'],
  );
  migrated['webtoonZoomMode'] =
      ReadingPreferenceSchema.normalizeWebtoonZoomModeId(
        migrated['webtoonZoomMode'],
      );
  migrated['autoPlayMode'] = ReadingPreferenceSchema.normalizeAutoPlayModeId(
    migrated['autoPlayMode'],
  );

  migrated.remove('readerIsVertical');
  migrated.remove('readerDimLevel');
  migrated.remove('readerAutoPlayEnabled');
  migrated.remove('autoScan');
  migrated.remove('enabledFormatGroups');
  migrated.remove('libraryCatalogSortFlipEnabled');
  migrated.putIfAbsent('useDynamicColor', () => false);
  migrated.putIfAbsent('colorSchemePreference', () => 'brand');
  migrated.putIfAbsent('preferLibraryRootSeries', () => true);
  migrated.putIfAbsent('fontPreference', () => 'miSans');
  migrated.putIfAbsent('defaultLibraryDisplayTarget', () => 'comics');
  // 设置项仅保留 miSans / notoSans；旧 SC/JP 选项并入 Noto Sans。
  final Object? rawFont = migrated['fontPreference'];
  if (rawFont == 'notoSansSc' || rawFont == 'notoSansJp') {
    migrated['fontPreference'] = 'notoSans';
  }
  if (migrated['version'] is int && (migrated['version'] as int) < 6) {
    migrated['version'] = 6;
  }
  return migrated;
}

/// Reads legacy app-global format groups before they are dropped from AppSetting.
List<ResourceFormatCategory> legacyEnabledResourceFormatCategoriesFromJson(
  Map<String, dynamic> json,
) {
  if (json.containsKey('enabledFormatGroups')) {
    return resourceFormatCategoriesFromStorage(json['enabledFormatGroups']);
  }
  return List<ResourceFormatCategory>.of(ResourceFormatCategory.all);
}

/// Reads legacy app-level autoScan before it is dropped from AppSetting.
bool? legacyAutoScanFromJson(Map<String, dynamic> json) {
  final Object? raw = json['autoScan'];
  if (raw is bool) {
    return raw;
  }
  return null;
}
