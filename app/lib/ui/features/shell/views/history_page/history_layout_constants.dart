import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';

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
  return pageInnerContentMaxWidth(
    viewportWidth: viewportWidth,
    horizontalPadding: historyContentHorizontalPadding(tier),
    capAtMaxWidth: tier == HistoryLayoutTier.expanded,
  );
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
      paddedWidth >= kPageContentMaxWidth
          ? (crossAxisCount: 4, mainAxisExtent: 138.0)
          : (crossAxisCount: 3, mainAxisExtent: 138.0),
  };
}
