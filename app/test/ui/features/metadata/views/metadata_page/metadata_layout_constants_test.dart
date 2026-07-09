import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_layout_constants.dart';

void main() {
  group('metadataLayoutTierForWidth', () {
    test('maps widths to compact, medium, and expanded tiers', () {
      expect(
        metadataLayoutTierForWidth(AppLayoutBreakpoints.compact - 1),
        MetadataLayoutTier.compact,
      );
      expect(
        metadataLayoutTierForWidth(AppLayoutBreakpoints.compact),
        MetadataLayoutTier.medium,
      );
      expect(
        metadataLayoutTierForWidth(AppLayoutBreakpoints.medium),
        MetadataLayoutTier.expanded,
      );
    });
  });

  group('metadata responsive sizing helpers', () {
    test('uses tiered padding and title sizes aligned with home/library', () {
      expect(metadataContentHorizontalPadding(MetadataLayoutTier.compact), 16);
      expect(metadataContentHorizontalPadding(MetadataLayoutTier.medium), 28);
      expect(metadataContentHorizontalPadding(MetadataLayoutTier.expanded), 48);

      expect(metadataPageTitleFontSize(MetadataLayoutTier.compact), 18);
      expect(metadataPageTitleFontSize(MetadataLayoutTier.medium), 22);
      expect(metadataPageTitleFontSize(MetadataLayoutTier.expanded), 26);
    });

    test('toggles compact-only layout behaviors', () {
      expect(metadataRowUsesOverflowMenu(MetadataLayoutTier.compact), isTrue);
      expect(metadataRowUsesOverflowMenu(MetadataLayoutTier.expanded), isFalse);
    });
  });

  group('metadataSearchFieldWidth', () {
    test('uses full width on compact and capped ratios on wider tiers', () {
      expect(metadataSearchFieldWidth(MetadataLayoutTier.compact, 320), 320);
      expect(metadataSearchFieldWidth(MetadataLayoutTier.medium, 800), 280);
      expect(metadataSearchFieldWidth(MetadataLayoutTier.expanded, 1200), 300);
    });
  });

  group('metadataInnerContentMaxWidth', () {
    test('caps expanded content width at 1280', () {
      expect(
        metadataInnerContentMaxWidth(MetadataLayoutTier.expanded, 1600),
        metadataContentMaxWidth,
      );
      expect(
        metadataInnerContentMaxWidth(MetadataLayoutTier.compact, 360),
        328,
      );
    });
  });

  group('metadataAddEntityTooltip', () {
    test('returns entity-specific add labels', () {
      expect(metadataAddEntityTooltip(0), '添加作者');
      expect(metadataAddEntityTooltip(1), '添加标签');
    });
  });
}
