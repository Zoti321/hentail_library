import 'package:json_annotation/json_annotation.dart';

/// 全局阅读模式（v1 仅 LTR）。
@JsonEnum(alwaysCreate: true)
enum ReadingMode {
  @JsonValue('paged')
  paged,
  @JsonValue('webtoon')
  webtoon,
  @JsonValue('dualPage')
  dualPage,
  @JsonValue('dualPageNoCover')
  dualPageNoCover,
}

/// 顶栏阅读设置 Dialog 中的一级模式。
enum ReaderModeCategory { paged, webtoon }

/// 翻页模式下的页面布局（二级选项）。
enum PagedLayout { single, dual, dualNoCover }

/// Webtoon 缩放模式（二级选项，UI 占位）。
enum WebtoonZoomMode { fitWidth, originalSize }

extension ReaderModeCategoryX on ReaderModeCategory {
  String get labelZh => switch (this) {
    ReaderModeCategory.paged => '翻页',
    ReaderModeCategory.webtoon => 'Webtoon',
  };
}

extension PagedLayoutX on PagedLayout {
  String get labelZh => switch (this) {
    PagedLayout.single => '单页',
    PagedLayout.dual => '双页',
    PagedLayout.dualNoCover => '双页（封面独立）',
  };

  ReadingMode toReadingMode() => switch (this) {
    PagedLayout.single => ReadingMode.paged,
    PagedLayout.dual => ReadingMode.dualPage,
    PagedLayout.dualNoCover => ReadingMode.dualPageNoCover,
  };
}

extension WebtoonZoomModeX on WebtoonZoomMode {
  String get labelZh => switch (this) {
    WebtoonZoomMode.fitWidth => '适应宽度',
    WebtoonZoomMode.originalSize => '原始尺寸',
  };
}

extension ReadingModeX on ReadingMode {
  String get labelZh {
    switch (this) {
      case ReadingMode.paged:
        return '翻页';
      case ReadingMode.webtoon:
        return 'Webtoon';
      case ReadingMode.dualPage:
        return '双页';
      case ReadingMode.dualPageNoCover:
        return '双页（封面独立）';
    }
  }

  bool get isWebtoon => this == ReadingMode.webtoon;

  bool get isPagedFamily => !isWebtoon;

  bool get supportsAutoPlay => !isWebtoon;

  bool get isDualPageMode =>
      this == ReadingMode.dualPage || this == ReadingMode.dualPageNoCover;

  bool get usesSpreadNavigation => isDualPageMode;

  ReaderModeCategory get category =>
      isWebtoon ? ReaderModeCategory.webtoon : ReaderModeCategory.paged;

  PagedLayout? get pagedLayout => switch (this) {
    ReadingMode.paged => PagedLayout.single,
    ReadingMode.dualPage => PagedLayout.dual,
    ReadingMode.dualPageNoCover => PagedLayout.dualNoCover,
    ReadingMode.webtoon => null,
  };
}

const ReadingMode kDefaultReadingMode = ReadingMode.paged;

ReadingMode readingModeFromJson(Object? json) {
  if (json is String) {
    if (json == 'continuousVertical') {
      return ReadingMode.webtoon;
    }
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
  ReadingMode.webtoon: 'webtoon',
  ReadingMode.dualPage: 'dualPage',
  ReadingMode.dualPageNoCover: 'dualPageNoCover',
};
