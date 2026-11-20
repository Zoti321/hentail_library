import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_defaults.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_migration.dart';
import 'package:hentai_library/features/app_settings/presentation/l10n/app_settings_l10n.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/appearance_preference_schema.dart';
import 'package:hentai_library/l10n/app_localizations_en.dart';

void main() {
  final AppLocalizationsEn l10n = AppLocalizationsEn();

  group('Appearance preference schema contract', () {
    test('order covers every AppearanceEnumPreferenceKind exactly once', () {
      expect(
        kAppearanceEnumPreferenceOrder.toSet(),
        AppearanceEnumPreferenceKind.values.toSet(),
      );
      expect(
        kAppearanceEnumPreferenceOrder.length,
        AppearanceEnumPreferenceKind.values.length,
      );
    });

    test('jsonKeys match schema helpers and migration fill keys', () {
      for (final AppearanceEnumPreferenceKind kind
          in AppearanceEnumPreferenceKind.values) {
        expect(
          AppearancePreferenceSchema.jsonKeys,
          contains(AppearancePreferenceSchema.jsonKey(kind)),
        );
      }
      final Map<String, dynamic> migrated = migrateAppSettingJson(
        <String, dynamic>{'version': 3},
      );
      expect(migrated['fontPreference'], AppSettingDefaults.fontPreferenceJsonId);
      expect(
        migrated['version'],
        AppSettingDefaults.schemaVersion,
      );
    });

    test('defaults match fresh AppSetting aggregate', () {
      final AppSetting setting = AppSetting();
      expect(setting.version, AppSettingDefaults.schemaVersion);
      expect(setting.themePreference, AppSettingDefaults.themePreference);
      expect(
        setting.colorSchemePreference,
        AppSettingDefaults.colorSchemePreference,
      );
      expect(setting.useDynamicColor, AppSettingDefaults.useDynamicColor);
      expect(setting.localePreference, AppSettingDefaults.localePreference);
      expect(setting.fontPreference, AppSettingDefaults.fontPreference);
      expect(
        setting.defaultLibraryDisplayTarget,
        AppSettingDefaults.defaultLibraryDisplayTarget,
      );
      expect(
        setting.toJson()['fontPreference'],
        AppSettingDefaults.fontPreferenceJsonId,
      );
    });

    test('schema read/fallback round-trip for each kind', () {
      final AppSetting setting = AppSetting();
      for (final AppearanceEnumPreferenceKind kind
          in AppearanceEnumPreferenceKind.values) {
        expect(
          AppearancePreferenceSchema.read(kind, setting),
          AppearancePreferenceSchema.fallback(kind),
        );
        expect(AppearancePreferenceSchema.leading(kind), isA<IconData>());
        expect(AppearancePreferenceSchema.titleOf(kind, l10n), isNotEmpty);
      }
    });

    test('l10n labels resolve for every theme/font/locale value', () {
      for (final AppThemePreference value in AppThemePreference.values) {
        expect(l10n.themePreferenceLabel(value), isNotEmpty);
      }
      for (final AppFontPreference value in AppFontPreference.values) {
        expect(l10n.fontPreferenceLabel(value), isNotEmpty);
      }
      for (final AppLocalePreference value in AppLocalePreference.values) {
        expect(l10n.localePreferenceLabel(value), isNotEmpty);
      }
    });
  });
}
