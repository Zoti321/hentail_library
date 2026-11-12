/// 阅读偏好**持久化 schema**（ADR-0046）：id 白名单、默认值与归一化常量。
///
/// 本文件只认识 `String` / `int` 原语，不认识任何阅读枚举——阅读语义归 `reader`。
/// `reader` 侧防腐层（`features/reader/public/reading_preferences_acl.dart`）
/// 把这些 id 映射回领域枚举；两侧 id 集合与默认值由
/// `test/architecture/reading_preferences_acl_shape_test.dart` 锁定一致。
library;

/// L1 传输记录：字段全部为持久化原语。
///
/// 这是 `app_settings` 唯一跨模块的阅读偏好出口（ADR-0040 允许的 `typedef` 投影）。
typedef ReadingPreferencesRecord = ({
  String readingModeId,
  String webtoonZoomModeId,
  int webtoonMarginPercent,
  String autoPlayModeId,
  int autoPlayIntervalSeconds,
});

/// 阅读偏好落盘键与值域（`app_setting_json` 扁平字段，`version` 不变）。
abstract final class ReadingPreferenceSchema {
  ReadingPreferenceSchema._();

  // ---- 阅读模式 ----
  static const String readingModePagedId = 'paged';
  static const String readingModeWebtoonId = 'webtoon';
  static const String readingModeDualPageId = 'dualPage';
  static const String defaultReadingModeId = readingModePagedId;
  static const Set<String> readingModeIds = <String>{
    readingModePagedId,
    readingModeWebtoonId,
    readingModeDualPageId,
  };

  /// 旧版阅读模式字符串 → 现行 id（其余字符串原样保留，交由 ACL 兜底上报）。
  static const Map<String, String> legacyReadingModeIds = <String, String>{
    'continuousVertical': readingModeWebtoonId,
    'dualPageNoCover': readingModeDualPageId,
  };

  // ---- Webtoon 缩放 ----
  static const String webtoonZoomFitWidthId = 'fitWidth';
  static const String webtoonZoomOriginalSizeId = 'originalSize';
  static const String defaultWebtoonZoomModeId = webtoonZoomFitWidthId;
  static const Set<String> webtoonZoomModeIds = <String>{
    webtoonZoomFitWidthId,
    webtoonZoomOriginalSizeId,
  };

  // ---- 自动播放模式 ----
  static const String autoPlayComicOnceId = 'comicOnce';
  static const String autoPlayComicLoopId = 'comicLoop';
  static const String autoPlaySeriesOnceId = 'seriesOnce';
  static const String autoPlaySeriesLoopId = 'seriesLoop';
  static const String defaultAutoPlayModeId = autoPlayComicOnceId;
  static const Set<String> autoPlayModeIds = <String>{
    autoPlayComicOnceId,
    autoPlayComicLoopId,
    autoPlaySeriesOnceId,
    autoPlaySeriesLoopId,
  };

  // ---- 数值字段 ----
  /// Webtoon 左右边距占视口宽度的百分比（两侧合计）；仅 fitWidth 生效。
  static const int defaultWebtoonMarginPercent = 20;
  static const int maxWebtoonMarginPercent = 40;
  static const int webtoonMarginPercentStep = 5;

  /// 阅读器自动播放间隔（秒）。
  static const int defaultAutoPlayIntervalSeconds = 5;
  static const int minAutoPlayIntervalSeconds = 1;
  static const int maxAutoPlayIntervalSeconds = 60;

  /// 边距归一化：clamp 到 `[0, max]` 后按步长取整。
  static int normalizeWebtoonMarginPercent(int value) {
    final int clamped = value.clamp(0, maxWebtoonMarginPercent);
    return ((clamped / webtoonMarginPercentStep).round() *
            webtoonMarginPercentStep)
        .clamp(0, maxWebtoonMarginPercent);
  }

  /// 自动播放间隔归一化：clamp 到 `[min, max]`。
  static int clampAutoPlayIntervalSeconds(int seconds) =>
      seconds.clamp(minAutoPlayIntervalSeconds, maxAutoPlayIntervalSeconds);

  // ---- 字符串规范化（纯函数，不解析领域枚举）----

  /// 阅读模式 id 规范化：旧别名就地改名；未知/空串原样保留，
  /// 由 `reader` 的 `decode` 退回默认值并上报（不静默掩盖配置损坏）。
  static String normalizeReadingModeId(Object? raw) {
    if (raw is! String) {
      return defaultReadingModeId;
    }
    return legacyReadingModeIds[raw] ?? raw;
  }

  static String normalizeWebtoonZoomModeId(Object? raw) =>
      raw is String ? raw : defaultWebtoonZoomModeId;

  static String normalizeAutoPlayModeId(Object? raw) =>
      raw is String ? raw : defaultAutoPlayModeId;
}
