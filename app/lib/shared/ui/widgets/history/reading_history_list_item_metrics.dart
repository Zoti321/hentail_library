import 'dart:math' as math;

import 'package:hentai_library/core/util/platform_desktop.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/library_browse_page_metrics.dart';
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
    required this.actionGap,
    required this.infoHorizontalGap,
  });

  final double coverWidth;
  final double coverHeight;
  final double coverRadius;
  final double containerRadius;
  final double horizontalPadding;
  final double verticalPadding;
  final M3EIconButtonSize actionButtonSize;

  /// 继续阅读与更多按钮之间的间距，随 [actionButtonSize] 变化。
  final double actionGap;
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

  /// 操作按钮尺寸：桌面端（鼠标）随窗口宽度收紧，窄窗口用 `sm`（40），
  /// 宽窗口（large 及以上）用 `md`（56）；移动端固定 `md`，保证触控目标不低于 48dp。
  static M3EIconButtonSize actionButtonSizeFor(
    Md3eWindowSizeClass window, {
    required bool desktop,
  }) {
    if (!desktop) {
      return M3EIconButtonSize.md;
    }
    return switch (window) {
      Md3eWindowSizeClass.compact ||
      Md3eWindowSizeClass.medium ||
      Md3eWindowSizeClass.expanded => M3EIconButtonSize.sm,
      Md3eWindowSizeClass.large ||
      Md3eWindowSizeClass.extraLarge => M3EIconButtonSize.md,
    };
  }

  /// [desktop] 为 null 时按当前运行平台判断（见 `isDesktop`）。
  static Md3eReadingHistoryListItemSpec specFor(
    Md3eWindowSizeClass window, {
    bool? desktop,
  }) {
    final M3EIconButtonSize actionButtonSize = actionButtonSizeFor(
      window,
      desktop: desktop ?? isDesktop,
    );
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
      actionButtonSize: actionButtonSize,
      actionGap: actionButtonSize == M3EIconButtonSize.md ? 8 : 4,
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
    final Md3eWindowSizeClass window = Md3eWindowSizeClass.fromWidth(
      viewportWidth,
    );
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
