import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';

part 'app_setting.freezed.dart';
part 'app_setting.g.dart';

Map<String, dynamic> _migrateAppSettingJson(Map<String, dynamic> json) {
  final Map<String, dynamic> migrated = Map<String, dynamic>.from(json);
  if (migrated.containsKey('readingMode')) {
    final Object? rawMode = migrated['readingMode'];
    if (rawMode == 'continuousVertical') {
      migrated['readingMode'] = readingModeToJson(ReadingMode.webtoon);
    } else {
      migrated['readingMode'] = readingModeToJson(
        readingModeFromJson(rawMode),
      );
    }
  }
  if (!migrated.containsKey('readingMode') &&
      migrated.containsKey('readerIsVertical')) {
    migrated['readingMode'] = migrated['readerIsVertical'] == true
        ? readingModeToJson(ReadingMode.webtoon)
        : readingModeToJson(kDefaultReadingMode);
  }
  migrated.remove('readerIsVertical');
  migrated.remove('readerDimLevel');
  return migrated;
}

@freezed
abstract class AppSetting with _$AppSetting {
  factory AppSetting({
    @Default(3) int version,
    @Default(AppThemePreference.system) AppThemePreference themePreference,
    @Default(false) bool autoScan,
    @Default(kDefaultReadingMode) ReadingMode readingMode,
    @Default(false) bool readerAutoPlayEnabled,
    @Default(5) int readerAutoPlayIntervalSeconds,
    @Default(true) bool desktopSidebarExpanded,

    /// 启动时是否自动检查应用更新。
    @Default(true) bool autoUpdate,

    /// 用户选择「稍后提醒」所忽略的远程版本号；空字符串表示未忽略。
    @Default('') String dismissedUpdateVersion,
  }) = _AppSetting;

  factory AppSetting.fromJson(Map<String, dynamic> json) =>
      _$AppSettingFromJson(_migrateAppSettingJson(json));
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
