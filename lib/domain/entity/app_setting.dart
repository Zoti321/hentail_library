import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_setting.freezed.dart';
part 'app_setting.g.dart';

@freezed
abstract class AppSetting with _$AppSetting {
  factory AppSetting({
    @Default(2) int version,
    @Default(AppThemePreference.system) AppThemePreference themePreference,
    @Default(false) bool isHealthyMode,
    @Default(false) bool autoScan,
  }) = _AppSetting;

  factory AppSetting.fromJson(Map<String, dynamic> json) =>
      _$AppSettingFromJson(json);
}

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
