import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/page_content_width_layout.dart';
import 'package:hentai_library/shared/ui/layout/content_search_width.dart';
import 'package:hentai_library/shared/ui/layout/page_header_layout.dart';

void main() {
  group('pageHeaderLayoutTierForWidth', () {
    test('maps widths to compact, medium, and expanded tiers', () {
      expect(
        pageHeaderLayoutTierForWidth(AppLayoutBreakpoints.compact - 1),
        PageHeaderLayoutTier.compact,
      );
      expect(
        pageHeaderLayoutTierForWidth(AppLayoutBreakpoints.compact),
        PageHeaderLayoutTier.medium,
      );
      expect(
        pageHeaderLayoutTierForWidth(AppLayoutBreakpoints.medium),
        PageHeaderLayoutTier.expanded,
      );
    });
  });

  group('history responsive sizing helpers', () {
    test('uses tiered padding and title sizes aligned with other pages', () {
      expect(pageHeaderHorizontalPadding(PageHeaderLayoutTier.compact), 16);
      expect(pageHeaderHorizontalPadding(PageHeaderLayoutTier.medium), 28);
      expect(pageHeaderHorizontalPadding(PageHeaderLayoutTier.expanded), 48);

      expect(pageHeaderTitleFontSize(PageHeaderLayoutTier.compact), 18);
      expect(pageHeaderTitleFontSize(PageHeaderLayoutTier.medium), 22);
      expect(pageHeaderTitleFontSize(PageHeaderLayoutTier.expanded), 26);
    });

    test('keeps header chrome constants aligned with home/metadata', () {
      expect(kPageHeaderVerticalPadding, 6);
      expect(kPageHeaderShadowGradientHeight, 6);
      expect(kPageHeaderSubtitleToSearchSpacing, 12);
      expect(kPageHeaderSearchToListSpacing, 16);
    });
  });

  group('pageHeaderInnerMaxWidth', () {
    test('caps expanded content width at 1280', () {
      expect(
        pageHeaderInnerMaxWidth(PageHeaderLayoutTier.expanded, 1600),
        kPageContentMaxWidth,
      );
      expect(pageHeaderInnerMaxWidth(PageHeaderLayoutTier.compact, 360), 328);
    });
  });

  group('pageHeaderGridMetrics', () {
    test('uses single column on compact widths', () {
      final PageHeaderGridMetrics metrics = pageHeaderGridMetrics(
        PageHeaderLayoutTier.compact,
        360,
      );
      expect(metrics.crossAxisCount, 1);
      expect(metrics.mainAxisExtent, 120);
    });

    test('uses two columns on medium widths', () {
      final PageHeaderGridMetrics metrics = pageHeaderGridMetrics(
        PageHeaderLayoutTier.medium,
        700,
      );
      expect(metrics.crossAxisCount, 2);
      expect(metrics.mainAxisExtent, 132);
    });

    test('uses four columns on wide expanded viewports', () {
      final PageHeaderGridMetrics metrics = pageHeaderGridMetrics(
        PageHeaderLayoutTier.expanded,
        1600,
      );
      expect(metrics.crossAxisCount, 4);
      expect(metrics.mainAxisExtent, 138);
    });

    test('uses three columns on narrower expanded viewports', () {
      final PageHeaderGridMetrics metrics = pageHeaderGridMetrics(
        PageHeaderLayoutTier.expanded,
        1100,
      );
      expect(metrics.crossAxisCount, 3);
      expect(metrics.mainAxisExtent, 138);
    });
  });

  group('contentSearchFieldWidth', () {
    test('matches shared search width formula', () {
      expect(contentSearchFieldWidth(ContentLayoutTier.compact, 320), 320);
      expect(contentSearchFieldWidth(ContentLayoutTier.medium, 800), 280);
      expect(contentSearchFieldWidth(ContentLayoutTier.expanded, 1200), 300);
    });
  });
}
