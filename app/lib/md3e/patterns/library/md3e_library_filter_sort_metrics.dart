import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';

/// 书库筛选抽屉内容相对左缘的内边距（对齐生产 `kLibraryFilterSortDrawerContentInset`）。
const double kMd3eLibraryFilterSortDrawerContentInset = 16;

/// 筛选抽屉 scrim：32% 黑，不绑 token（MASTER §9 第 50 条）。
const Color kMd3eLibraryFilterSortDrawerScrimColor = Color(0x52000000);

/// 与生产 [LibraryLayoutTier] 一致的三档，用于抽屉宽度（600 / 1024 阈值）。
enum Md3eLibraryFilterSortLayoutTier { compact, medium, expanded }

Md3eLibraryFilterSortLayoutTier md3eLibraryFilterSortLayoutTierForWidth(
  double width,
) {
  if (width < 600) {
    return Md3eLibraryFilterSortLayoutTier.compact;
  }
  if (width < 1024) {
    return Md3eLibraryFilterSortLayoutTier.medium;
  }
  return Md3eLibraryFilterSortLayoutTier.expanded;
}

/// 筛选排序 end drawer 宽度（对齐 `libraryFilterSortDrawerWidth`）。
double md3eLibraryFilterSortDrawerWidth(
  Md3eLibraryFilterSortLayoutTier tier,
  double viewportWidth,
) {
  return switch (tier) {
    Md3eLibraryFilterSortLayoutTier.compact => math.min(
      math.max(viewportWidth * 0.55, 200),
      math.min(viewportWidth - 16, 400),
    ),
    Md3eLibraryFilterSortLayoutTier.medium => math.min(
      360,
      viewportWidth * 0.35,
    ),
    Md3eLibraryFilterSortLayoutTier.expanded => math.min(
      360,
      viewportWidth * 0.30,
    ),
  };
}

double md3eLibraryFilterSortDrawerWidthForViewport(double viewportWidth) {
  return md3eLibraryFilterSortDrawerWidth(
    md3eLibraryFilterSortLayoutTierForWidth(viewportWidth),
    viewportWidth,
  );
}

/// 模态 [M3ESideSheet] 宽度：在抽屉公式基础上抬高 compact/medium 下限，避免标题被截断。
double md3eLibraryFilterSortSideSheetWidthForViewport(double viewportWidth) {
  final Md3eLibraryFilterSortLayoutTier tier =
      md3eLibraryFilterSortLayoutTierForWidth(viewportWidth);
  final double drawerWidth = md3eLibraryFilterSortDrawerWidth(
    tier,
    viewportWidth,
  );
  return switch (tier) {
    Md3eLibraryFilterSortLayoutTier.compact => math.min(
      math.max(drawerWidth, 260),
      viewportWidth - 16,
    ),
    Md3eLibraryFilterSortLayoutTier.medium => math.max(drawerWidth, 320),
    Md3eLibraryFilterSortLayoutTier.expanded => drawerWidth,
  };
}

/// [M3ESideSheet] detached：M3 expanded 及以上（≥840）距窗口 16、四角圆角。
bool md3eLibraryFilterSortSideSheetDetachedForViewport(double viewportWidth) {
  return Md3eWindowSizeClass.fromWidth(viewportWidth).isAtLeastExpanded;
}

/// 筛选排序面板：compact / medium（宽度小于 840）用 [M3EBottomSheet]，expanded+ 用 [M3ESideSheet]。
bool md3eLibraryFilterSortPrefersBottomSheetForViewport(double viewportWidth) {
  return viewportWidth < Md3eBreakpoints.expanded;
}

/// 筛选 / 排序列表行与手风琴头的触控与字号（按书库三档布局）。
@immutable
class Md3eLibraryFilterSortRowMetrics {
  const Md3eLibraryFilterSortRowMetrics({
    required this.rowMinHeight,
    required this.optionLabelFontSize,
    required this.accordionTitleFontSize,
    required this.accordionHeaderMinHeight,
    required this.sortIconSize,
    required this.checkboxBoxSize,
    required this.checkboxHitSize,
    required this.checkboxTargetSize,
  });

  final double rowMinHeight;
  final double optionLabelFontSize;
  final double accordionTitleFontSize;
  final double accordionHeaderMinHeight;
  final double sortIconSize;

  /// [M3ECheckbox] 尺寸，与 [rowMinHeight] 对齐，避免状态层被裁切。
  final double checkboxBoxSize;
  final double checkboxHitSize;
  final double checkboxTargetSize;

  static Md3eLibraryFilterSortRowMetrics forViewportWidth(
    double viewportWidth,
  ) {
    return forTier(md3eLibraryFilterSortLayoutTierForWidth(viewportWidth));
  }

  static Md3eLibraryFilterSortRowMetrics forTier(
    Md3eLibraryFilterSortLayoutTier tier,
  ) {
    return switch (tier) {
      Md3eLibraryFilterSortLayoutTier.compact =>
        const Md3eLibraryFilterSortRowMetrics(
          rowMinHeight: 48,
          optionLabelFontSize: 14,
          accordionTitleFontSize: 15,
          accordionHeaderMinHeight: 48,
          sortIconSize: 16,
          checkboxBoxSize: 18,
          checkboxHitSize: 40,
          checkboxTargetSize: 48,
        ),
      Md3eLibraryFilterSortLayoutTier.medium =>
        const Md3eLibraryFilterSortRowMetrics(
          rowMinHeight: 44,
          optionLabelFontSize: 13,
          accordionTitleFontSize: 14,
          accordionHeaderMinHeight: 44,
          sortIconSize: 15,
          checkboxBoxSize: 18,
          checkboxHitSize: 36,
          checkboxTargetSize: 44,
        ),
      Md3eLibraryFilterSortLayoutTier.expanded =>
        const Md3eLibraryFilterSortRowMetrics(
          rowMinHeight: 40,
          optionLabelFontSize: 13,
          accordionTitleFontSize: 14,
          accordionHeaderMinHeight: 40,
          sortIconSize: 14,
          checkboxBoxSize: 18,
          checkboxHitSize: 32,
          checkboxTargetSize: 40,
        ),
    };
  }
}
