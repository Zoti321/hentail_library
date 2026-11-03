import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/domain/app_theme_preferences_port.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';

class _AppThemePreferencesFromSetting implements AppThemePreferencesPort {
  _AppThemePreferencesFromSetting(this._setting);

  final AppSetting _setting;

  @override
  AppThemePreference get themePreference => _setting.themePreference;

  @override
  AppColorSchemePreference get colorSchemePreference =>
      _setting.colorSchemePreference;

  @override
  bool get useDynamicColor => _setting.useDynamicColor;
}

/// 由 bootstrap 通过 `shared/di` 的 [appThemePreferencesPortProvider] 注入。
AppThemePreferencesPort createAppThemePreferencesPort(Ref ref) {
  final AppSetting setting = ref.watch(settingsProvider).value ?? AppSetting();
  return _AppThemePreferencesFromSetting(setting);
}
