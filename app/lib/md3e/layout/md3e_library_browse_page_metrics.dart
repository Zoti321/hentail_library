import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// M3 layout margins / section spacing for [Md3eLibraryBrowsePage].
///
/// Horizontal margins align with [Md3eLibraryPageHeaderMetrics.contentHorizontalPadding]
/// (M3 window-size margins). Vertical gaps follow M3 grids & spacing (16dp compact,
/// 24dp medium+ between major blocks).
abstract final class Md3eLibraryBrowsePageMetrics {
  /// Sticky 页头抬起高度（[`M3EElevation.level1`]）。
  static const double pinnedHeaderElevation = M3EElevation.level1;

  static const double scrollToTopBottomInset = 24;
  static const double scrollToTopShowViewportRatio = 1;
  static const double scrollToTopHideViewportRatio = 0.85;

  /// FAB 圆角（regular 规格默认 16；较大尺寸也统一为 16）。
  static const double scrollToTopCornerRadius = 16;

  /// 响应式 [M3EFab] 尺寸（56 / 80 / 96dp 容器）。
  static M3EFabSize scrollToTopFabSize(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact ||
      Md3eWindowSizeClass.medium => M3EFabSize.regular,
      Md3eWindowSizeClass.expanded => M3EFabSize.medium,
      Md3eWindowSizeClass.large || Md3eWindowSizeClass.extraLarge =>
        M3EFabSize.large,
    };
  }

  static double _scrollToTopFabContainerExtent(M3EFabSize size) {
    return switch (size) {
      M3EFabSize.small => 40,
      M3EFabSize.regular => 56,
      M3EFabSize.medium => 80,
      M3EFabSize.large => 96,
    };
  }

  static double contentHorizontalPadding(Md3eWindowSizeClass sizeClass) {
    return Md3eLibraryPageHeaderMetrics.contentHorizontalPadding(sizeClass);
  }

  /// Gap below pinned header before tabs + count row (header already has bottom inset).
  static double catalogToolbarTopSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => 12,
      _ => 16,
    };
  }

  /// Gap between tabs row and view-mode controls.
  static double catalogToolbarToViewModeSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => 12,
      _ => 16,
    };
  }

  /// Gap between view-mode row and grid / list body.
  static double catalogBodyTopSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => 16,
      _ => 24,
    };
  }

  static double paginationVerticalSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => 24,
      _ => 32,
    };
  }

  /// Extra scroll padding so the FAB does not cover pagination.
  static double scrollBottomInset(Md3eWindowSizeClass sizeClass) {
    final M3EFabSize fabSize = scrollToTopFabSize(sizeClass);
    return paginationVerticalSpacing(sizeClass) +
        _scrollToTopFabContainerExtent(fabSize);
  }
}
