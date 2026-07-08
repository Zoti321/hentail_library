import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';

void main() {
  group('libraryLayoutTierForWidth', () {
    test('maps widths to compact, medium, and expanded tiers', () {
      expect(
        libraryLayoutTierForWidth(AppLayoutBreakpoints.compact - 1),
        LibraryLayoutTier.compact,
      );
      expect(
        libraryLayoutTierForWidth(AppLayoutBreakpoints.compact),
        LibraryLayoutTier.medium,
      );
      expect(
        libraryLayoutTierForWidth(AppLayoutBreakpoints.medium - 1),
        LibraryLayoutTier.medium,
      );
      expect(
        libraryLayoutTierForWidth(AppLayoutBreakpoints.medium),
        LibraryLayoutTier.expanded,
      );
    });
  });

  group('library responsive sizing helpers', () {
    test(
      'uses tiered padding, title sizes, toolbar spacing, and grid metrics',
      () {
        expect(libraryContentHorizontalPadding(LibraryLayoutTier.compact), 16);
        expect(libraryContentHorizontalPadding(LibraryLayoutTier.medium), 28);
        expect(libraryContentHorizontalPadding(LibraryLayoutTier.expanded), 48);

        expect(libraryPageTitleFontSize(LibraryLayoutTier.compact), 18);
        expect(libraryPageTitleFontSize(LibraryLayoutTier.medium), 22);
        expect(libraryPageTitleFontSize(LibraryLayoutTier.expanded), 26);

        expect(libraryToolbarActionSpacing(LibraryLayoutTier.compact), 4);
        expect(libraryToolbarActionSpacing(LibraryLayoutTier.medium), 6);
        expect(libraryToolbarActionSpacing(LibraryLayoutTier.expanded), 8);

        expect(libraryGridMaxCrossAxisExtent(LibraryLayoutTier.compact), 168);
        expect(libraryGridMaxCrossAxisExtent(LibraryLayoutTier.medium), 188);
        expect(libraryGridMaxCrossAxisExtent(LibraryLayoutTier.expanded), 200);

        expect(libraryGridSpacing(LibraryLayoutTier.compact), 12);
        expect(libraryGridSpacing(LibraryLayoutTier.medium), 14);
        expect(libraryGridSpacing(LibraryLayoutTier.expanded), 16);

        expect(
          libraryHeaderShowsCountChips(LibraryLayoutTier.compact),
          isFalse,
        );
        expect(libraryHeaderShowsCountChips(LibraryLayoutTier.medium), isTrue);
      },
    );
  });

  group('libraryTabBadgeMetrics', () {
    test('uses smaller compact badge offset and size', () {
      final LibraryTabBadgeMetrics compact = libraryTabBadgeMetrics(
        LibraryLayoutTier.compact,
      );
      final LibraryTabBadgeMetrics expanded = libraryTabBadgeMetrics(
        LibraryLayoutTier.expanded,
      );

      expect(compact.top, lessThan(expanded.top));
      expect(compact.right, lessThan(expanded.right));
      expect(compact.minSize, lessThan(expanded.minSize));
      expect(compact.fontSize, lessThan(expanded.fontSize));
    });
  });

  group('library popup menu widths', () {
    test('widens compact menus within viewport margins', () {
      expect(libraryPageSizeMenuWidth(LibraryLayoutTier.compact, 360), 160);
      expect(libraryOverflowMenuWidth(LibraryLayoutTier.compact, 360), 240);
      expect(libraryPageSizeMenuWidth(LibraryLayoutTier.expanded, 1200), 120);
      expect(libraryOverflowMenuWidth(LibraryLayoutTier.expanded, 1200), 200);
    });
  });

  group('libraryFilterSortDrawerWidth', () {
    test('uses at least half viewport on compact widths', () {
      const double viewportWidth = 360;

      expect(
        libraryFilterSortDrawerWidth(LibraryLayoutTier.compact, viewportWidth),
        greaterThanOrEqualTo(viewportWidth * 0.5),
      );
      expect(libraryFilterSortDrawerWidthForViewport(viewportWidth), 200);
    });

    test('keeps medium and expanded drawer widths proportional', () {
      expect(libraryFilterSortDrawerWidth(LibraryLayoutTier.medium, 800), 280);
      expect(
        libraryFilterSortDrawerWidth(LibraryLayoutTier.expanded, 1200),
        360,
      );
    });
  });
}
