import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/fab_sizing.dart';
import 'package:hentai_library/shared/ui/layout/pinned_toolbar_chrome_metrics.dart';
import 'package:hentai_library/shared/ui/layout/spacing.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 书库浏览页的非留白类尺寸（回到顶部按钮、工具行间距、分页与 FAB 避让）。
/// 水平留白、页头上下内边距与页头到正文间距已统一到 PageLayoutSpec。
abstract final class LibraryBrowsePageMetrics {
  /// Sticky 页头抬起高度（[`M3EElevation.level1`]）。
  static const double pinnedHeaderElevation =
      PinnedToolbarChromeMetrics.pinnedHeaderElevation;

  static const double scrollToTopBottomInset = Spacing.space24;
  static const double scrollToTopShowViewportRatio = 1;
  static const double scrollToTopHideViewportRatio = 0.85;

  /// FAB 圆角（regular 规格默认 16；较大尺寸也统一为 16）。
  static const double scrollToTopCornerRadius = Spacing.space16;

  /// Gap between tabs row and view-mode controls.
  static double catalogToolbarToViewModeSpacing(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => 12,
      _ => 16,
    };
  }

  static double paginationVerticalSpacing(WindowSizeClass sizeClass) =>
      Spacing.paginationVertical(sizeClass);

  /// Extra scroll padding so the FAB does not cover pagination.
  static double scrollBottomInset(WindowSizeClass sizeClass) {
    final M3EFabSize fabSize = FabSizing.responsive(sizeClass);
    return paginationVerticalSpacing(sizeClass) +
        FabSizing.containerExtent(fabSize);
  }
}
