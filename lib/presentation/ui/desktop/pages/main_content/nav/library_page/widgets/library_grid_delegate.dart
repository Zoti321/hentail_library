part of 'library_page_widgets.dart';

const double _kLibraryGridMaxCrossAxisExtent = 200;
const double _kLibraryGridCrossAxisSpacing = 16;
const double _kLibraryGridMainAxisSpacing = 16;

double libraryGridMainAxisExtentFromTokens(AppThemeTokens tokens) {
  final double pad = tokens.spacing.sm;
  final double innerWidth = _kLibraryGridMaxCrossAxisExtent - 2 * pad;
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

SliverGridDelegate libraryGridDelegateForTokens(AppThemeTokens tokens) {
  return SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: _kLibraryGridMaxCrossAxisExtent,
    mainAxisExtent: libraryGridMainAxisExtentFromTokens(tokens),
    crossAxisSpacing: _kLibraryGridCrossAxisSpacing,
    mainAxisSpacing: _kLibraryGridMainAxisSpacing,
  );
}
