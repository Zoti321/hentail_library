import 'package:flutter/painting.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Layout mode for [LibraryPageHeader] (MASTER §5.1 漫画库粘滞头).
enum LibraryPageHeaderLayout {
  /// 标题 + 操作；漫画/系列 tabs 在 [LibraryCatalogToolbar]（随列表滚动）。
  titleAndActionsOnly,
}

/// MASTER §5.1 漫画库页内头部尺寸。
abstract final class LibraryPageHeaderMetrics {
  static const double actionIconSize = 20;

  /// 与旧 Baseline 库页 display target tabs 一致的两 tab 间距。
  static const double displayTargetTabGap = 16;

  static const double displayTargetIndicatorHeight = 2;

  /// 指示条比文案左右各宽 2dp（[`M3ETabTheme.indicatorInset`] 为负值）。
  static const double displayTargetIndicatorSideExtend = 2;

  /// 注入 [`LibraryDisplayTargetTabs`] 的 [`M3ETabTheme`]（无底部分割线、生产风指示条）。
  ///
  /// [`M3ETabs`] 的 hover / focus / press 由包内 [`M3ETappable`] + 本 theme 的
  /// state opacity 驱动；指示条位移用 [indicatorSpring]。Tab 命中区为矩形铺满槽位，
  /// 圆角 state layer 需改 M3E 组件或换胶囊分段控件。
  static M3ETabTheme displayTargetTabThemeFor(WindowSizeClass sizeClass) {
    final double barHeight = switch (sizeClass) {
      WindowSizeClass.compact => 40,
      _ => 44,
    };
    return M3ETabTheme(
      height: barHeight,
      dividerHeight: 0,
      indicatorHeight: displayTargetIndicatorHeight,
      indicatorInset: -displayTargetIndicatorSideExtend,
      indicatorCornerRadius: 1,
      indicatorSpring: M3EMotion.spatialDefault,
      scrollableTabPadding: displayTargetTabGap / 2,
      scrollableLeadingOffset: 0,
    );
  }

  /// Scrollable [`M3ETabs`] 条宽度（文案 + 水平 padding）。
  static double displayTargetTabsBarWidth({
    required List<String> tabLabels,
    required TextStyle labelStyle,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final double horizontalPadding = displayTargetTabGap / 2;
    double width = 0;
    for (final String label in tabLabels) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        maxLines: 1,
        textDirection: textDirection,
      )..layout();
      width += painter.size.width + horizontalPadding * 2;
      painter.dispose();
    }
    return width;
  }

  static LibraryPageHeaderLayout layoutFor(WindowSizeClass sizeClass) {
    return LibraryPageHeaderLayout.titleAndActionsOnly;
  }

  static double actionSpacing(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => 4,
      WindowSizeClass.medium => 8,
      _ => 8,
    };
  }
}
