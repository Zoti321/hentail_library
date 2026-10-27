import 'package:flutter/painting.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_pinned_toolbar_chrome_metrics.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

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

  static double contentHorizontalPadding(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => 16,
      Md3eWindowSizeClass.medium => 24,
      Md3eWindowSizeClass.expanded => 32,
      Md3eWindowSizeClass.large => 40,
      Md3eWindowSizeClass.extraLarge =>
        Md3eLibraryPageHeaderMetrics.contentHorizontalPadding(sizeClass),
    };
  }

  static double headerTopPadding(Md3eWindowSizeClass sizeClass) =>
      Md3ePinnedToolbarChromeMetrics.topPadding(sizeClass);

  static double headerBottomPadding(Md3eWindowSizeClass sizeClass) =>
      Md3ePinnedToolbarChromeMetrics.bottomPadding(sizeClass);

  static double catalogBodyTopSpacing(Md3eWindowSizeClass sizeClass) =>
      Md3ePinnedToolbarChromeMetrics.bodyBelowHeaderSpacing(sizeClass);

  static double primaryToMetadataSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => 28,
      Md3eWindowSizeClass.medium => 32,
      _ => 40,
    };
  }

  static double metadataTagsToResourceSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => 24,
      Md3eWindowSizeClass.medium => 28,
      _ => 32,
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
      Md3eWindowSizeClass.compact => 16,
      Md3eWindowSizeClass.medium => 20,
      _ => 24,
    };
  }

  static double primaryColumnSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => 12,
      _ => 16,
    };
  }

  static TextStyle titleTextStyle({
    required Md3eWindowSizeClass sizeClass,
    required M3ETypeScale typeScale,
    required Color color,
  }) {
    final TextStyle base = switch (sizeClass) {
      Md3eWindowSizeClass.compact => typeScale.titleLarge,
      Md3eWindowSizeClass.medium => typeScale.headlineSmall,
      Md3eWindowSizeClass.expanded => typeScale.headlineSmall,
      _ => typeScale.headlineMedium,
    };
    return base.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      color: color,
      height: 1.25,
    );
  }

  static const double scrollBottomInset = 24;
}
