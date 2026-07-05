import 'package:json_annotation/json_annotation.dart';

/// 全局阅读模式（v1 仅 LTR）。
@JsonEnum(alwaysCreate: true)
enum ReadingMode {
  @JsonValue('paged')
  paged,
  @JsonValue('continuousVertical')
  continuousVertical,
  @JsonValue('dualPage')
  dualPage,
  @JsonValue('dualPageNoCover')
  dualPageNoCover,
}

extension ReadingModeX on ReadingMode {
  String get labelZh {
    switch (this) {
      case ReadingMode.paged:
        return '翻页';
      case ReadingMode.continuousVertical:
        return '长条';
      case ReadingMode.dualPage:
        return '双页';
      case ReadingMode.dualPageNoCover:
        return '双页（封面独立）';
    }
  }

  bool get isContinuousVertical => this == ReadingMode.continuousVertical;

  bool get supportsAutoPlay => !isContinuousVertical;

  bool get isDualPageMode =>
      this == ReadingMode.dualPage || this == ReadingMode.dualPageNoCover;

  bool get usesSpreadNavigation => isDualPageMode;
}

const ReadingMode kDefaultReadingMode = ReadingMode.paged;

ReadingMode readingModeFromJson(Object? json) {
  if (json is String) {
    for (final MapEntry<ReadingMode, String> entry
        in _$ReadingModeEnumMap.entries) {
      if (entry.value == json) {
        return entry.key;
      }
    }
  }
  return kDefaultReadingMode;
}

String readingModeToJson(ReadingMode mode) => _$ReadingModeEnumMap[mode]!;

const _$ReadingModeEnumMap = {
  ReadingMode.paged: 'paged',
  ReadingMode.continuousVertical: 'continuousVertical',
  ReadingMode.dualPage: 'dualPage',
  ReadingMode.dualPageNoCover: 'dualPageNoCover',
};
