import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/spacing.dart';

/// Library 创建/编辑表单布局 token（Lab；对齐生产 dialog 640dp 宽）。
/// 页面水平留白统一来自 Md3ePageLayoutSpec，本类不再重复定义。
abstract final class Md3eLibraryEditFormMetrics {
  static const double maxWidth = 640;
  static const double sideTabColumnWidth = 168;

  static double sectionGap(Md3eWindowSizeClass sizeClass) {
    return sizeClass.isCompact ? Md3eSpacing.space16 : Md3eSpacing.space20;
  }
}
