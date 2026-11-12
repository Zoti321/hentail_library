import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/public.dart';

void main() {
  test('public barrel exports schema, DI entry points and UI', () {
    expect(AppSetting, isNotNull);
    expect(AppThemePreference, isNotNull);
    expect(AppColorSchemePreference, isNotNull);
    expect(AppLocalePreference, isNotNull);
    expect(AppSettingRepository, isNotNull);
    expect(ReadingPreferenceSchema, isNotNull);
    expect(readingPreferencesRecordOf, isNotNull);
    expect(readingPreferencesRecordProvider, isNotNull);
    expect(readingPreferencesControllerProvider, isNotNull);
    expect(appSettingsProvider, isNotNull);
    expect(appSettingRepositoryProvider, isNotNull);
    expect(createAppSettingRepository, isNotNull);
    expect(SettingsPage, isNotNull);
    expect(DiagnosticModeBanner, isNotNull);
    expect(settingsProvider, isNotNull);
  });

  test('readingPreferencesRecordOf projects 持久化原语只有 String/int', () {
    final ReadingPreferencesRecord record = readingPreferencesRecordOf(
      AppSetting(),
    );
    expect(record.readingModeId, ReadingPreferenceSchema.defaultReadingModeId);
    expect(
      record.webtoonZoomModeId,
      ReadingPreferenceSchema.defaultWebtoonZoomModeId,
    );
    expect(
      record.autoPlayModeId,
      ReadingPreferenceSchema.defaultAutoPlayModeId,
    );
  });
}
