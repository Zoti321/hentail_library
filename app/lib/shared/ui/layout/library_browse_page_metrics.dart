import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/fab_sizing.dart';
import 'package:hentai_library/shared/ui/layout/pinned_toolbar_chrome_metrics.dart';
import 'package:hentai_library/shared/ui/layout/spacing.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 书库浏览页的非留白类尺寸（回到顶部按钮、工具行间距、分页与 FAB 避让）。
/// 水平留白、页头上下内边距与页头到正文间距已统一到 Md3ePageLayoutSpec。
abstract final class Md3eLibraryBrowsePageMetrics {
  /// Sticky 页头抬起高度（[`M3EElevation.level1`]）。
  static const double pinnedHeaderElevation =
      Md3ePinnedToolbarChromeMetrics.pinnedHeaderElevation;

  static const double scrollToTopBottomInset = Md3eSpacing.space24;
  static const double scrollToTopShowViewportRatio = 1;
  static const double scrollToTopHideViewportRatio = 0.85;

  /// FAB 圆角（regular 规格默认 16；较大尺寸也统一为 16）。
  static const double scrollToTopCornerRadius = Md3eSpacing.space16;

  /// Gap between tabs row and view-mode controls.
  static double catalogToolbarToViewModeSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => 12,
      _ => 16,
    };
  }

  static double paginationVerticalSpacing(Md3eWindowSizeClass sizeClass) =>
      Md3eSpacing.paginationVertical(sizeClass);

  /// Extra scroll padding so the FAB does not cover pagination.
  static double scrollBottomInset(Md3eWindowSizeClass sizeClass) {
    final M3EFabSize fabSize = Md3eFabSizing.responsive(sizeClass);
    return paginationVerticalSpacing(sizeClass) +
        Md3eFabSizing.containerExtent(fabSize);
  }
}
