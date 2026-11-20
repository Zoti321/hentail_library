import 'package:hentai_library/features/app_settings/domain/app_preferences.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

/// Single source for AppSetting schema version and appearance/interface defaults.
///
/// Keep `@Default(...)`, migration `putIfAbsent`, UI fallbacks, and contract tests
/// aligned with these constants (see `README.md`).
abstract final class AppSettingDefaults {
  static const int schemaVersion = 6;

  static const AppThemePreference themePreference = AppThemePreference.system;
  static const AppColorSchemePreference colorSchemePreference =
      AppColorSchemePreference.brand;
  static const bool useDynamicColor = false;
  static const AppLocalePreference localePreference = AppLocalePreference.system;
  static const AppFontPreference fontPreference = AppFontPreference.notoSans;
  static const String fontPreferenceJsonId = 'notoSans';
  static const String colorSchemePreferenceJsonId = 'brand';
  static const String themePreferenceJsonId = 'system';
  static const String localePreferenceJsonId = 'system';
  static const LibraryDisplayTarget defaultLibraryDisplayTarget =
      LibraryDisplayTarget.comics;
  static const String defaultLibraryDisplayTargetJsonId = 'comics';
}
