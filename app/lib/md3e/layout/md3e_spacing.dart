import 'package:flutter/widgets.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:material_3_expressive/foundations/foundations.dart';

/// MD3E Lab 间距：组件内用 [of]（主题 [M3ESpacing]）；布局 metrics 用 [M3EDimensions] 常量。
///
/// 尺度与 Material 3 Expressive 一致（4dp 网格）：xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32；
/// 见包内 [M3ESpacing.regular] 与 [M3EDimensions]。
abstract final class Md3eSpacing {
  /// 当前主题的 Expressive 间距（随密度 / 主题变化）。
  static M3ESpacing of(BuildContext context) => M3ETheme.of(context).spacing;

  /// 默认 regular 尺度（无 [BuildContext] 时与主题默认一致）。
  static const M3ESpacing regular = M3ESpacing.regular();

  static const double space4 = M3EDimensions.space4;
  static const double space8 = M3EDimensions.space8;
  static const double space12 = M3EDimensions.space12;
  static const double space16 = M3EDimensions.space16;
  static const double space20 = M3EDimensions.space20;
  static const double space24 = M3EDimensions.space24;
  static const double space28 = M3EDimensions.space28;
  static const double space32 = M3EDimensions.space32;
  static const double space40 = M3EDimensions.space40;
  static const double space48 = M3EDimensions.space48;

  /// 粘滞顶栏 / 工具行与下方主内容区之间的纵向间距。
  static double majorSectionBelowHeader(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => space16,
      Md3eWindowSizeClass.medium => space20,
      _ => space24,
    };
  }

  /// 书库：视图模式行与目录网格之间的间距（与 [majorSectionBelowHeader] 同档）。
  static double catalogBodyBelowToolbar(Md3eWindowSizeClass sizeClass) =>
      majorSectionBelowHeader(sizeClass);

  /// 分页条与相邻区块的纵向间距。
  static double paginationVertical(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => space24,
      _ => space32,
    };
  }

  /// 滚动区底部留白（避免 FAB 遮挡分页等）。
  static double scrollBottomInset(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => space24,
      _ => space32,
    };
  }
}
