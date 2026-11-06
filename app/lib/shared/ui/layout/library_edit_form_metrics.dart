import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/spacing.dart';

/// Library 创建/编辑表单布局 token（Lab；对齐生产 dialog 640dp 宽）。
/// 页面水平留白统一来自 PageLayoutSpec，本类不再重复定义。
abstract final class LibraryEditFormMetrics {
  static const double maxWidth = 640;
  static const double sideTabColumnWidth = 168;

  static double sectionGap(WindowSizeClass sizeClass) {
    return sizeClass.isCompact ? Spacing.space16 : Spacing.space20;
  }
}
