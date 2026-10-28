import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_comic_detail_page_metrics.dart';
import 'package:hentai_library/md3e/layout/md3e_spacing.dart';

/// Library 创建/编辑表单布局 token（Lab；对齐生产 dialog 640dp 宽）。
abstract final class Md3eLibraryEditFormMetrics {
  static const double maxWidth = 640;
  static const double sideTabColumnWidth = 168;

  static double contentHorizontalPadding(Md3eWindowSizeClass sizeClass) {
    return Md3eComicDetailPageMetrics.contentHorizontalPadding(sizeClass);
  }

  static double sectionGap(Md3eWindowSizeClass sizeClass) {
    return sizeClass.isCompact ? Md3eSpacing.space16 : Md3eSpacing.space20;
  }
}
