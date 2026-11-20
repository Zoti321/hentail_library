import 'package:flutter/widgets.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_defaults.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Appearance enum preferences driven by [SettingsEnumNavigationTile]
/// (excludes color dialog and dynamic-color switch).
enum AppearanceEnumPreferenceKind { theme, font, locale }

/// UI assembly order for enum nav tiles (color / dynamic inserted after theme).
const List<AppearanceEnumPreferenceKind> kAppearanceEnumPreferenceOrder =
    <AppearanceEnumPreferenceKind>[
      AppearanceEnumPreferenceKind.theme,
      AppearanceEnumPreferenceKind.font,
      AppearanceEnumPreferenceKind.locale,
    ];

/// Declarative metadata for appearance enum preferences (json keys, icons, titles).
abstract final class AppearancePreferenceSchema {
  static String jsonKey(AppearanceEnumPreferenceKind kind) {
    return switch (kind) {
      AppearanceEnumPreferenceKind.theme => 'themePreference',
      AppearanceEnumPreferenceKind.font => 'fontPreference',
      AppearanceEnumPreferenceKind.locale => 'localePreference',
    };
  }

  static IconData leading(AppearanceEnumPreferenceKind kind) {
    return switch (kind) {
      AppearanceEnumPreferenceKind.theme => Symbols.dark_mode,
      AppearanceEnumPreferenceKind.font => Symbols.text_fields,
      AppearanceEnumPreferenceKind.locale => Symbols.language,
    };
  }

  static String titleOf(
    AppearanceEnumPreferenceKind kind,
    AppLocalizations l10n,
  ) {
    return switch (kind) {
      AppearanceEnumPreferenceKind.theme => l10n.settingsThemeLabel,
      AppearanceEnumPreferenceKind.font => l10n.settingsFontLabel,
      AppearanceEnumPreferenceKind.locale => l10n.settingsLanguageLabel,
    };
  }

  static Object fallback(AppearanceEnumPreferenceKind kind) {
    return switch (kind) {
      AppearanceEnumPreferenceKind.theme => AppSettingDefaults.themePreference,
      AppearanceEnumPreferenceKind.font => AppSettingDefaults.fontPreference,
      AppearanceEnumPreferenceKind.locale =>
        AppSettingDefaults.localePreference,
    };
  }

  static Object read(AppearanceEnumPreferenceKind kind, AppSetting setting) {
    return switch (kind) {
      AppearanceEnumPreferenceKind.theme => setting.themePreference,
      AppearanceEnumPreferenceKind.font => setting.fontPreference,
      AppearanceEnumPreferenceKind.locale => setting.localePreference,
    };
  }

  /// All JSON keys owned by this schema (for migration / contract tests).
  static const Set<String> jsonKeys = <String>{
    'themePreference',
    'fontPreference',
    'localePreference',
  };
}
