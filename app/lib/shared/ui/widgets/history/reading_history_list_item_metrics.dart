import 'dart:math' as math;

import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';

import 'package:hentai_library/core/util/platform_desktop.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Resolved geometry for one [ReadingHistoryListItem] at a window class.
class ReadingHistoryListItemSpec {
  const ReadingHistoryListItemSpec({
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
class ReadingHistoryListLayoutSpec {
  const ReadingHistoryListLayoutSpec({
    required this.sizeClass,
    required this.columnCount,
    required this.tileWidth,
    required this.gap,
    required this.horizontalInset,
    required this.itemSpec,
  });

  final WindowSizeClass sizeClass;
  final int columnCount;
  final double tileWidth;
  final double gap;
  final double horizontalInset;
  final ReadingHistoryListItemSpec itemSpec;
}

/// Breakpoints and sizing for reading-history list tiles.
abstract final class ReadingHistoryListItemMetrics {
  static const double minTileWidthCompact = 280;

  static const double minTileWidthMultiColumn = 320;

  /// 操作按钮尺寸：桌面端（鼠标）随窗口宽度收紧，窄窗口用 `sm`（40），
  /// 宽窗口（large 及以上）用 `md`（56）；移动端固定 `md`，保证触控目标不低于 48dp。
  static M3EIconButtonSize actionButtonSizeFor(
    WindowSizeClass window, {
    required bool desktop,
  }) {
    if (!desktop) {
      return M3EIconButtonSize.md;
    }
    return switch (window) {
      WindowSizeClass.compact ||
      WindowSizeClass.medium ||
      WindowSizeClass.expanded => M3EIconButtonSize.sm,
      WindowSizeClass.large ||
      WindowSizeClass.extraLarge => M3EIconButtonSize.md,
    };
  }

  /// [desktop] 为 null 时按当前运行平台判断（见 `isDesktop`）。
  static ReadingHistoryListItemSpec specFor(
    WindowSizeClass window, {
    bool? desktop,
  }) {
    final M3EIconButtonSize actionButtonSize = actionButtonSizeFor(
      window,
      desktop: desktop ?? isDesktop,
    );
    final double coverWidth = switch (window) {
      WindowSizeClass.compact => 52,
      WindowSizeClass.medium => 56,
      WindowSizeClass.expanded => 60,
      WindowSizeClass.large => 64,
      WindowSizeClass.extraLarge => 68,
    };
    final double coverHeight = coverWidth * 3 / 2;
    return ReadingHistoryListItemSpec(
      coverWidth: coverWidth,
      coverHeight: coverHeight,
      coverRadius: switch (window) {
        WindowSizeClass.compact => 8,
        _ => 10,
      },
      containerRadius: switch (window) {
        WindowSizeClass.compact => 16,
        WindowSizeClass.medium => 18,
        _ => 20,
      },
      horizontalPadding: switch (window) {
        WindowSizeClass.compact => 12,
        WindowSizeClass.medium => 14,
        _ => 16,
      },
      verticalPadding: switch (window) {
        WindowSizeClass.compact => 10,
        _ => 12,
      },
      actionButtonSize: actionButtonSize,
      actionGap: actionButtonSize == M3EIconButtonSize.md ? 8 : 4,
      infoHorizontalGap: switch (window) {
        WindowSizeClass.compact => 12,
        _ => 14,
      },
    );
  }

  static int _columnCap(WindowSizeClass window) {
    return switch (window) {
      WindowSizeClass.compact => 1,
      WindowSizeClass.medium => 1,
      WindowSizeClass.expanded => 2,
      WindowSizeClass.large => 3,
      WindowSizeClass.extraLarge => 3,
    };
  }

  static double _gap(WindowSizeClass window) {
    return switch (window) {
      WindowSizeClass.compact => 12,
      WindowSizeClass.medium => 14,
      WindowSizeClass.expanded => 16,
      _ => 20,
    };
  }

  static ReadingHistoryListLayoutSpec layoutForViewportWidth(
    double viewportWidth, {
    double? horizontalInset,
  }) {
    final WindowSizeClass window = WindowSizeClass.fromWidth(viewportWidth);
    final ReadingHistoryListItemSpec itemSpec = specFor(window);
    final double inset =
        horizontalInset ??
        PageLayoutSpec.resolve(
          LayoutContext.fromPlatform(viewportWidth: viewportWidth),
        ).horizontalInset;
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

    return ReadingHistoryListLayoutSpec(
      sizeClass: window,
      columnCount: columns,
      tileWidth: tileWidth,
      gap: gap,
      horizontalInset: inset,
      itemSpec: itemSpec,
    );
  }
}
