import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 粘滞顶栏的共享 chrome 常量（工具行高度、抬起阴影、内嵌水平内边距）。
/// 上下留白与页头到正文间距已统一到 Md3ePageLayoutSpec。
abstract final class Md3ePinnedToolbarChromeMetrics {
  static const double toolbarRowHeight = Md3ePageLayoutSpec.toolbarRowHeight;
  static const double innerHorizontalInset = 4;

  /// 内容在 [SliverPersistentHeader] 下滚动时抬起阴影（顶栏静止时为 level0）。
  static const double pinnedHeaderElevation = M3EElevation.level1;
}
