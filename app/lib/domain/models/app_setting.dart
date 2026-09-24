import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/models/app_setting_migration.dart';
import 'package:hentai_library/domain/reading/auto_play_mode.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';

part 'app_setting.freezed.dart';
part 'app_setting.g.dart';

@freezed
abstract class AppSetting with _$AppSetting {
  factory AppSetting({
    @Default(3) int version,
    @Default(AppThemePreference.system) AppThemePreference themePreference,
    @Default(AppLocalePreference.system) AppLocalePreference localePreference,
    @Default(kDefaultReadingMode) ReadingMode readingMode,
    @Default(kDefaultWebtoonMarginPercent) int webtoonMarginPercent,
    @Default(kDefaultWebtoonZoomMode) WebtoonZoomMode webtoonZoomMode,
    @Default(5) int readerAutoPlayIntervalSeconds,
    @Default(kDefaultAutoPlayMode)
    // ignore: invalid_annotation_target
    @JsonKey(fromJson: autoPlayModeFromJson, toJson: autoPlayModeToJson)
    AutoPlayMode autoPlayMode,
    @Default(true) bool desktopSidebarExpanded,

    /// 启动时是否自动检查应用更新。
    @Default(true) bool autoUpdate,

    /// 用户选择「稍后提醒」所忽略的远程版本号；空字符串表示未忽略。
    @Default('') String dismissedUpdateVersion,
  }) = _AppSetting;

  factory AppSetting.fromJson(Map<String, dynamic> json) =>
      _$AppSettingFromJson(migrateAppSettingJson(json));
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

/// 应用语言：中文 / English / 跟随系统。
@JsonEnum(alwaysCreate: true)
enum AppLocalePreference {
  @JsonValue('system')
  system,
  @JsonValue('zh_CN')
  zhCn,
  @JsonValue('en')
  en,
}
