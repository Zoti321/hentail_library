import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_catalog_cover_viewport_notifier.g.dart';

/// 库页网格中应使用 [ThumbnailPriority.high] 加载封面的索引集合。
@Riverpod(keepAlive: true)
class LibraryCatalogCoverViewport extends _$LibraryCatalogCoverViewport {
  @override
  Set<int> build() => const <int>{};

  void updateRange({required int startIndex, required int endIndex}) {
    if (endIndex < startIndex) {
      if (state.isEmpty) {
        return;
      }
      state = const <int>{};
      return;
    }
    final Set<int> next = <int>{for (int i = startIndex; i <= endIndex; i++) i};
    if (setEquals(next, state)) {
      return;
    }
    state = next;
  }

  void clear() {
    if (state.isEmpty) {
      return;
    }
    state = const <int>{};
  }
}

int libraryGridCrossAxisCount(double viewportWidth, LibraryLayoutTier tier) {
  final double horizontalPadding = libraryContentHorizontalPadding(tier);
  final double innerWidth = math.max(0, viewportWidth - horizontalPadding * 2);
  final double maxExtent = libraryGridMaxCrossAxisExtent(tier);
  final double spacing = libraryGridSpacing(tier);
  if (innerWidth <= 0) {
    return 1;
  }
  return math.max(1, ((innerWidth + spacing) / (maxExtent + spacing)).floor());
}

/// 根据滚动偏移估算当前可见（含缓冲行）的网格索引范围。
({int startIndex, int endIndex}) visibleCatalogGridIndexRange({
  required double scrollPixels,
  required double viewportHeight,
  required double gridStartScrollOffset,
  required int itemCount,
  required double rowExtent,
  required double rowSpacing,
  required int crossAxisCount,
  int rowBuffer = 1,
}) {
  if (itemCount <= 0) {
    return (startIndex: 0, endIndex: -1);
  }
  final double relativeOffset = scrollPixels - gridStartScrollOffset;
  final double rowStride = rowExtent + rowSpacing;
  final int firstRow = relativeOffset <= 0
      ? 0
      : math.max(0, (relativeOffset / rowStride).floor() - rowBuffer);
  final int visibleRows =
      (viewportHeight / rowStride).ceil() + rowBuffer * 2 + 1;
  final int startIndex = math.min(itemCount - 1, firstRow * crossAxisCount);
  final int endIndex = math.min(
    itemCount - 1,
    ((firstRow + visibleRows) * crossAxisCount) - 1,
  );
  return (startIndex: startIndex, endIndex: math.max(startIndex, endIndex));
}

/// 库页网格封面视口估算所需的行高（卡片主轴 + 行间距）。
double libraryCatalogGridRowExtent(
  AppThemeTokens tokens,
  LibraryLayoutTier tier,
) {
  final double cardWidth = libraryGridMaxCrossAxisExtent(tier);
  final double coverHeight = cardWidth * 3 / 2;
  final double coverToInfoGap = tokens.spacing.md;
  final double titleLineHeight = tokens.text.bodyMd * 1.25;
  const double infoColumnSpacing = 6;
  final double metaLineHeight = tokens.text.labelXs - 1;
  final double infoBottomPad = tokens.spacing.sm;
  final double cardMainAxis =
      (coverHeight +
              coverToInfoGap +
              titleLineHeight +
              infoColumnSpacing +
              metaLineHeight +
              infoBottomPad)
          .ceil() +
      16;
  return cardMainAxis + libraryGridSpacing(tier);
}
