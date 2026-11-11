import 'package:hentai_library/design-system/design_system.dart';

/// Library 创建/编辑表单布局 token（Lab；对齐生产 dialog 640dp 宽）。
/// 页面水平留白统一来自 PageLayoutSpec，本类不再重复定义。
abstract final class LibraryEditFormMetrics {
  static const double maxWidth = 640;
  static const double sideTabColumnWidth = 168;

  /// Detail 区水平内边距（侧栏间隙之外，字段左右留白）。
  static const double detailContentHorizontalInset = Spacing.space16;

  static double sectionGap(WindowSizeClass sizeClass) {
    // 与设置页 list-detail paneGap（24）对齐。
    return sizeClass.isCompact ? Spacing.space16 : Spacing.space24;
  }
}
