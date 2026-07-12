import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';
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

double homePageTitleFontSize(HomePageLayoutTier tier) {
  return switch (tier) {
    HomePageLayoutTier.compact => 18,
    HomePageLayoutTier.medium => 22,
    HomePageLayoutTier.expanded => 26,
  };
}

double homeInnerContentMaxWidth(
  HomePageLayoutTier tier,
  double viewportWidth,
) {
  return pageInnerContentMaxWidth(
    viewportWidth: viewportWidth,
    horizontalPadding: homeContentHorizontalPadding(tier),
    capAtMaxWidth: tier == HomePageLayoutTier.expanded,
  );
}

double continueReadingItemWidthFor(HomePageLayoutTier tier) {
  return switch (tier) {
    HomePageLayoutTier.compact => continueReadingItemWidthCompact,
    HomePageLayoutTier.medium => continueReadingItemWidth,
    HomePageLayoutTier.expanded => continueReadingItemWidth,
  };
}
