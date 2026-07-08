part of 'library_page_widgets.dart';

double libraryGridMainAxisExtentFromTokens(
  AppThemeTokens tokens,
  LibraryLayoutTier layoutTier,
) {
  final double maxCrossAxisExtent = libraryGridMaxCrossAxisExtent(layoutTier);
  final double pad = tokens.spacing.sm;
  final double innerWidth = maxCrossAxisExtent - 2 * pad;
  final double coverHeight = innerWidth * 3 / 2;
  const double coverToInfoGap = 12;
  final double titleLineHeight = tokens.text.bodyMd * 1.25;
  const double infoColumnSpacing = 6;
  final double metaLineHeight = tokens.text.labelXs - 1;
  return (2 * pad +
              coverHeight +
              coverToInfoGap +
              titleLineHeight +
              infoColumnSpacing +
              metaLineHeight)
          .ceil() +
      16;
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
