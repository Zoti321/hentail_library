import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/entity/app_theme_preference.dart';

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
