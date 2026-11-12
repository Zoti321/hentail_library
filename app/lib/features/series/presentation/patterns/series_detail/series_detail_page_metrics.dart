import 'package:hentai_library/design-system/design_system.dart';

/// Layout tokens for [SeriesDetailLayout].
abstract final class SeriesDetailPageMetrics {
  static const double toolbarHeight = ComicDetailPageMetrics.toolbarHeight;
  static const double primaryRowNarrowBreakpoint =
      ComicDetailPageMetrics.primaryRowNarrowBreakpoint;

  static double primaryToMetadataSpacing(WindowSizeClass sizeClass) =>
      ComicDetailPageMetrics.primaryToMetadataSpacing(sizeClass);

  static double metadataToComicsSpacing(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => Spacing.space20,
      _ => Spacing.space24,
    };
  }

  static double comicsSectionTopSpacing(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => Spacing.space12,
      _ => Spacing.space16,
    };
  }

  static double paginationVerticalSpacing(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => Spacing.space12,
      _ => Spacing.space16,
    };
  }

  static double coverWidth(WindowSizeClass sizeClass) =>
      ComicDetailPageMetrics.coverWidth(sizeClass);

  static double primaryRowGap(WindowSizeClass sizeClass) =>
      ComicDetailPageMetrics.primaryRowGap(sizeClass);

  static double primaryColumnSpacing(WindowSizeClass sizeClass) =>
      ComicDetailPageMetrics.primaryColumnSpacing(sizeClass);

  static const double scrollBottomInset = Spacing.space24;
}
