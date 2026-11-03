import 'package:hentai_library/features/app_settings/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'public barrel exports cross-feature types, ports, and bootstrap hooks',
    () {
      expect(AppSetting, isNotNull);
      expect(AppThemePreference, isNotNull);
      expect(AppColorSchemePreference, isNotNull);
      expect(AppLocalePreference, isNotNull);
      expect(AppSettingRepository, isNotNull);
      expect(ReaderSettingsCommandPort, isNotNull);
      expect(AppThemePreferencesPort, isNotNull);
      expect(createAppSettingRepository, isNotNull);
      expect(createAppThemePreferencesPort, isNotNull);
      expect(createReaderDisplayPreferencesPort, isNotNull);
      expect(createReaderSettingsCommandPort, isNotNull);
      expect(SettingsMd3ePage, isNotNull);
      expect(DiagnosticModeBanner, isNotNull);
      expect(settingsProvider, isNotNull);
    },
  );
}
