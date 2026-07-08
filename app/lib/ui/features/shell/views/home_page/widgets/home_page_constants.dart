import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';

const double homeContentMaxWidth = 1280;
const double continueReadingItemWidth = 304;
const double continueReadingItemWidthCompact = 272;
const double continueReadingStripHeight = 138;
const double heroStatCardRadius = 16;
const Duration heroStatCardHoverDuration = Duration(milliseconds: 200);

enum HomePageLayoutTier { compact, medium, expanded }

HomePageLayoutTier homePageLayoutTierForWidth(double width) {
  if (AppLayoutBreakpoints.isCompact(width)) {
    return HomePageLayoutTier.compact;
  }
  if (AppLayoutBreakpoints.isMedium(width)) {
    return HomePageLayoutTier.medium;
  }
  return HomePageLayoutTier.expanded;
}

double homeContentHorizontalPadding(HomePageLayoutTier tier) {
  return switch (tier) {
    HomePageLayoutTier.compact => 16,
    HomePageLayoutTier.medium => 28,
    HomePageLayoutTier.expanded => 48,
  };
}

double continueReadingItemWidthFor(HomePageLayoutTier tier) {
  return switch (tier) {
    HomePageLayoutTier.compact => continueReadingItemWidthCompact,
    HomePageLayoutTier.medium => continueReadingItemWidth,
    HomePageLayoutTier.expanded => continueReadingItemWidth,
  };
}
