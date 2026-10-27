import 'package:flutter/painting.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_comic_detail_page_metrics.dart';
import 'package:hentai_library/md3e/layout/md3e_pinned_toolbar_chrome_metrics.dart';
import 'package:hentai_library/md3e/layout/md3e_spacing.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Layout tokens for [Md3eSeriesDetailPage].
abstract final class Md3eSeriesDetailPageMetrics {
  static const double toolbarHeight = Md3eComicDetailPageMetrics.toolbarHeight;
  static const double primaryRowNarrowBreakpoint =
      Md3eComicDetailPageMetrics.primaryRowNarrowBreakpoint;

  static double contentHorizontalPadding(Md3eWindowSizeClass sizeClass) =>
      Md3eComicDetailPageMetrics.contentHorizontalPadding(sizeClass);

  static double headerTopPadding(Md3eWindowSizeClass sizeClass) =>
      Md3eComicDetailPageMetrics.headerTopPadding(sizeClass);

  static double headerBottomPadding(Md3eWindowSizeClass sizeClass) =>
      Md3eComicDetailPageMetrics.headerBottomPadding(sizeClass);

  static double introTopSpacing(Md3eWindowSizeClass sizeClass) =>
      Md3ePinnedToolbarChromeMetrics.bodyBelowHeaderSpacing(sizeClass);

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

  static TextStyle titleTextStyle({
    required Md3eWindowSizeClass sizeClass,
    required M3ETypeScale typeScale,
    required Color color,
  }) =>
      Md3eComicDetailPageMetrics.titleTextStyle(
        sizeClass: sizeClass,
        typeScale: typeScale,
        color: color,
      );

  static const double scrollBottomInset = Md3eSpacing.space24;
}
