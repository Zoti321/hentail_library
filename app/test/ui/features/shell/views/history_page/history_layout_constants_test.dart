import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';
import 'package:hentai_library/ui/core/layout/content_search_width.dart';
import 'package:hentai_library/ui/features/shell/views/history_page/history_layout_constants.dart';

void main() {
  group('historyLayoutTierForWidth', () {
    test('maps widths to compact, medium, and expanded tiers', () {
      expect(
        historyLayoutTierForWidth(AppLayoutBreakpoints.compact - 1),
        HistoryLayoutTier.compact,
      );
      expect(
        historyLayoutTierForWidth(AppLayoutBreakpoints.compact),
        HistoryLayoutTier.medium,
      );
      expect(
        historyLayoutTierForWidth(AppLayoutBreakpoints.medium),
        HistoryLayoutTier.expanded,
      );
    });
  });

  group('history responsive sizing helpers', () {
    test('uses tiered padding and title sizes aligned with other pages', () {
      expect(historyContentHorizontalPadding(HistoryLayoutTier.compact), 16);
      expect(historyContentHorizontalPadding(HistoryLayoutTier.medium), 28);
      expect(historyContentHorizontalPadding(HistoryLayoutTier.expanded), 48);

      expect(historyPageTitleFontSize(HistoryLayoutTier.compact), 18);
      expect(historyPageTitleFontSize(HistoryLayoutTier.medium), 22);
      expect(historyPageTitleFontSize(HistoryLayoutTier.expanded), 26);
    });

    test('keeps header chrome constants aligned with home/metadata', () {
      expect(kHistoryHeaderVerticalPadding, 6);
      expect(kHistoryHeaderShadowGradientHeight, 6);
      expect(kHistorySubtitleToSearchSpacing, 12);
      expect(kHistorySearchToListSpacing, 16);
    });
  });

  group('historyInnerContentMaxWidth', () {
    test('caps expanded content width at 1280', () {
      expect(
        historyInnerContentMaxWidth(HistoryLayoutTier.expanded, 1600),
        kPageContentMaxWidth,
      );
      expect(historyInnerContentMaxWidth(HistoryLayoutTier.compact, 360), 328);
    });
  });

  group('historyGridMetrics', () {
    test('uses single column on compact widths', () {
      final HistoryGridMetrics metrics = historyGridMetrics(
        HistoryLayoutTier.compact,
        360,
      );
      expect(metrics.crossAxisCount, 1);
      expect(metrics.mainAxisExtent, 120);
    });

    test('uses two columns on medium widths', () {
      final HistoryGridMetrics metrics = historyGridMetrics(
        HistoryLayoutTier.medium,
        700,
      );
      expect(metrics.crossAxisCount, 2);
      expect(metrics.mainAxisExtent, 132);
    });

    test('uses four columns on wide expanded viewports', () {
      final HistoryGridMetrics metrics = historyGridMetrics(
        HistoryLayoutTier.expanded,
        1600,
      );
      expect(metrics.crossAxisCount, 4);
      expect(metrics.mainAxisExtent, 138);
    });

    test('uses three columns on narrower expanded viewports', () {
      final HistoryGridMetrics metrics = historyGridMetrics(
        HistoryLayoutTier.expanded,
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
