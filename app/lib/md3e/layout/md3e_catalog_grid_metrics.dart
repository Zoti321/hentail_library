import 'dart:math' as math;

import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_card.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import 'md3e_breakpoints.dart';

/// Resolved grid geometry for a viewport width (cell width matches delegate).
class Md3eCatalogGridLayout {
  const Md3eCatalogGridLayout({
    required this.sizeClass,
    required this.horizontalMargin,
    required this.crossAxisCount,
    required this.cellWidth,
    required this.gutter,
    required this.mainAxisExtent,
  });

  final Md3eWindowSizeClass sizeClass;
  final double horizontalMargin;
  final int crossAxisCount;
  final double cellWidth;
  final double gutter;

  /// Row height for [SliverGridDelegateWithFixedCrossAxisCount.mainAxisExtent].
  final double mainAxisExtent;
}

/// Responsive catalog grid cell metrics (aligned with production library tiers).
abstract final class Md3eCatalogGridMetrics {
  /// Max cross-axis extent per M3 window class (wider on large / XL).
  static double maxCrossAxisExtent(Md3eWindowSizeClass window) {
    return switch (window) {
      Md3eWindowSizeClass.compact => 168,
      Md3eWindowSizeClass.medium => 188,
      Md3eWindowSizeClass.expanded => 200,
      Md3eWindowSizeClass.large => 220,
      Md3eWindowSizeClass.extraLarge => 240,
    };
  }

  /// Gutter between grid cells (roomier than minimal M3 8dp; scales with width).
  static double gridSpacing(Md3eWindowSizeClass window) {
    return switch (window) {
      Md3eWindowSizeClass.compact => 16,
      Md3eWindowSizeClass.medium => 18,
      Md3eWindowSizeClass.expanded => 20,
      Md3eWindowSizeClass.large => 24,
      Md3eWindowSizeClass.extraLarge => 24,
    };
  }

  static int crossAxisCount(double viewportWidth, Md3eWindowSizeClass window) {
    final double horizontalMargin =
        Md3eLibraryBrowsePageMetrics.contentHorizontalPadding(window);
    final double innerWidth = math.max(
      0,
      viewportWidth - horizontalMargin * 2,
    );
    return _crossAxisCountForInnerWidth(
      innerWidth,
      window,
      gutter: gridSpacing(window),
    );
  }

  /// Full grid geometry for [viewportWidth], including row [mainAxisExtent].
  static Md3eCatalogGridLayout resolve({
    required double viewportWidth,
    required M3ESpacing spacing,
    double? horizontalMargin,
    bool hasSubtitle = true,
  }) {
    final Md3eCatalogGridLayout partial = _layoutForViewportWidth(
      viewportWidth,
      horizontalMargin: horizontalMargin,
    );
    return Md3eCatalogGridLayout(
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

  static Md3eCatalogGridLayout layoutForViewportWidth(double viewportWidth) {
    return _layoutForViewportWidth(viewportWidth);
  }

  static Md3eCatalogGridLayout _layoutForViewportWidth(
    double viewportWidth, {
    double? horizontalMargin,
  }) {
    final Md3eWindowSizeClass sizeClass =
        Md3eWindowSizeClass.fromWidth(viewportWidth);
    final double margin = horizontalMargin ??
        Md3eLibraryBrowsePageMetrics.contentHorizontalPadding(sizeClass);
    final double innerWidth = math.max(
      0,
      viewportWidth - margin * 2,
    );
    final double gutter = gridSpacing(sizeClass);
    final int count = _crossAxisCountForInnerWidth(
      innerWidth,
      sizeClass,
      gutter: gutter,
    );
    final double cellWidth = count <= 1
        ? innerWidth
        : (innerWidth - gutter * (count - 1)) / count;
    return Md3eCatalogGridLayout(
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
    Md3eWindowSizeClass window, {
    required double gutter,
  }) {
    if (innerWidth <= 0) {
      return 1;
    }
    final double maxExtent = maxCrossAxisExtent(window);
    return math.max(
      1,
      ((innerWidth + gutter) / (maxExtent + gutter)).floor(),
    );
  }

  /// Grid row height from the **actual** cell width (not [maxCrossAxisExtent]).
  /// Extra row height so [Md3eComicCard] typography / [M3ECard] chrome fits the cell.
  static const double mainAxisSlack = 8;

  static double mainAxisExtentForCellWidth(
    double cellWidth,
    M3ESpacing spacing, {
    bool hasSubtitle = true,
  }) {
    return Md3eComicCard.layoutMainAxisExtent(
      cardWidth: cellWidth,
      coverToInfoGap: spacing.md,
      infoBottomPadding: spacing.sm,
      hasSubtitle: hasSubtitle,
    ) +
        mainAxisSlack;
  }
}
