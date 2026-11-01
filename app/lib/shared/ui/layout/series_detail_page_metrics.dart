import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_page_metrics.dart';
import 'package:hentai_library/shared/ui/layout/spacing.dart';

/// Layout tokens for [Md3eSeriesDetailPage].
abstract final class Md3eSeriesDetailPageMetrics {
  static const double toolbarHeight = Md3eComicDetailPageMetrics.toolbarHeight;
  static const double primaryRowNarrowBreakpoint =
      Md3eComicDetailPageMetrics.primaryRowNarrowBreakpoint;

  static double primaryToMetadataSpacing(Md3eWindowSizeClass sizeClass) =>
      Md3eComicDetailPageMetrics.primaryToMetadataSpacing(sizeClass);

  static double metadataToComicsSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => Md3eSpacing.space20,
      _ => Md3eSpacing.space24,
    };
  }

  static double comicsSectionTopSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => Md3eSpacing.space12,
      _ => Md3eSpacing.space16,
    };
  }

  static double paginationVerticalSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => Md3eSpacing.space12,
      _ => Md3eSpacing.space16,
    };
  }

  static double coverWidth(Md3eWindowSizeClass sizeClass) =>
      Md3eComicDetailPageMetrics.coverWidth(sizeClass);

  static double primaryRowGap(Md3eWindowSizeClass sizeClass) =>
      Md3eComicDetailPageMetrics.primaryRowGap(sizeClass);

  static double primaryColumnSpacing(Md3eWindowSizeClass sizeClass) =>
      Md3eComicDetailPageMetrics.primaryColumnSpacing(sizeClass);

  static const double scrollBottomInset = Md3eSpacing.space24;
}
