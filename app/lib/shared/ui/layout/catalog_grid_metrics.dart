import 'dart:math' as math;

import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_card.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Resolved grid geometry for a viewport width (cell width matches delegate).
class CatalogGridLayout {
  const CatalogGridLayout({
    required this.sizeClass,
    required this.horizontalMargin,
    required this.crossAxisCount,
    required this.cellWidth,
    required this.gutter,
    required this.mainAxisExtent,
  });

  final WindowSizeClass sizeClass;
  final double horizontalMargin;
  final int crossAxisCount;
  final double cellWidth;
  final double gutter;

  /// Row height for [SliverGridDelegateWithFixedCrossAxisCount.mainAxisExtent].
  final double mainAxisExtent;
}

/// Responsive catalog grid cell metrics (aligned with production library tiers).
abstract final class CatalogGridMetrics {
  /// 书库网格左右留白：与页面正文共用 [PageLayoutSpec]（含超宽窗口的居中偏移）。
  static double _horizontalInsetFor(double viewportWidth) {
    return PageLayoutSpec.resolve(
      LayoutContext.fromPlatform(viewportWidth: viewportWidth),
    ).horizontalInset;
  }

  /// Max cross-axis extent per M3 window class (wider on large / XL).
  static double maxCrossAxisExtent(WindowSizeClass window) {
    return switch (window) {
      WindowSizeClass.compact => 132,
      WindowSizeClass.medium => 148,
      WindowSizeClass.expanded => 160,
      WindowSizeClass.large => 172,
      WindowSizeClass.extraLarge => 184,
    };
  }

  /// Gutter between grid cells (roomier than minimal M3 8dp; scales with width).
  static double gridSpacing(WindowSizeClass window) {
    return switch (window) {
      WindowSizeClass.compact => 16,
      WindowSizeClass.medium => 18,
      WindowSizeClass.expanded => 20,
      WindowSizeClass.large => 24,
      WindowSizeClass.extraLarge => 24,
    };
  }

  static int crossAxisCount(double viewportWidth, WindowSizeClass window) {
    final double horizontalMargin = _horizontalInsetFor(viewportWidth);
    final double innerWidth = math.max(0, viewportWidth - horizontalMargin * 2);
    return _crossAxisCountForInnerWidth(
      innerWidth,
      window,
      gutter: gridSpacing(window),
    );
  }

  /// Full grid geometry for [viewportWidth], including row [mainAxisExtent].
  static CatalogGridLayout resolve({
    required double viewportWidth,
    required M3ESpacing spacing,
    double? horizontalMargin,
    bool hasSubtitle = true,
  }) {
    final CatalogGridLayout partial = _layoutForViewportWidth(
      viewportWidth,
      horizontalMargin: horizontalMargin,
    );
    return CatalogGridLayout(
      sizeClass: partial.sizeClass,
      horizontalMargin: partial.horizontalMargin,
      crossAxisCount: partial.crossAxisCount,
      cellWidth: partial.cellWidth,
      gutter: partial.gutter,
      mainAxisExtent: mainAxisExtentForCellWidth(
        partial.cellWidth,
        spacing,
        hasSubtitle: hasSubtitle,
      ),
    );
  }

  static CatalogGridLayout layoutForViewportWidth(double viewportWidth) {
    return _layoutForViewportWidth(viewportWidth);
  }

  static CatalogGridLayout _layoutForViewportWidth(
    double viewportWidth, {
    double? horizontalMargin,
  }) {
    final WindowSizeClass sizeClass = WindowSizeClass.fromWidth(viewportWidth);
    final double margin =
        horizontalMargin ?? _horizontalInsetFor(viewportWidth);
    final double innerWidth = math.max(0, viewportWidth - margin * 2);
    final double gutter = gridSpacing(sizeClass);
    final int count = _crossAxisCountForInnerWidth(
      innerWidth,
      sizeClass,
      gutter: gutter,
    );
    final double cellWidth = count <= 1
        ? innerWidth
        : (innerWidth - gutter * (count - 1)) / count;
    return CatalogGridLayout(
      sizeClass: sizeClass,
      horizontalMargin: margin,
      crossAxisCount: count,
      cellWidth: cellWidth,
      gutter: gutter,
      mainAxisExtent: 0,
    );
  }

  static int _crossAxisCountForInnerWidth(
    double innerWidth,
    WindowSizeClass window, {
    required double gutter,
  }) {
    if (innerWidth <= 0) {
      return 1;
    }
    final double maxExtent = maxCrossAxisExtent(window);
    return math.max(1, ((innerWidth + gutter) / (maxExtent + gutter)).floor());
  }

  /// Grid row height from the **actual** cell width (not [maxCrossAxisExtent]).
  /// Extra row height so [ComicCard] typography / [M3ECard] chrome fits the cell.
  static const double mainAxisSlack = 8;

  static double mainAxisExtentForCellWidth(
    double cellWidth,
    M3ESpacing spacing, {
    bool hasSubtitle = true,
  }) {
    return ComicCard.layoutMainAxisExtent(
          cardWidth: cellWidth,
          coverToInfoGap: spacing.md,
          infoBottomPadding: spacing.sm,
          hasSubtitle: hasSubtitle,
        ) +
        mainAxisSlack;
  }
}
