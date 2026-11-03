import 'package:hentai_library/features/app_settings/domain/app_setting.dart';

/// Shell / `shared/ui/theme` 将来读取主题偏好的只读端口（ADR-0032 / #441）。
///
/// 动态配色分支本迭代不实现；[useDynamicColor] 仅作持久化与契约占位。
abstract class AppThemePreferencesPort {
  AppThemePreference get themePreference;

  AppColorSchemePreference get colorSchemePreference;

  bool get useDynamicColor;
}
