import 'auto_play_interval.dart';
import 'auto_play_mode.dart';
import 'reading_mode.dart';

/// L2 领域值对象：阅读偏好的语义形态（枚举字段）。
///
/// 由 `reader/public/reading_preferences_acl.dart` 从持久化原语记录解码而来；
/// `app_settings` 永远看不到本类型（ADR-0046）。
class ReadingPreferences {
  const ReadingPreferences({
    required this.readingMode,
    required this.webtoonZoomMode,
    required this.webtoonMarginPercent,
    required this.autoPlayMode,
    required this.autoPlayIntervalSeconds,
  });

  /// 全默认值（`app_settings` 尚未加载时的兜底）。
  const ReadingPreferences.defaults()
    : readingMode = kDefaultReadingMode,
      webtoonZoomMode = kDefaultWebtoonZoomMode,
      webtoonMarginPercent = kDefaultWebtoonMarginPercent,
      autoPlayMode = kDefaultAutoPlayMode,
      autoPlayIntervalSeconds = kReaderAutoPlayIntervalDefault;

  final ReadingMode readingMode;
  final WebtoonZoomMode webtoonZoomMode;
  final int webtoonMarginPercent;
  final AutoPlayMode autoPlayMode;
  final int autoPlayIntervalSeconds;

  ReadingPreferences copyWith({
    ReadingMode? readingMode,
    WebtoonZoomMode? webtoonZoomMode,
    int? webtoonMarginPercent,
    AutoPlayMode? autoPlayMode,
    int? autoPlayIntervalSeconds,
  }) {
    return ReadingPreferences(
      readingMode: readingMode ?? this.readingMode,
      webtoonZoomMode: webtoonZoomMode ?? this.webtoonZoomMode,
      webtoonMarginPercent: webtoonMarginPercent ?? this.webtoonMarginPercent,
      autoPlayMode: autoPlayMode ?? this.autoPlayMode,
      autoPlayIntervalSeconds:
          autoPlayIntervalSeconds ?? this.autoPlayIntervalSeconds,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReadingPreferences &&
        other.readingMode == readingMode &&
        other.webtoonZoomMode == webtoonZoomMode &&
        other.webtoonMarginPercent == webtoonMarginPercent &&
        other.autoPlayMode == autoPlayMode &&
        other.autoPlayIntervalSeconds == autoPlayIntervalSeconds;
  }

  @override
  int get hashCode => Object.hash(
    readingMode,
    webtoonZoomMode,
    webtoonMarginPercent,
    autoPlayMode,
    autoPlayIntervalSeconds,
  );

  @override
  String toString() =>
      'ReadingPreferences(readingMode: $readingMode, '
      'webtoonZoomMode: $webtoonZoomMode, '
      'webtoonMarginPercent: $webtoonMarginPercent, '
      'autoPlayMode: $autoPlayMode, '
      'autoPlayIntervalSeconds: $autoPlayIntervalSeconds)';
}
