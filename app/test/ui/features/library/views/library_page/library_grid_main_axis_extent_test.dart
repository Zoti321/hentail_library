import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/catalog_cover_card_shell.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_page_widgets.dart';

/// Intrinsic height of [CatalogCoverCardShell] when cover is flush to the card
/// width (no horizontal padding around the 2:3 cover).
double _flushCoverCatalogCardHeight(AppThemeTokens tokens, double cardWidth) {
  final double coverHeight = cardWidth * 3 / 2;
  final double titleLineHeight = tokens.text.bodyMd * 1.25;
  const double infoColumnSpacing = 6;
  final double metaLineHeight = tokens.text.labelXs - 1;
  return coverHeight +
      tokens.spacing.md +
      titleLineHeight +
      infoColumnSpacing +
      metaLineHeight +
      tokens.spacing.sm;
}

void main() {
  final AppThemeTokens tokens = AppThemeTokens.shared;

  group('catalogCoverCardMainAxisExtent', () {
    test('is tall enough for arbitrary flush-cover card widths', () {
      const List<double> cardWidths = <double>[120, 168, 188, 200, 240];
      for (final double cardWidth in cardWidths) {
        final double needed = _flushCoverCatalogCardHeight(tokens, cardWidth);
        final double extent = catalogCoverCardMainAxisExtent(tokens, cardWidth);

        expect(
          extent,
          greaterThanOrEqualTo(needed),
          reason:
              'width=$cardWidth: extent=$extent must cover flush-cover '
              'height $needed',
        );
      }
    });

    test('library grid helper delegates to card-width formula', () {
      for (final LibraryLayoutTier tier in LibraryLayoutTier.values) {
        final double maxCross = libraryGridMaxCrossAxisExtent(tier);
        expect(
          libraryGridMainAxisExtentFromTokens(tokens, tier),
          catalogCoverCardMainAxisExtent(tokens, maxCross),
        );
      }
    });
  });

  group('CatalogCoverCardShell at formula mainAxisExtent', () {
    testWidgets('does not overflow for each library layout tier card size', (
      WidgetTester tester,
    ) async {
      for (final LibraryLayoutTier tier in LibraryLayoutTier.values) {
        final double width = libraryGridMaxCrossAxisExtent(tier);
        final double height = catalogCoverCardMainAxisExtent(tokens, width);

        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(Brightness.light),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  height: height,
                  child: CatalogCoverCardShell(
                    cover: const ColoredBox(color: Colors.grey),
                    info: (bool isHover) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: <Widget>[
                        Text(
                          'Title',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: tokens.text.bodyMd,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        Text(
                          '0 页',
                          style: TextStyle(fontSize: tokens.text.labelXs - 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '$tier ${width}x$height must not overflow',
        );
      }
    });
  });
}
