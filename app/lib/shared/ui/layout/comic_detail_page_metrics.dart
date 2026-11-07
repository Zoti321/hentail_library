import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/pinned_toolbar_chrome_metrics.dart';
import 'package:hentai_library/shared/ui/layout/spacing.dart';

/// Layout tokens for [ComicDetailLayout] (Lab; spacing tuned for sticky header + scroll body).
abstract final class ComicDetailPageMetrics {
  static const double toolbarHeight =
      PinnedToolbarChromeMetrics.toolbarRowHeight;
  static const double coverAspectRatio = 2 / 3;
  static const double coverCornerRadius = 2;

  /// 封面与主信息列横排断点（内容区宽度小于 840 时改为纵排）。
  static const double primaryRowNarrowBreakpoint = Breakpoints.expanded;

  static const double seriesMenuWidth = 320;
  static const double seriesMenuMaxHeight = 360;

  static double primaryToMetadataSpacing(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => Spacing.space28,
      WindowSizeClass.medium => Spacing.space32,
      _ => Spacing.space40,
    };
  }

  static double metadataTagsToResourceSpacing(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => Spacing.space24,
      WindowSizeClass.medium => Spacing.space28,
      _ => Spacing.space32,
    };
  }

  static double coverWidth(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => 168,
      WindowSizeClass.medium => 192,
      WindowSizeClass.expanded => 220,
      WindowSizeClass.large => 236,
      WindowSizeClass.extraLarge => 252,
    };
  }

  static double primaryRowGap(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => Spacing.space16,
      WindowSizeClass.medium => Spacing.space20,
      _ => Spacing.space24,
    };
  }

  static double primaryColumnSpacing(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => Spacing.space12,
      _ => Spacing.space16,
    };
  }

  static const double scrollBottomInset = Spacing.space24;
}
