import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_page/widgets/library_layout_constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_catalog_cover_viewport_notifier.g.dart';

/// Content scroll offset of [key]'s render object within its [Scrollable].
///
/// Works for both [RenderBox] and [RenderSliver] (e.g. [SliverMainAxisGroup]
/// behind [CatalogBlocksSliverGroup]) via [RenderObject.getTransformTo] —
/// never cast the keyed render object to [RenderBox].
double? measureScrollableKeyedContentOffset(GlobalKey key) {
  final BuildContext? targetContext = key.currentContext;
  final ScrollableState? scrollable = targetContext == null
      ? null
      : Scrollable.maybeOf(targetContext);
  final RenderObject? targetRender = targetContext?.findRenderObject();
  final RenderObject? scrollableRender = scrollable?.context.findRenderObject();
  if (targetRender == null ||
      scrollable == null ||
      scrollableRender is! RenderBox) {
    return null;
  }
  final double topInViewport = MatrixUtils.transformPoint(
    targetRender.getTransformTo(scrollableRender),
    Offset.zero,
  ).dy;
  return scrollable.position.pixels + topInViewport;
}

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
