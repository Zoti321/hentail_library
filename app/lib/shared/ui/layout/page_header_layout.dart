import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/page_content_width_layout.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';

const double kPageHeaderVerticalPadding = 6;
const double kPageHeaderShadowGradientHeight = 6;
const double kPageHeaderSubtitleToSearchSpacing = 12;
const double kPageHeaderSearchToListSpacing = 16;

enum PageHeaderLayoutTier { compact, medium, expanded }

typedef PageHeaderGridMetrics = ({int crossAxisCount, double mainAxisExtent});

PageHeaderLayoutTier pageHeaderLayoutTierForWidth(double width) {
  if (AppLayoutBreakpoints.isCompact(width)) {
    return PageHeaderLayoutTier.compact;
  }
  if (AppLayoutBreakpoints.isMedium(width)) {
    return PageHeaderLayoutTier.medium;
  }
  return PageHeaderLayoutTier.expanded;
}

double pageHeaderHorizontalPadding(PageHeaderLayoutTier tier) {
  return switch (tier) {
    PageHeaderLayoutTier.compact => 16,
    PageHeaderLayoutTier.medium => 28,
    PageHeaderLayoutTier.expanded => 48,
  };
}

double pageHeaderTitleFontSize(PageHeaderLayoutTier tier) {
  return switch (tier) {
    PageHeaderLayoutTier.compact => 18,
    PageHeaderLayoutTier.medium => 22,
    PageHeaderLayoutTier.expanded => 26,
  };
}

double pageHeaderInnerMaxWidth(
  PageHeaderLayoutTier tier,
  double viewportWidth,
) {
  return pageInnerContentMaxWidth(
    viewportWidth: viewportWidth,
    horizontalPadding: pageHeaderHorizontalPadding(tier),
    capAtMaxWidth: tier == PageHeaderLayoutTier.expanded,
  );
}

PageHeaderGridMetrics pageHeaderGridMetrics(
  PageHeaderLayoutTier tier,
  double viewportWidth,
) {
  final double paddedWidth =
      viewportWidth - pageHeaderHorizontalPadding(tier) * 2;
  return switch (tier) {
    PageHeaderLayoutTier.compact => (crossAxisCount: 1, mainAxisExtent: 120.0),
    PageHeaderLayoutTier.medium => (crossAxisCount: 2, mainAxisExtent: 132.0),
    PageHeaderLayoutTier.expanded =>
      paddedWidth >= kPageContentMaxWidth
          ? (crossAxisCount: 4, mainAxisExtent: 138.0)
          : (crossAxisCount: 3, mainAxisExtent: 138.0),
  };
}

TextStyle pageHeaderTitleStyle(
  HentaiColorScheme semantic,
  PageHeaderLayoutTier layoutTier,
) {
  return TextStyle(
    color: semantic.textPrimary,
    fontSize: pageHeaderTitleFontSize(layoutTier),
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );
}
