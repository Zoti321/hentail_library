import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/theme/app_font.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 书库筛选抽屉内容相对左缘的内边距（对齐生产 `kLibraryFilterSortDrawerContentInset`）。
const double kLibraryFilterSortDrawerContentInset = 16;

/// 筛选抽屉 scrim：32% 黑，不绑 token（MASTER §9 第 50 条）。
const Color kLibraryFilterSortDrawerScrimColor = Color(0x52000000);

/// 与旧 Baseline 库页布局档位一致的三档，用于抽屉宽度（600 / 1024 阈值）。
enum LibraryFilterSortLayoutTier { compact, medium, expanded }

LibraryFilterSortLayoutTier libraryFilterSortLayoutTierForWidth(double width) {
  if (width < 600) {
    return LibraryFilterSortLayoutTier.compact;
  }
  if (width < 1024) {
    return LibraryFilterSortLayoutTier.medium;
  }
  return LibraryFilterSortLayoutTier.expanded;
}

/// 筛选排序 end drawer 宽度（沿用旧 Baseline 库页的断点策略）。
double libraryFilterSortDrawerWidth(
  LibraryFilterSortLayoutTier tier,
  double viewportWidth,
) {
  return switch (tier) {
    LibraryFilterSortLayoutTier.compact => math.min(
      math.max(viewportWidth * 0.55, 200),
      math.min(viewportWidth - 16, 400),
    ),
    LibraryFilterSortLayoutTier.medium => math.min(360, viewportWidth * 0.35),
    LibraryFilterSortLayoutTier.expanded => math.min(360, viewportWidth * 0.30),
  };
}

double libraryFilterSortDrawerWidthForViewport(double viewportWidth) {
  return libraryFilterSortDrawerWidth(
    libraryFilterSortLayoutTierForWidth(viewportWidth),
    viewportWidth,
  );
}

/// 模态 [M3ESideSheet] 宽度：在抽屉公式基础上抬高 compact/medium 下限，避免标题被截断。
double libraryFilterSortSideSheetWidthForViewport(double viewportWidth) {
  final LibraryFilterSortLayoutTier tier = libraryFilterSortLayoutTierForWidth(
    viewportWidth,
  );
  final double drawerWidth = libraryFilterSortDrawerWidth(tier, viewportWidth);
  return switch (tier) {
    LibraryFilterSortLayoutTier.compact => math.min(
      math.max(drawerWidth, 260),
      viewportWidth - 16,
    ),
    LibraryFilterSortLayoutTier.medium => math.max(drawerWidth, 320),
    LibraryFilterSortLayoutTier.expanded => drawerWidth,
  };
}

/// [M3ESideSheet] detached：M3 expanded 及以上（≥840）距窗口 16、四角圆角。
bool libraryFilterSortSideSheetDetachedForViewport(double viewportWidth) {
  return WindowSizeClass.fromWidth(viewportWidth).isAtLeastExpanded;
}

/// 筛选排序面板：compact / medium（宽度小于 840）用 [M3EBottomSheet]，expanded+ 用 [M3ESideSheet]。
bool libraryFilterSortPrefersBottomSheetForViewport(double viewportWidth) {
  return viewportWidth < Breakpoints.expanded;
}

/// Side sheet 标题排版：与阅读设置面板一致用 titleLarge，并保证应用字体。
///
/// [topElementsGap] 用 M3 默认 12，给标题与「筛选」分区留出呼吸感（曾为空标题时压到 8）。
M3ESideSheetTheme libraryFilterSortSideSheetTheme(M3EThemeData m3e) {
  return m3e.sideSheetTheme.copyWith(
    horizontalPadding: 16,
    topElementsGap: 12,
    headlineMaxLines: 1,
    headlineTextStyle: m3e.typeScale.titleLarge.copyWith(
      fontFamily: m3e.typeScale.bodyLarge.fontFamily ?? kAppFontFamily,
    ),
  );
}

/// 筛选 / 排序列表行与手风琴头的触控与字号（按书库三档布局）。
@immutable
class LibraryFilterSortRowMetrics {
  const LibraryFilterSortRowMetrics({
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

  static LibraryFilterSortRowMetrics forViewportWidth(double viewportWidth) {
    return forTier(libraryFilterSortLayoutTierForWidth(viewportWidth));
  }

  static LibraryFilterSortRowMetrics forTier(LibraryFilterSortLayoutTier tier) {
    return switch (tier) {
      LibraryFilterSortLayoutTier.compact => const LibraryFilterSortRowMetrics(
        rowMinHeight: 48,
        optionLabelFontSize: 14,
        accordionTitleFontSize: 15,
        accordionHeaderMinHeight: 48,
        sortIconSize: 16,
        checkboxBoxSize: 18,
        checkboxHitSize: 40,
        checkboxTargetSize: 48,
      ),
      LibraryFilterSortLayoutTier.medium => const LibraryFilterSortRowMetrics(
        rowMinHeight: 44,
        optionLabelFontSize: 13,
        accordionTitleFontSize: 14,
        accordionHeaderMinHeight: 44,
        sortIconSize: 15,
        checkboxBoxSize: 18,
        checkboxHitSize: 36,
        checkboxTargetSize: 44,
      ),
      LibraryFilterSortLayoutTier.expanded => const LibraryFilterSortRowMetrics(
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
