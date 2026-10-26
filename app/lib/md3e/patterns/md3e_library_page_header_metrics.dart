import 'package:flutter/painting.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Layout modes for [Md3eLibraryPageHeader] (MASTER §5.1 漫画库头部).
enum Md3eLibraryPageHeaderLayout {
  /// medium 及以上：标题 + 居中 [M3ETabs] + 操作，单行 44dp。
  singleRowWithTabs,

  /// compact：工具栏行 + 下方全宽 [M3ETabs]（fill）。
  twoRowTabsBelow,
}

/// MASTER §5.1 漫画库页内头部尺寸。
abstract final class Md3eLibraryPageHeaderMetrics {
  static const double toolbarHeight = 44;
  static const double verticalPadding = 10;
  static const double tabsRowTopGap = 4;
  static const double actionIconSize = 20;

  static Md3eLibraryPageHeaderLayout layoutFor(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact =>
        Md3eLibraryPageHeaderLayout.twoRowTabsBelow,
      _ => Md3eLibraryPageHeaderLayout.singleRowWithTabs,
    };
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

  /// [M3ETabs] 响应式尺寸（secondary、fill 场景）。
  static M3ETabTheme tabThemeFor(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => const M3ETabTheme(
        height: 40,
        secondaryIndicatorHeight: 2,
        scrollableTabPadding: 12,
      ),
      Md3eWindowSizeClass.medium => const M3ETabTheme(
        height: 44,
        secondaryIndicatorHeight: 2,
        scrollableTabPadding: 14,
      ),
      Md3eWindowSizeClass.expanded => const M3ETabTheme(
        height: 44,
        secondaryIndicatorHeight: 2,
      ),
      Md3eWindowSizeClass.large || Md3eWindowSizeClass.extraLarge =>
        M3ETabTheme.defaults,
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
