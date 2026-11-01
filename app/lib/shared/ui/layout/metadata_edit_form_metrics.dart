import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_page_metrics.dart';
import 'package:hentai_library/shared/ui/layout/spacing.dart';

/// 漫画 / 系列元数据编辑表单布局 token（Lab）。
abstract final class Md3eMetadataEditFormMetrics {
  static const double comicMaxWidth = 720;
  static const double seriesMaxWidth = 480;

  static double contentHorizontalPadding(Md3eWindowSizeClass sizeClass) {
    return Md3eComicDetailPageMetrics.contentHorizontalPadding(sizeClass);
  }

  static double sectionGap(Md3eWindowSizeClass sizeClass) {
    return sizeClass.isCompact ? Md3eSpacing.space16 : Md3eSpacing.space20;
  }
}
