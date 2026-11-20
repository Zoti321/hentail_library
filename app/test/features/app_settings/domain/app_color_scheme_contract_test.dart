import 'package:test/test.dart';
import 'package:hentai_library/features/app_settings/domain/app_color_scheme_preference.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_defaults.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

void main() {
  group('color scheme and dynamic color contract fields', () {
    test('defaults on fresh aggregate', () {
      final AppSetting setting = AppSetting();
      expect(setting.version, AppSettingDefaults.schemaVersion);
      expect(
        setting.colorSchemePreference,
        AppSettingDefaults.colorSchemePreference,
      );
      expect(setting.useDynamicColor, AppSettingDefaults.useDynamicColor);
      expect(setting.fontPreference, AppSettingDefaults.fontPreference);
      expect(
        setting.defaultLibraryDisplayTarget,
        AppSettingDefaults.defaultLibraryDisplayTarget,
      );
    });

    test('migrateAppSettingJson fills reserved keys for legacy JSON', () {
      final AppSetting setting = AppSetting.fromJson(<String, dynamic>{
        'version': 3,
        'themePreference': 'dark',
      });

      expect(setting.version, AppSettingDefaults.schemaVersion);
      expect(setting.themePreference, AppThemePreference.dark);
      expect(
        setting.colorSchemePreference,
        AppSettingDefaults.colorSchemePreference,
      );
      expect(setting.useDynamicColor, AppSettingDefaults.useDynamicColor);
      expect(setting.fontPreference, AppSettingDefaults.fontPreference);
      expect(
        setting.defaultLibraryDisplayTarget,
        AppSettingDefaults.defaultLibraryDisplayTarget,
      );
      expect(
        setting.toJson()['colorSchemePreference'],
        AppSettingDefaults.colorSchemePreferenceJsonId,
      );
      expect(
        setting.toJson()['useDynamicColor'],
        AppSettingDefaults.useDynamicColor,
      );
      expect(
        setting.toJson()['fontPreference'],
        AppSettingDefaults.fontPreferenceJsonId,
      );
      expect(
        setting.toJson()['defaultLibraryDisplayTarget'],
        AppSettingDefaults.defaultLibraryDisplayTargetJsonId,
      );
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
      expect(
        colorSchemeIdForPreference(AppColorSchemePreference.sakura),
        'sakura',
      );
      expect(
        colorSchemeIdForPreference(AppColorSchemePreference.green),
        'green',
      );
    });
  });
}
