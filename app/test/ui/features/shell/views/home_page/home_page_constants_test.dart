import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/features/shell/views/home_page/widgets/home_page_constants.dart';

void main() {
  group('homePageLayoutTierForWidth', () {
    test('maps widths to compact, medium, and expanded tiers', () {
      expect(
        homePageLayoutTierForWidth(AppLayoutBreakpoints.compact - 1),
        HomePageLayoutTier.compact,
      );
      expect(
        homePageLayoutTierForWidth(AppLayoutBreakpoints.compact),
        HomePageLayoutTier.medium,
      );
      expect(
        homePageLayoutTierForWidth(AppLayoutBreakpoints.medium - 1),
        HomePageLayoutTier.medium,
      );
      expect(
        homePageLayoutTierForWidth(AppLayoutBreakpoints.medium),
        HomePageLayoutTier.expanded,
      );
    });
  });

  group('home responsive sizing helpers', () {
    test('uses tighter padding and continue-reading tiles in compact tier', () {
      expect(homeContentHorizontalPadding(HomePageLayoutTier.compact), 16);
      expect(homeContentHorizontalPadding(HomePageLayoutTier.medium), 28);
      expect(homeContentHorizontalPadding(HomePageLayoutTier.expanded), 48);
      expect(
        continueReadingItemWidthFor(HomePageLayoutTier.compact),
        continueReadingItemWidthCompact,
      );
    });
  });
}
