import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_migration.dart';
import 'package:hentai_library/features/app_settings/domain/reader_session_preference_types.dart';

part 'app_setting.freezed.dart';
part 'app_setting.g.dart';

@freezed
abstract class AppSetting with _$AppSetting {
  factory AppSetting({
    @Default(4) int version,
    @Default(AppThemePreference.system) AppThemePreference themePreference,
    @Default(AppColorSchemePreference.brand)
    AppColorSchemePreference colorSchemePreference,

    /// 预留：Material 动态取色；本迭代不实现运行时取色（ADR-0032）。
    @Default(false) bool useDynamicColor,
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

    /// Healthy mode：库、搜索与历史中隐藏 R18 Comic（不修改分级）。
    @Default(false) bool healthyMode,
  }) = _AppSetting;

  const AppSetting._();

  factory AppSetting.fromJson(Map<String, dynamic> json) =>
      _$AppSettingFromJson(migrateAppSettingJson(json))
          .withNormalizedReaderPreferences();

  /// 阅读器相关数值字段归一化（边距步进、自动播放间隔 clamp）。
  AppSetting withNormalizedReaderPreferences() {
    return copyWith(
      webtoonMarginPercent: normalizeWebtoonMarginPercent(webtoonMarginPercent),
      readerAutoPlayIntervalSeconds: clampReaderAutoPlayInterval(
        readerAutoPlayIntervalSeconds,
      ),
    );
  }

  AppSetting withWebtoonMarginPercent(int value) {
    return copyWith(webtoonMarginPercent: normalizeWebtoonMarginPercent(value));
  }

  AppSetting withReaderAutoPlayIntervalSeconds(int value) {
    return copyWith(
      readerAutoPlayIntervalSeconds: clampReaderAutoPlayInterval(value),
    );
  }

  AppSetting withDismissedUpdateVersion(String remoteVersion) {
    return copyWith(dismissedUpdateVersion: remoteVersion.trim());
  }

  /// 是否应向用户展示更新提示（已忽略的版本不再提示）。
  bool shouldPromptForUpdate(String remoteVersion) {
    final String version = remoteVersion.trim();
    if (!autoUpdate || version.isEmpty) {
      return false;
    }
    return dismissedUpdateVersion != version;
  }
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

/// 固定配色方案 id（非 Material Dynamic Color 运行时）；与 [AppThemePreference] 正交。
@JsonEnum(alwaysCreate: true)
enum AppColorSchemePreference {
  @JsonValue('brand')
  brand,
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
