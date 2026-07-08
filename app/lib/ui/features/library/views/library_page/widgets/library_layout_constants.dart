import 'dart:math' as math;

import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';

enum LibraryLayoutTier { compact, medium, expanded }

typedef LibraryTabBadgeMetrics = ({
  double top,
  double right,
  double minSize,
  double fontSize,
  double horizontalPadding,
  double borderRadius,
});

LibraryLayoutTier libraryLayoutTierForWidth(double width) {
  if (AppLayoutBreakpoints.isCompact(width)) {
    return LibraryLayoutTier.compact;
  }
  if (AppLayoutBreakpoints.isMedium(width)) {
    return LibraryLayoutTier.medium;
  }
  return LibraryLayoutTier.expanded;
}

double libraryContentHorizontalPadding(LibraryLayoutTier tier) {
  return switch (tier) {
    LibraryLayoutTier.compact => 16,
    LibraryLayoutTier.medium => 28,
    LibraryLayoutTier.expanded => 48,
  };
}

double libraryPageTitleFontSize(LibraryLayoutTier tier) {
  return switch (tier) {
    LibraryLayoutTier.compact => 18,
    LibraryLayoutTier.medium => 22,
    LibraryLayoutTier.expanded => 26,
  };
}

double libraryToolbarActionSpacing(LibraryLayoutTier tier) {
  return switch (tier) {
    LibraryLayoutTier.compact => 4,
    LibraryLayoutTier.medium => 6,
    LibraryLayoutTier.expanded => 8,
  };
}

bool libraryHeaderShowsCountChips(LibraryLayoutTier tier) {
  return tier != LibraryLayoutTier.compact;
}

double libraryGridMaxCrossAxisExtent(LibraryLayoutTier tier) {
  return switch (tier) {
    LibraryLayoutTier.compact => 168,
    LibraryLayoutTier.medium => 188,
    LibraryLayoutTier.expanded => 200,
  };
}

double libraryGridSpacing(LibraryLayoutTier tier) {
  return switch (tier) {
    LibraryLayoutTier.compact => 12,
    LibraryLayoutTier.medium => 14,
    LibraryLayoutTier.expanded => 16,
  };
}

LibraryTabBadgeMetrics libraryTabBadgeMetrics(LibraryLayoutTier tier) {
  return switch (tier) {
    LibraryLayoutTier.compact => (
      top: -8,
      right: -14,
      minSize: 14,
      fontSize: 9,
      horizontalPadding: 3,
      borderRadius: 7,
    ),
    LibraryLayoutTier.medium || LibraryLayoutTier.expanded => (
      top: -2,
      right: -10,
      minSize: 16,
      fontSize: 10,
      horizontalPadding: 4,
      borderRadius: 8,
    ),
  };
}

double libraryPageSizeMenuWidth(LibraryLayoutTier tier, double viewportWidth) {
  return switch (tier) {
    LibraryLayoutTier.compact => math.min(viewportWidth - 32, 160),
    LibraryLayoutTier.medium || LibraryLayoutTier.expanded => 120,
  };
}

double libraryOverflowMenuWidth(LibraryLayoutTier tier, double viewportWidth) {
  return switch (tier) {
    LibraryLayoutTier.compact => math.min(viewportWidth - 32, 240),
    LibraryLayoutTier.medium || LibraryLayoutTier.expanded => 200,
  };
}

double libraryFilterSortDrawerWidth(LibraryLayoutTier tier, double viewportWidth) {
  return switch (tier) {
    LibraryLayoutTier.compact => math.min(
      math.max(viewportWidth * 0.55, 200),
      math.min(viewportWidth - 16, 400),
    ),
    LibraryLayoutTier.medium => math.min(360, viewportWidth * 0.35),
    LibraryLayoutTier.expanded => math.min(360, viewportWidth * 0.30),
  };
}

double libraryFilterSortDrawerWidthForViewport(double viewportWidth) {
  return libraryFilterSortDrawerWidth(
    libraryLayoutTierForWidth(viewportWidth),
    viewportWidth,
  );
}
