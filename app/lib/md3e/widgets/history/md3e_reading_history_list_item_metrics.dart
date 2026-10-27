import 'dart:math' as math;

import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Resolved geometry for one [Md3eReadingHistoryListItem] at a window class.
class Md3eReadingHistoryListItemSpec {
  const Md3eReadingHistoryListItemSpec({
    required this.coverWidth,
    required this.coverHeight,
    required this.coverRadius,
    required this.containerRadius,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.actionButtonSize,
    required this.infoHorizontalGap,
  });

  final double coverWidth;
  final double coverHeight;
  final double coverRadius;
  final double containerRadius;
  final double horizontalPadding;
  final double verticalPadding;
  final M3EIconButtonSize actionButtonSize;
  final double infoHorizontalGap;

  double get rowHeight => coverHeight + 2 * verticalPadding;
}

/// Responsive grid for reading-history rows.
class Md3eReadingHistoryListLayoutSpec {
  const Md3eReadingHistoryListLayoutSpec({
    required this.sizeClass,
    required this.columnCount,
    required this.tileWidth,
    required this.gap,
    required this.horizontalInset,
    required this.itemSpec,
  });

  final Md3eWindowSizeClass sizeClass;
  final int columnCount;
  final double tileWidth;
  final double gap;
  final double horizontalInset;
  final Md3eReadingHistoryListItemSpec itemSpec;
}

/// Breakpoints and sizing for reading-history list tiles.
abstract final class Md3eReadingHistoryListItemMetrics {
  static const double minTileWidthCompact = 280;

  static const double minTileWidthMultiColumn = 320;

  static Md3eReadingHistoryListItemSpec specFor(Md3eWindowSizeClass window) {
    final double coverWidth = switch (window) {
      Md3eWindowSizeClass.compact => 52,
      Md3eWindowSizeClass.medium => 56,
      Md3eWindowSizeClass.expanded => 60,
      Md3eWindowSizeClass.large => 64,
      Md3eWindowSizeClass.extraLarge => 68,
    };
    final double coverHeight = coverWidth * 3 / 2;
    return Md3eReadingHistoryListItemSpec(
      coverWidth: coverWidth,
      coverHeight: coverHeight,
      coverRadius: switch (window) {
        Md3eWindowSizeClass.compact => 8,
        _ => 10,
      },
      containerRadius: switch (window) {
        Md3eWindowSizeClass.compact => 16,
        Md3eWindowSizeClass.medium => 18,
        _ => 20,
      },
      horizontalPadding: switch (window) {
        Md3eWindowSizeClass.compact => 12,
        Md3eWindowSizeClass.medium => 14,
        _ => 16,
      },
      verticalPadding: switch (window) {
        Md3eWindowSizeClass.compact => 10,
        _ => 12,
      },
      actionButtonSize: M3EIconButtonSize.md,
      infoHorizontalGap: switch (window) {
        Md3eWindowSizeClass.compact => 12,
        _ => 14,
      },
    );
  }

  static int _columnCap(Md3eWindowSizeClass window) {
    return switch (window) {
      Md3eWindowSizeClass.compact => 1,
      Md3eWindowSizeClass.medium => 1,
      Md3eWindowSizeClass.expanded => 2,
      Md3eWindowSizeClass.large => 3,
      Md3eWindowSizeClass.extraLarge => 3,
    };
  }

  static double _gap(Md3eWindowSizeClass window) {
    return switch (window) {
      Md3eWindowSizeClass.compact => 12,
      Md3eWindowSizeClass.medium => 14,
      Md3eWindowSizeClass.expanded => 16,
      _ => 20,
    };
  }

  static Md3eReadingHistoryListLayoutSpec layoutForViewportWidth(
    double viewportWidth, {
    double? horizontalInset,
  }) {
    final Md3eWindowSizeClass window =
        Md3eWindowSizeClass.fromWidth(viewportWidth);
    final Md3eReadingHistoryListItemSpec itemSpec = specFor(window);
    final double inset =
        horizontalInset ??
        Md3eLibraryBrowsePageMetrics.contentHorizontalPadding(window);
    final double innerWidth = math.max(0, viewportWidth - inset * 2);
    final double gap = _gap(window);
    final int columnCap = _columnCap(window);
    final double minTile = columnCap == 1
        ? minTileWidthCompact
        : minTileWidthMultiColumn;
    final int columns = math.min(
      columnCap,
      math.max(1, ((innerWidth + gap) / (minTile + gap)).floor()),
    );
    final double tileWidth = columns <= 1
        ? innerWidth
        : (innerWidth - gap * (columns - 1)) / columns;

    return Md3eReadingHistoryListLayoutSpec(
      sizeClass: window,
      columnCount: columns,
      tileWidth: tileWidth,
      gap: gap,
      horizontalInset: inset,
      itemSpec: itemSpec,
    );
  }
}
