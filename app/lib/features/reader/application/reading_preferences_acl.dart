import 'package:hentai_library/features/app_settings/public/reading_preferences_schema.dart';
import 'package:hentai_library/features/reader/domain/auto_play_mode.dart';
import 'package:hentai_library/features/reader/domain/reading_mode.dart';
import 'package:hentai_library/features/reader/domain/reading_preferences.dart';

/// 解码结果：合法领域值 + 未被识别的 id 列表（交给 provider 层上报）。
typedef DecodedReadingPreferences = ({
  ReadingPreferences value,
  List<String> unknownIds,
});

/// 防腐层（ADR-0046）：`app_settings` 的持久化原语记录 ↔ `reader` 领域值对象。
///
/// 纯函数、无状态、不 I/O、不打日志、不抛异常。
abstract final class ReadingPreferencesAcl {
  ReadingPreferencesAcl._();

  /// 全函数：任意输入都返回合法值；未知 id 退回该字段默认值并记入 `unknownIds`。
  static DecodedReadingPreferences decode(ReadingPreferencesRecord record) {
    final List<String> unknownIds = <String>[];
    return (
      value: ReadingPreferences(
        readingMode: _readingModeOf(record.readingModeId, unknownIds),
        webtoonZoomMode: _webtoonZoomModeOf(
          record.webtoonZoomModeId,
          unknownIds,
        ),
        webtoonMarginPercent:
            ReadingPreferenceSchema.normalizeWebtoonMarginPercent(
              record.webtoonMarginPercent,
            ),
        autoPlayMode: _autoPlayModeOf(record.autoPlayModeId, unknownIds),
        autoPlayIntervalSeconds:
            ReadingPreferenceSchema.clampAutoPlayIntervalSeconds(
              record.autoPlayIntervalSeconds,
            ),
      ),
      unknownIds: unknownIds,
    );
  }

  /// 编码：穷尽 switch，新增枚举值时编译失败（不允许 `default` 分支）。
  static ReadingPreferencesRecord encode(ReadingPreferences value) {
    return (
      readingModeId: switch (value.readingMode) {
        ReadingMode.paged => ReadingPreferenceSchema.readingModePagedId,
        ReadingMode.webtoon => ReadingPreferenceSchema.readingModeWebtoonId,
        ReadingMode.dualPage => ReadingPreferenceSchema.readingModeDualPageId,
      },
      webtoonZoomModeId: switch (value.webtoonZoomMode) {
        WebtoonZoomMode.fitWidth =>
          ReadingPreferenceSchema.webtoonZoomFitWidthId,
        WebtoonZoomMode.originalSize =>
          ReadingPreferenceSchema.webtoonZoomOriginalSizeId,
      },
      webtoonMarginPercent: value.webtoonMarginPercent,
      autoPlayModeId: switch (value.autoPlayMode) {
        AutoPlayMode.comicOnce => ReadingPreferenceSchema.autoPlayComicOnceId,
        AutoPlayMode.comicLoop => ReadingPreferenceSchema.autoPlayComicLoopId,
        AutoPlayMode.seriesOnce => ReadingPreferenceSchema.autoPlaySeriesOnceId,
        AutoPlayMode.seriesLoop => ReadingPreferenceSchema.autoPlaySeriesLoopId,
      },
      autoPlayIntervalSeconds: value.autoPlayIntervalSeconds,
    );
  }

  static ReadingMode _readingModeOf(String id, List<String> unknownIds) {
    return switch (id) {
      ReadingPreferenceSchema.readingModePagedId => ReadingMode.paged,
      ReadingPreferenceSchema.readingModeWebtoonId => ReadingMode.webtoon,
      ReadingPreferenceSchema.readingModeDualPageId => ReadingMode.dualPage,
      _ => _fallback(id, unknownIds, kDefaultReadingMode),
    };
  }

  static WebtoonZoomMode _webtoonZoomModeOf(
    String id,
    List<String> unknownIds,
  ) {
    return switch (id) {
      ReadingPreferenceSchema.webtoonZoomFitWidthId => WebtoonZoomMode.fitWidth,
      ReadingPreferenceSchema.webtoonZoomOriginalSizeId =>
        WebtoonZoomMode.originalSize,
      _ => _fallback(id, unknownIds, kDefaultWebtoonZoomMode),
    };
  }

  static AutoPlayMode _autoPlayModeOf(String id, List<String> unknownIds) {
    return switch (id) {
      ReadingPreferenceSchema.autoPlayComicOnceId => AutoPlayMode.comicOnce,
      ReadingPreferenceSchema.autoPlayComicLoopId => AutoPlayMode.comicLoop,
      ReadingPreferenceSchema.autoPlaySeriesOnceId => AutoPlayMode.seriesOnce,
      ReadingPreferenceSchema.autoPlaySeriesLoopId => AutoPlayMode.seriesLoop,
      _ => _fallback(id, unknownIds, kDefaultAutoPlayMode),
    };
  }

  static T _fallback<T>(String id, List<String> unknownIds, T fallback) {
    unknownIds.add(id);
    return fallback;
  }
}
