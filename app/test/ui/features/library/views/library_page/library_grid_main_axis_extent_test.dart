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

  group('libraryGridMainAxisExtentFromTokens', () {
    test('is tall enough for edge-to-edge catalog cover cards', () {
      for (final LibraryLayoutTier tier in LibraryLayoutTier.values) {
        final double maxCross = libraryGridMaxCrossAxisExtent(tier);
        final double needed = _flushCoverCatalogCardHeight(tokens, maxCross);
        final double extent = libraryGridMainAxisExtentFromTokens(tokens, tier);

        expect(
          extent,
          greaterThanOrEqualTo(needed),
          reason:
              '$tier: extent=$extent must cover flush-cover height $needed '
              '(maxCross=$maxCross)',
        );
      }
    });
  });

  group('CatalogCoverCardShell in library grid cell', () {
    testWidgets('does not overflow at formula mainAxisExtent', (
      WidgetTester tester,
    ) async {
      for (final LibraryLayoutTier tier in LibraryLayoutTier.values) {
        final double width = libraryGridMaxCrossAxisExtent(tier);
        final double height = libraryGridMainAxisExtentFromTokens(tokens, tier);

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
