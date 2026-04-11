import 'package:json_annotation/json_annotation.dart';

/// 应用外观：浅色 / 深色 / 跟随系统。
@JsonEnum(alwaysCreate: true)
enum AppThemePreference {
  @JsonValue('system')
  system,
  @JsonValue('light')
  light,
  @JsonValue('dark')
  dark,
}

extension AppThemePreferenceX on AppThemePreference {
  String get labelZh {
    switch (this) {
      case AppThemePreference.system:
        return '跟随系统';
      case AppThemePreference.light:
        return '浅色';
      case AppThemePreference.dark:
        return '深色';
    }
  }
}
