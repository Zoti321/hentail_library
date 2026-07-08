import 'dart:math' as math;

import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';

const double settingsContentMaxWidth = 1280;
const double settingsThemeMenuWidthMedium = 224;

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

bool settingsShowsRowDescription(SettingsLayoutTier tier) {
  return tier != SettingsLayoutTier.compact;
}

bool settingsThemeRowUsesChevronAction(SettingsLayoutTier tier) {
  return tier == SettingsLayoutTier.compact;
}

double settingsInnerContentMaxWidth(
  SettingsLayoutTier tier,
  double viewportWidth,
) {
  final double horizontalPadding = settingsContentHorizontalPadding(tier);
  final double paddedWidth = viewportWidth - horizontalPadding * 2;
  return switch (tier) {
    SettingsLayoutTier.expanded => math.min(paddedWidth, settingsContentMaxWidth),
    SettingsLayoutTier.compact || SettingsLayoutTier.medium => paddedWidth,
  };
}

double settingsThemeMenuWidth(
  SettingsLayoutTier tier,
  double viewportWidth,
) {
  return switch (tier) {
    SettingsLayoutTier.compact => math.min(viewportWidth - 32, 200),
    SettingsLayoutTier.medium || SettingsLayoutTier.expanded =>
      settingsThemeMenuWidthMedium,
  };
}
