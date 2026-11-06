import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/domain/app_color_scheme_preference.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';

void main() {
  group('color scheme and dynamic color contract fields', () {
    test('defaults on fresh aggregate', () {
      final AppSetting setting = AppSetting();
      expect(setting.version, 4);
      expect(setting.colorSchemePreference, AppColorSchemePreference.brand);
      expect(setting.useDynamicColor, isFalse);
    });

    test('migrateAppSettingJson fills reserved keys for legacy JSON', () {
      final AppSetting setting = AppSetting.fromJson(<String, dynamic>{
        'version': 3,
        'themePreference': 'dark',
      });

      expect(setting.version, 4);
      expect(setting.themePreference, AppThemePreference.dark);
      expect(setting.colorSchemePreference, AppColorSchemePreference.brand);
      expect(setting.useDynamicColor, isFalse);
      expect(setting.toJson()['colorSchemePreference'], 'brand');
      expect(setting.toJson()['useDynamicColor'], isFalse);
    });

    test('persists non-brand colorSchemePreference', () {
      final AppSetting setting = AppSetting(
        colorSchemePreference: AppColorSchemePreference.teal,
      );
      expect(setting.toJson()['colorSchemePreference'], 'teal');
      expect(
        AppSetting.fromJson(setting.toJson()).colorSchemePreference,
        AppColorSchemePreference.teal,
      );
      expect(
        colorSchemeIdForPreference(AppColorSchemePreference.deepOrange),
        'deepOrange',
      );
    });
  });
}
