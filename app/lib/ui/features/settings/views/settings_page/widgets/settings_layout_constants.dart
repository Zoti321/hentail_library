import 'dart:math' as math;

import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';

const double settingsThemeMenuWidthMedium = 224;
const double kSettingsHeaderVerticalPadding = 6;
const double kSettingsHeaderShadowGradientHeight = 6;

enum SettingsLayoutTier { compact, medium, expanded }

SettingsLayoutTier settingsLayoutTierForWidth(double width) {
  if (AppLayoutBreakpoints.isCompact(width)) {
    return SettingsLayoutTier.compact;
  }
  if (AppLayoutBreakpoints.isMedium(width)) {
    return SettingsLayoutTier.medium;
  }
  return SettingsLayoutTier.expanded;
}

double settingsContentHorizontalPadding(SettingsLayoutTier tier) {
  return switch (tier) {
    SettingsLayoutTier.compact => 16,
    SettingsLayoutTier.medium => 28,
    SettingsLayoutTier.expanded => 48,
  };
}

double settingsPageTitleFontSize(SettingsLayoutTier tier) {
  return switch (tier) {
    SettingsLayoutTier.compact => 18,
    SettingsLayoutTier.medium => 22,
    SettingsLayoutTier.expanded => 26,
  };
}

bool settingsThemeRowUsesChevronAction(SettingsLayoutTier tier) {
  return tier == SettingsLayoutTier.compact;
}

double settingsInnerContentMaxWidth(
  SettingsLayoutTier tier,
  double viewportWidth,
) {
  return pageInnerContentMaxWidth(
    viewportWidth: viewportWidth,
    horizontalPadding: settingsContentHorizontalPadding(tier),
    capAtMaxWidth: tier == SettingsLayoutTier.expanded,
  );
}

double settingsThemeMenuWidth(SettingsLayoutTier tier, double viewportWidth) {
  return switch (tier) {
    SettingsLayoutTier.compact => math.min(viewportWidth - 32, 200),
    SettingsLayoutTier.medium ||
    SettingsLayoutTier.expanded => settingsThemeMenuWidthMedium,
  };
}
