import 'dart:math' as math;

import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';

const double historyContentMaxWidth = 1280;
const double kHistoryHeaderVerticalPadding = 6;
const double kHistoryHeaderShadowGradientHeight = 6;
const double kHistorySubtitleToSearchSpacing = 12;
const double kHistorySearchToListSpacing = 16;

enum HistoryLayoutTier { compact, medium, expanded }

typedef HistoryGridMetrics = ({int crossAxisCount, double mainAxisExtent});

HistoryLayoutTier historyLayoutTierForWidth(double width) {
  if (AppLayoutBreakpoints.isCompact(width)) {
    return HistoryLayoutTier.compact;
  }
  if (AppLayoutBreakpoints.isMedium(width)) {
    return HistoryLayoutTier.medium;
  }
  return HistoryLayoutTier.expanded;
}

double historyContentHorizontalPadding(HistoryLayoutTier tier) {
  return switch (tier) {
    HistoryLayoutTier.compact => 16,
    HistoryLayoutTier.medium => 28,
    HistoryLayoutTier.expanded => 48,
  };
}

double historyPageTitleFontSize(HistoryLayoutTier tier) {
  return switch (tier) {
    HistoryLayoutTier.compact => 18,
    HistoryLayoutTier.medium => 22,
    HistoryLayoutTier.expanded => 26,
  };
}

double historyInnerContentMaxWidth(
  HistoryLayoutTier tier,
  double viewportWidth,
) {
  final double horizontalPadding = historyContentHorizontalPadding(tier);
  final double paddedWidth = viewportWidth - horizontalPadding * 2;
  return switch (tier) {
    HistoryLayoutTier.expanded => math.min(paddedWidth, historyContentMaxWidth),
    HistoryLayoutTier.compact || HistoryLayoutTier.medium => paddedWidth,
  };
}

HistoryGridMetrics historyGridMetrics(
  HistoryLayoutTier tier,
  double viewportWidth,
) {
  final double paddedWidth =
      viewportWidth - historyContentHorizontalPadding(tier) * 2;
  return switch (tier) {
    HistoryLayoutTier.compact => (crossAxisCount: 1, mainAxisExtent: 120.0),
    HistoryLayoutTier.medium => (crossAxisCount: 2, mainAxisExtent: 132.0),
    HistoryLayoutTier.expanded =>
      paddedWidth >= historyContentMaxWidth
          ? (crossAxisCount: 4, mainAxisExtent: 138.0)
          : (crossAxisCount: 3, mainAxisExtent: 138.0),
  };
}
