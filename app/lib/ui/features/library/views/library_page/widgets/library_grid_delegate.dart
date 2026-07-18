part of 'library_page_widgets.dart';

/// Main-axis extent for a flush-cover [CatalogCoverCardShell] at [cardWidth].
double catalogCoverCardMainAxisExtent(
  AppThemeTokens tokens,
  double cardWidth,
) {
  // CatalogCoverCardShell: 2:3 cover flush to card width (no side padding).
  final double coverHeight = cardWidth * 3 / 2;
  final double coverToInfoGap = tokens.spacing.md;
  final double titleLineHeight = tokens.text.bodyMd * 1.25;
  const double infoColumnSpacing = 6;
  final double metaLineHeight = tokens.text.labelXs - 1;
  final double infoBottomPad = tokens.spacing.sm;
  return (coverHeight +
              coverToInfoGap +
              titleLineHeight +
              infoColumnSpacing +
              metaLineHeight +
              infoBottomPad)
          .ceil() +
      16;
}

double libraryGridMainAxisExtentFromTokens(
  AppThemeTokens tokens,
  LibraryLayoutTier layoutTier,
) {
  return catalogCoverCardMainAxisExtent(
    tokens,
    libraryGridMaxCrossAxisExtent(layoutTier),
  );
}

SliverGridDelegate libraryGridDelegateForTokens(
  AppThemeTokens tokens,
  LibraryLayoutTier layoutTier,
) {
  final double spacing = libraryGridSpacing(layoutTier);
  return SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: libraryGridMaxCrossAxisExtent(layoutTier),
    mainAxisExtent: libraryGridMainAxisExtentFromTokens(tokens, layoutTier),
    crossAxisSpacing: spacing,
    mainAxisSpacing: spacing,
  );
}
