import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/features/app_settings/domain/app_preferences.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_defaults.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_migration.dart';
import 'package:hentai_library/features/app_settings/domain/reading_preferences_schema.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

export 'package:hentai_library/features/app_settings/domain/app_preferences.dart';

part 'app_setting.freezed.dart';
part 'app_setting.g.dart';

LibraryDisplayTarget defaultLibraryDisplayTargetFromJson(Object? raw) {
  return switch (raw) {
    'series' => LibraryDisplayTarget.series,
    _ => LibraryDisplayTarget.comics,
  };
}

String defaultLibraryDisplayTargetToJson(LibraryDisplayTarget value) {
  return switch (value) {
    LibraryDisplayTarget.comics => 'comics',
    LibraryDisplayTarget.series => 'series',
  };
}

@freezed
abstract class AppSetting with _$AppSetting {
  factory AppSetting({
    @Default(AppSettingDefaults.schemaVersion) int version,
    @Default(AppSettingDefaults.themePreference)
    AppThemePreference themePreference,
    @Default(AppSettingDefaults.colorSchemePreference)
    AppColorSchemePreference colorSchemePreference,

    /// 系统动态配色：开启后以平台强调色为 seed（ADR-0037）。
    @Default(AppSettingDefaults.useDynamicColor) bool useDynamicColor,
    @Default(AppSettingDefaults.localePreference)
    AppLocalePreference localePreference,
    @Default(AppSettingDefaults.fontPreference)
    AppFontPreference fontPreference,

    /// 阅读模式持久化 id（`reader` 的 `ReadingMode` 值域，见 [ReadingPreferenceSchema]）。
    @JsonKey(name: 'readingMode')
    @Default(ReadingPreferenceSchema.defaultReadingModeId)
    String readingModeId,
    @Default(ReadingPreferenceSchema.defaultWebtoonMarginPercent)
    int webtoonMarginPercent,

    /// Webtoon 缩放持久化 id（`reader` 的 `WebtoonZoomMode` 值域）。
    @JsonKey(name: 'webtoonZoomMode')
    @Default(ReadingPreferenceSchema.defaultWebtoonZoomModeId)
    String webtoonZoomModeId,
    @Default(ReadingPreferenceSchema.defaultAutoPlayIntervalSeconds)
    int readerAutoPlayIntervalSeconds,

    /// 自动播放模式持久化 id（`reader` 的 `AutoPlayMode` 值域）。
    @Default(ReadingPreferenceSchema.defaultAutoPlayModeId)
    @JsonKey(name: 'autoPlayMode')
    String autoPlayModeId,
    @Default(true) bool desktopSidebarExpanded,

    /// 启动时是否自动检查应用更新。
    @Default(true) bool autoUpdate,

    /// 用户选择「稍后提醒」所忽略的远程版本号；空字符串表示未忽略。
    @Default('') String dismissedUpdateVersion,

    /// 智能匹配：Comic 元数据表单是否按历史共现排序候选（默认开启）。
    @Default(true) bool smartFacetMatchEnabled,

    /// Healthy mode：库、搜索与历史中隐藏 R18 Comic（不修改分级）。
    @Default(false) bool healthyMode,

    /// Series 浏览：Library root series 固定排在列表最前（Library browse preference）。
    @Default(true) bool preferLibraryRootSeries,

    /// Default library display target：进入库浏览时默认 Comics / Series。
    @Default(AppSettingDefaults.defaultLibraryDisplayTarget)
    // fromJson/toJson 需落在 factory 参数上，非 target 注解位置。
    // ignore: invalid_annotation_target
    @JsonKey(
      fromJson: defaultLibraryDisplayTargetFromJson,
      toJson: defaultLibraryDisplayTargetToJson,
    )
    LibraryDisplayTarget defaultLibraryDisplayTarget,
  }) = _AppSetting;

  const AppSetting._();

  factory AppSetting.fromJson(Map<String, dynamic> json) =>
      _$AppSettingFromJson(migrateAppSettingJson(json))
          .withNormalizedReaderPreferences();

  /// 阅读器相关数值字段归一化（边距步进、自动播放间隔 clamp）。
  AppSetting withNormalizedReaderPreferences() {
    return copyWith(
      webtoonMarginPercent:
          ReadingPreferenceSchema.normalizeWebtoonMarginPercent(
            webtoonMarginPercent,
          ),
      readerAutoPlayIntervalSeconds:
          ReadingPreferenceSchema.clampAutoPlayIntervalSeconds(
            readerAutoPlayIntervalSeconds,
          ),
    );
  }

  AppSetting withWebtoonMarginPercent(int value) {
    return copyWith(
      webtoonMarginPercent:
          ReadingPreferenceSchema.normalizeWebtoonMarginPercent(value),
    );
  }

  AppSetting withReaderAutoPlayIntervalSeconds(int value) {
    return copyWith(
      readerAutoPlayIntervalSeconds:
          ReadingPreferenceSchema.clampAutoPlayIntervalSeconds(value),
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

