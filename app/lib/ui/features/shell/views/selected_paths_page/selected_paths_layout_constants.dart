import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';

const double kSelectedPathsHeaderVerticalPadding = 6;
const double kSelectedPathsHeaderShadowGradientHeight = 6;

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

double selectedPathsInnerContentMaxWidth(
  SelectedPathsLayoutTier tier,
  double viewportWidth,
) {
  return pageInnerContentMaxWidth(
    viewportWidth: viewportWidth,
    horizontalPadding: selectedPathsContentHorizontalPadding(tier),
    capAtMaxWidth: tier == SelectedPathsLayoutTier.expanded,
  );
}
