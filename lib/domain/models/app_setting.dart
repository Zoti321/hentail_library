import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_setting.freezed.dart';
part 'app_setting.g.dart';

@freezed
abstract class AppSetting with _$AppSetting {
  factory AppSetting({
    @Default(3) int version,
    @Default(AppThemePreference.system) AppThemePreference themePreference,
    @Default(false) bool isHealthyMode,
    @Default(false) bool autoScan,
    @Default(0.0) double readerDimLevel,
    @Default(false) bool readerIsVertical,
    @Default(false) bool readerAutoPlayEnabled,
    @Default(5) int readerAutoPlayIntervalSeconds,
    @Default(true) bool desktopSidebarExpanded,

    /// 漫画库「漫画」分区不显示已归入任意系列的漫画。
    @Default(false) bool libraryHideComicsInSeries,

    /// 是否将 epub/zip/cbz 列表封面解码结果写入应用缓存目录（关闭后不读写，已落盘文件保留）。
    @Default(true) bool archiveCoverDiskCacheEnabled,

    /// 启动时是否自动检查应用更新。
    @Default(true) bool autoUpdate,

    /// 用户选择「稍后提醒」所忽略的远程版本号；空字符串表示未忽略。
    @Default('') String dismissedUpdateVersion,
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
