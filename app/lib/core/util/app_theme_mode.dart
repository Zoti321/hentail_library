import 'package:flutter/material.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';

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
