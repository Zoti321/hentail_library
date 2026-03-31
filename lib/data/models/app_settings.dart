import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

const int currentSettingsVersion = 1;

@freezed
abstract class AppSettings with _$AppSettings {
  factory AppSettings({
    @Default(currentSettingsVersion) int version,
    @Default(false) bool isDarkMode,
    @Default(false) bool isHealthyMode,
    @Default(false) bool autoScan,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
