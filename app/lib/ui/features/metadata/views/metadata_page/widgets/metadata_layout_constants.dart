import 'dart:math' as math;

import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/layout/content_search_width.dart';

const double metadataContentMaxWidth = 1280;

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

double metadataPanelTitleFontSize(MetadataLayoutTier tier) {
  return switch (tier) {
    MetadataLayoutTier.compact => 18,
    MetadataLayoutTier.medium => 22,
    MetadataLayoutTier.expanded => 26,
  };
}

bool metadataShowsPageSubtitle(MetadataLayoutTier tier) {
  return tier != MetadataLayoutTier.compact;
}

bool metadataPanelHeaderIsVertical(MetadataLayoutTier tier) {
  return tier == MetadataLayoutTier.compact;
}

bool metadataListFillsAvailableHeight(MetadataLayoutTier tier) {
  return tier == MetadataLayoutTier.compact;
}

bool metadataRowUsesOverflowMenu(MetadataLayoutTier tier) {
  return tier == MetadataLayoutTier.compact;
}

double metadataInnerContentMaxWidth(
  MetadataLayoutTier tier,
  double viewportWidth,
) {
  final double horizontalPadding = metadataContentHorizontalPadding(tier);
  final double paddedWidth = viewportWidth - horizontalPadding * 2;
  return switch (tier) {
    MetadataLayoutTier.expanded => math.min(
      paddedWidth,
      metadataContentMaxWidth,
    ),
    MetadataLayoutTier.compact || MetadataLayoutTier.medium => paddedWidth,
  };
}

double metadataSearchFieldWidth(
  MetadataLayoutTier tier,
  double contentMaxWidth,
) {
  return contentSearchFieldWidth(
    switch (tier) {
      MetadataLayoutTier.compact => ContentLayoutTier.compact,
      MetadataLayoutTier.medium => ContentLayoutTier.medium,
      MetadataLayoutTier.expanded => ContentLayoutTier.expanded,
    },
    contentMaxWidth,
  );
}

String metadataAddButtonLabel(
  MetadataLayoutTier tier,
  String entityName,
  String shortcutLabel,
) {
  if (tier == MetadataLayoutTier.compact) {
    return '添加$entityName';
  }
  return '添加$entityName ($shortcutLabel)';
}
