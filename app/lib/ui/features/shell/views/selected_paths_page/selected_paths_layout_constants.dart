import 'dart:math' as math;

import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';

const double selectedPathsContentMaxWidth = 1280;

enum SelectedPathsLayoutTier { compact, medium, expanded }

SelectedPathsLayoutTier selectedPathsLayoutTierForWidth(double width) {
  if (AppLayoutBreakpoints.isCompact(width)) {
    return SelectedPathsLayoutTier.compact;
  }
  if (AppLayoutBreakpoints.isMedium(width)) {
    return SelectedPathsLayoutTier.medium;
  }
  return SelectedPathsLayoutTier.expanded;
}

double selectedPathsContentHorizontalPadding(SelectedPathsLayoutTier tier) {
  return switch (tier) {
    SelectedPathsLayoutTier.compact => 16,
    SelectedPathsLayoutTier.medium => 28,
    SelectedPathsLayoutTier.expanded => 48,
  };
}

double selectedPathsPageTitleFontSize(SelectedPathsLayoutTier tier) {
  return switch (tier) {
    SelectedPathsLayoutTier.compact => 18,
    SelectedPathsLayoutTier.medium => 22,
    SelectedPathsLayoutTier.expanded => 26,
  };
}

bool selectedPathsHeaderIsVertical(SelectedPathsLayoutTier tier) {
  return tier == SelectedPathsLayoutTier.compact;
}

bool selectedPathsShowsSubtitle(SelectedPathsLayoutTier tier) {
  return tier != SelectedPathsLayoutTier.compact;
}

bool selectedPathsHeaderUsesIconOnlyClear(SelectedPathsLayoutTier tier) {
  return tier == SelectedPathsLayoutTier.compact;
}

double selectedPathsInnerContentMaxWidth(
  SelectedPathsLayoutTier tier,
  double viewportWidth,
) {
  final double horizontalPadding = selectedPathsContentHorizontalPadding(tier);
  final double paddedWidth = viewportWidth - horizontalPadding * 2;
  return switch (tier) {
    SelectedPathsLayoutTier.expanded =>
      math.min(paddedWidth, selectedPathsContentMaxWidth),
    SelectedPathsLayoutTier.compact || SelectedPathsLayoutTier.medium =>
      paddedWidth,
  };
}
