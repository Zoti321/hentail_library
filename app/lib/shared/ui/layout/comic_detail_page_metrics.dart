import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/pinned_toolbar_chrome_metrics.dart';
import 'package:hentai_library/shared/ui/layout/spacing.dart';

/// Layout tokens for [Md3eComicDetailPage] (Lab; spacing tuned for sticky header + scroll body).
abstract final class Md3eComicDetailPageMetrics {
  static const double toolbarHeight =
      Md3ePinnedToolbarChromeMetrics.toolbarRowHeight;
  static const double coverAspectRatio = 2 / 3;
  static const double coverCornerRadius = 2;

  /// 封面与主信息列横排断点（内容区宽度小于 840 时改为纵排）。
  static const double primaryRowNarrowBreakpoint = Md3eBreakpoints.expanded;

  static const double seriesMenuWidth = 320;
  static const double seriesMenuMaxHeight = 360;

  static double primaryToMetadataSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => Md3eSpacing.space28,
      Md3eWindowSizeClass.medium => Md3eSpacing.space32,
      _ => Md3eSpacing.space40,
    };
  }

  static double metadataTagsToResourceSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => Md3eSpacing.space24,
      Md3eWindowSizeClass.medium => Md3eSpacing.space28,
      _ => Md3eSpacing.space32,
    };
  }

  static double coverWidth(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => 168,
      Md3eWindowSizeClass.medium => 192,
      Md3eWindowSizeClass.expanded => 220,
      Md3eWindowSizeClass.large => 236,
      Md3eWindowSizeClass.extraLarge => 252,
    };
  }

  static double primaryRowGap(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => Md3eSpacing.space16,
      Md3eWindowSizeClass.medium => Md3eSpacing.space20,
      _ => Md3eSpacing.space24,
    };
  }

  static double primaryColumnSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => Md3eSpacing.space12,
      _ => Md3eSpacing.space16,
    };
  }

  static const double scrollBottomInset = Md3eSpacing.space24;
}
