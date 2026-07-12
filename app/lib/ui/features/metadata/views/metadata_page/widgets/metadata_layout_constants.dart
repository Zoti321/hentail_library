import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/layout/content_search_width.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';
const double kMetadataPanelSubtitleFontSize = 13;
const double kMetadataHeaderVerticalPadding = 6;
const double kMetadataSearchToListSpacing = 16;

enum MetadataLayoutTier { compact, medium, expanded }

MetadataLayoutTier metadataLayoutTierForWidth(double width) {
  if (AppLayoutBreakpoints.isCompact(width)) {
    return MetadataLayoutTier.compact;
  }
  if (AppLayoutBreakpoints.isMedium(width)) {
    return MetadataLayoutTier.medium;
  }
  return MetadataLayoutTier.expanded;
}

double metadataContentHorizontalPadding(MetadataLayoutTier tier) {
  return switch (tier) {
    MetadataLayoutTier.compact => 16,
    MetadataLayoutTier.medium => 28,
    MetadataLayoutTier.expanded => 48,
  };
}

double metadataPageTitleFontSize(MetadataLayoutTier tier) {
  return switch (tier) {
    MetadataLayoutTier.compact => 18,
    MetadataLayoutTier.medium => 22,
    MetadataLayoutTier.expanded => 26,
  };
}

bool metadataRowUsesOverflowMenu(MetadataLayoutTier tier) {
  return tier == MetadataLayoutTier.compact;
}

double metadataInnerContentMaxWidth(
  MetadataLayoutTier tier,
  double viewportWidth,
) {
  return pageInnerContentMaxWidth(
    viewportWidth: viewportWidth,
    horizontalPadding: metadataContentHorizontalPadding(tier),
    capAtMaxWidth: tier == MetadataLayoutTier.expanded,
  );
}

double metadataSearchFieldWidth(
  MetadataLayoutTier tier,
  double contentMaxWidth,
) {
  return contentSearchFieldWidth(switch (tier) {
    MetadataLayoutTier.compact => ContentLayoutTier.compact,
    MetadataLayoutTier.medium => ContentLayoutTier.medium,
    MetadataLayoutTier.expanded => ContentLayoutTier.expanded,
  }, contentMaxWidth);
}

String metadataAddEntityTooltip(int tabIndex) {
  return switch (tabIndex) {
    0 => '添加作者',
    1 => '添加标签',
    _ => '添加',
  };
}
