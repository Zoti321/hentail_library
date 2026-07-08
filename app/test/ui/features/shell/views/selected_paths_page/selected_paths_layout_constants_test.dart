import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/features/shell/views/selected_paths_page/selected_paths_layout_constants.dart';

void main() {
  group('selectedPathsLayoutTierForWidth', () {
    test('maps widths to compact, medium, and expanded tiers', () {
      expect(
        selectedPathsLayoutTierForWidth(AppLayoutBreakpoints.compact - 1),
        SelectedPathsLayoutTier.compact,
      );
      expect(
        selectedPathsLayoutTierForWidth(AppLayoutBreakpoints.compact),
        SelectedPathsLayoutTier.medium,
      );
      expect(
        selectedPathsLayoutTierForWidth(AppLayoutBreakpoints.medium),
        SelectedPathsLayoutTier.expanded,
      );
    });
  });

  group('selected paths responsive sizing helpers', () {
    test('uses tiered padding and title sizes aligned with other pages', () {
      expect(
        selectedPathsContentHorizontalPadding(SelectedPathsLayoutTier.compact),
        16,
      );
      expect(
        selectedPathsContentHorizontalPadding(SelectedPathsLayoutTier.medium),
        28,
      );
      expect(
        selectedPathsContentHorizontalPadding(SelectedPathsLayoutTier.expanded),
        48,
      );

      expect(
        selectedPathsPageTitleFontSize(SelectedPathsLayoutTier.compact),
        18,
      );
      expect(
        selectedPathsPageTitleFontSize(SelectedPathsLayoutTier.medium),
        22,
      );
      expect(
        selectedPathsPageTitleFontSize(SelectedPathsLayoutTier.expanded),
        26,
      );
    });
  });

  group('selectedPathsInnerContentMaxWidth', () {
    test('caps expanded content width at 1280', () {
      expect(
        selectedPathsInnerContentMaxWidth(
          SelectedPathsLayoutTier.expanded,
          1600,
        ),
        selectedPathsContentMaxWidth,
      );
      expect(
        selectedPathsInnerContentMaxWidth(SelectedPathsLayoutTier.compact, 360),
        328,
      );
    });
  });
}
