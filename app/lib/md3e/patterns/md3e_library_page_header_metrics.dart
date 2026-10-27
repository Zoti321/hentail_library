import 'package:flutter/painting.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
/// Layout modes for [Md3eLibraryPageHeader] (MASTER §5.1 漫画库头部).
enum Md3eLibraryPageHeaderLayout {
  /// 标题 + 居中 [M3ETabs] + 操作，单行 44dp（Widgetbook 页头预览等）。
  singleRowWithTabs,

  /// 标题 + 操作；漫画/系列 tabs 在 [Md3eLibraryCatalogToolbar]（随列表滚动）。
  titleAndActionsOnly,
}

/// MASTER §5.1 漫画库页内头部尺寸。
abstract final class Md3eLibraryPageHeaderMetrics {
  static const double toolbarHeight = 44;
  /// 与生产 `kLibraryHeaderVerticalPadding` 一致；页顶不再额外叠一层 browse 外边距。
  static const double verticalPadding = 10;

  /// Browse 粘滞头无内嵌 tabs 时，缩小底距以免与 [Md3eLibraryBrowsePageMetrics.catalogToolbarTopSpacing] 叠成过大空隙。
  static const double browsePinnedHeaderBottomPadding = 4;
  static const double actionIconSize = 20;

  /// 与生产 [LibraryDisplayTargetTabs] 一致的两 tab 间距。
  static const double displayTargetTabGap = 16;

  static const double displayTargetIndicatorHeight = 2;

  /// 指示条比文案左右各宽 2dp（[`M3ETabTheme.indicatorInset`] 为负值）。
  static const double displayTargetIndicatorSideExtend = 2;

  static const List<String> _displayTargetTabLabels = <String>['漫画', '系列'];

  /// 注入 [`Md3eLibraryDisplayTargetTabs`] 的 [`M3ETabTheme`]（无底部分割线、生产风指示条）。
  ///
  /// [`M3ETabs`] 的 hover / focus / press 由包内 [`M3ETappable`] + 本 theme 的
  /// state opacity 驱动；指示条位移用 [indicatorSpring]。Tab 命中区为矩形铺满槽位，
  /// 圆角 state layer 需改 M3E 组件或换胶囊分段控件。
  static M3ETabTheme displayTargetTabThemeFor(Md3eWindowSizeClass sizeClass) {
    final double barHeight = switch (sizeClass) {
      Md3eWindowSizeClass.compact => 40,
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
    required TextStyle labelStyle,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final double horizontalPadding = displayTargetTabGap / 2;
    double width = 0;
    for (final String label in _displayTargetTabLabels) {
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

  static Md3eLibraryPageHeaderLayout layoutFor(
    Md3eWindowSizeClass sizeClass,
  ) {
    return Md3eLibraryPageHeaderLayout.singleRowWithTabs;
  }

  /// 单行布局时居中 tabs 区域宽度（避免与标题、动作重叠）。
  static double centeredTabsMaxWidth(
    double viewportWidth,
    Md3eWindowSizeClass sizeClass,
  ) {
    if (viewportWidth <= 0 || !viewportWidth.isFinite) {
      return 320;
    }
    return switch (sizeClass) {
      Md3eWindowSizeClass.medium => (viewportWidth * 0.38).clamp(200, 300),
      Md3eWindowSizeClass.expanded => (viewportWidth * 0.34).clamp(220, 360),
      Md3eWindowSizeClass.large => (viewportWidth * 0.36).clamp(260, 400),
      Md3eWindowSizeClass.extraLarge => (viewportWidth * 0.36).clamp(280, 420),
      _ => (viewportWidth * 0.36).clamp(240, 420),
    };
  }

  static double contentHorizontalPadding(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => 16,
      Md3eWindowSizeClass.medium => 28,
      _ => 48,
    };
  }

  static double titleFontSize(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.extraLarge || Md3eWindowSizeClass.large => 32,
      Md3eWindowSizeClass.expanded => 28,
      Md3eWindowSizeClass.medium || Md3eWindowSizeClass.compact => 24,
    };
  }

  static FontWeight titleFontWeight(Md3eWindowSizeClass sizeClass) {
    return sizeClass.isCompact ? FontWeight.w700 : FontWeight.w600;
  }

  static double actionSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => 4,
      Md3eWindowSizeClass.medium => 8,
      _ => 8,
    };
  }
}
