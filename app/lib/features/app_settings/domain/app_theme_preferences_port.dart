import 'package:hentai_library/features/app_settings/domain/app_setting.dart';

/// Shell / `shared/ui/theme` 读取主题偏好的只读端口（ADR-0032 / ADR-0037）。
abstract class AppThemePreferencesPort {
  AppThemePreference get themePreference;

  AppColorSchemePreference get colorSchemePreference;

  /// 开启时装配改用系统动态色 seed，并禁用手动配色方案项。
  bool get useDynamicColor;
}
