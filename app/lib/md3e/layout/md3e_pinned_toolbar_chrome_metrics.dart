import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_spacing.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 漫画库 / 漫画详情 / 系列详情粘滞顶栏共用尺寸与 elevation。
abstract final class Md3ePinnedToolbarChromeMetrics {
  static const double toolbarRowHeight = 48;
  static const double innerHorizontalInset = 4;

  /// 内容在 [SliverPersistentHeader] 下滚动时抬起阴影（顶栏静止时为 level0）。
  static const double pinnedHeaderElevation = M3EElevation.level1;

  static double topPadding(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => 6,
      _ => 8,
    };
  }

  static double bottomPadding(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => 0,
      _ => 2,
    };
  }

  /// 粘滞顶栏与首屏正文之间的间距（漫画 / 系列详情共用）。
  static double bodyBelowHeaderSpacing(Md3eWindowSizeClass sizeClass) =>
      Md3eSpacing.majorSectionBelowHeader(sizeClass);
}
