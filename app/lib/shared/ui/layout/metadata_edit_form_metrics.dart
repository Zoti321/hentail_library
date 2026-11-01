import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/spacing.dart';

/// 漫画 / 系列元数据编辑表单布局 token（Lab）。
/// 页面水平留白统一来自 Md3ePageLayoutSpec，本类不再重复定义。
abstract final class Md3eMetadataEditFormMetrics {
  static const double comicMaxWidth = 720;
  static const double seriesMaxWidth = 480;

  static double sectionGap(Md3eWindowSizeClass sizeClass) {
    return sizeClass.isCompact ? Md3eSpacing.space16 : Md3eSpacing.space20;
  }
}
