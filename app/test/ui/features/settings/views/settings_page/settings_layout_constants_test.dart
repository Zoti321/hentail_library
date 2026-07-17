import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';

void main() {
  group('settingsLayoutTierForWidth', () {
    test('maps widths to compact, medium, and expanded tiers', () {
      expect(
        settingsLayoutTierForWidth(AppLayoutBreakpoints.compact - 1),
        SettingsLayoutTier.compact,
      );
      expect(
        settingsLayoutTierForWidth(AppLayoutBreakpoints.compact),
        SettingsLayoutTier.medium,
      );
      expect(
        settingsLayoutTierForWidth(AppLayoutBreakpoints.medium),
        SettingsLayoutTier.expanded,
      );
    });
  });

  group('settings responsive sizing helpers', () {
    test('uses tiered padding and title sizes aligned with other pages', () {
      expect(settingsContentHorizontalPadding(SettingsLayoutTier.compact), 16);
      expect(settingsContentHorizontalPadding(SettingsLayoutTier.medium), 28);
      expect(settingsContentHorizontalPadding(SettingsLayoutTier.expanded), 48);

      expect(settingsPageTitleFontSize(SettingsLayoutTier.compact), 18);
      expect(settingsPageTitleFontSize(SettingsLayoutTier.medium), 22);
      expect(settingsPageTitleFontSize(SettingsLayoutTier.expanded), 26);
    });

    test('keeps header chrome constants aligned with home/history', () {
      expect(kSettingsHeaderVerticalPadding, 6);
      expect(kSettingsHeaderShadowGradientHeight, 6);
    });

    test('toggles compact-only theme chevron action', () {
      expect(
        settingsThemeRowUsesChevronAction(SettingsLayoutTier.compact),
        isTrue,
      );
      expect(
        settingsThemeRowUsesChevronAction(SettingsLayoutTier.expanded),
        isFalse,
      );
    });
  });

  group('settingsInnerContentMaxWidth', () {
    test('caps expanded content width at 1280', () {
      expect(
        settingsInnerContentMaxWidth(SettingsLayoutTier.expanded, 1600),
        kPageContentMaxWidth,
      );
      expect(
        settingsInnerContentMaxWidth(SettingsLayoutTier.compact, 360),
        328,
      );
    });
  });

  group('settingsThemeMenuWidth', () {
    test('widens compact menus within viewport margins', () {
      expect(settingsThemeMenuWidth(SettingsLayoutTier.compact, 360), 200);
      expect(
        settingsThemeMenuWidth(SettingsLayoutTier.medium, 700),
        settingsThemeMenuWidthMedium,
      );
      expect(
        settingsThemeMenuWidth(SettingsLayoutTier.expanded, 1200),
        settingsThemeMenuWidthMedium,
      );
    });
  });
}
