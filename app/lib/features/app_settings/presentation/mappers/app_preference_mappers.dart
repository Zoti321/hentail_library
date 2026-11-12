import 'package:flutter/material.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';

/// 持久化偏好 → Flutter 类型映射（原 `core/util/app_locale.dart` /
/// `core/util/app_theme_mode.dart`）。
///
/// 归位 app_settings：映射的输入是该模块拥有的偏好枚举，放在 core 会制造
/// `core → features`（ADR-0045 可达性豁免）。
Locale? localeFromPreference(AppLocalePreference preference) {
  switch (preference) {
    case AppLocalePreference.system:
      return null;
    case AppLocalePreference.zhCn:
      return const Locale('zh');
    case AppLocalePreference.en:
      return const Locale('en');
  }
}

ThemeMode themeModeFromPreference(AppThemePreference preference) {
  switch (preference) {
    case AppThemePreference.system:
      return ThemeMode.system;
    case AppThemePreference.light:
      return ThemeMode.light;
    case AppThemePreference.dark:
      return ThemeMode.dark;
  }
}
