import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';

/// app_settings 偏好枚举 → 展示文案（owner extension；ARB 源仍在 `core/l10n`）。
extension AppSettingsL10nX on AppLocalizations {
  String themePreferenceLabel(AppThemePreference preference) {
    switch (preference) {
      case AppThemePreference.system:
        return themePreferenceSystem;

      case AppThemePreference.light:
        return themePreferenceLight;

      case AppThemePreference.dark:
        return themePreferenceDark;
    }
  }

  String colorSchemePreferenceLabel(AppColorSchemePreference preference) {
    return switch (preference) {
      // brand 文案已定稿为紫罗兰色；遗留 violet 偏好显示同一标签。
      AppColorSchemePreference.brand ||
      AppColorSchemePreference.violet => colorSchemePreferenceBrand,
      AppColorSchemePreference.teal => colorSchemePreferenceTeal,
      AppColorSchemePreference.cyan => colorSchemePreferenceCyan,
      AppColorSchemePreference.blue => colorSchemePreferenceBlue,
      AppColorSchemePreference.indigo => colorSchemePreferenceIndigo,
      AppColorSchemePreference.deepPurple => colorSchemePreferenceDeepPurple,
      AppColorSchemePreference.pink => colorSchemePreferencePink,
      AppColorSchemePreference.sakura => colorSchemePreferenceSakura,
      AppColorSchemePreference.yellow => colorSchemePreferenceYellow,
      AppColorSchemePreference.orange => colorSchemePreferenceOrange,
      AppColorSchemePreference.deepOrange => colorSchemePreferenceDeepOrange,
      AppColorSchemePreference.green => colorSchemePreferenceGreen,
    };
  }

  String localePreferenceLabel(AppLocalePreference preference) {
    switch (preference) {
      case AppLocalePreference.system:
        return localePreferenceSystem;

      case AppLocalePreference.zhCn:
        return localePreferenceZhCn;

      case AppLocalePreference.en:
        return localePreferenceEn;
    }
  }

  String fontPreferenceLabel(AppFontPreference preference) {
    return switch (preference) {
      AppFontPreference.miSans => fontPreferenceMiSans,
      AppFontPreference.notoSans => fontPreferenceNotoSans,
    };
  }
}
