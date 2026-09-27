import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_catalog_grid_animation.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_page_widgets.dart';

void main() {
  testWidgets('page-only suppress key change runs page transition animation', (
    WidgetTester tester,
  ) async {
    const LibraryCatalogGridSuppressAnimationKey pageOne =
        LibraryCatalogGridSuppressAnimationKey(
          keyword: '',
          ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
          page: 1,
          pageSize: 50,
        );
    const LibraryCatalogGridSuppressAnimationKey pageTwo =
        LibraryCatalogGridSuppressAnimationKey(
          keyword: '',
          ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
          page: 2,
          pageSize: 50,
        );

    LibraryCatalogGridSuppressAnimationKey suppressKey = pageOne;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              body: CustomScrollView(
                slivers: <Widget>[
                  AnimatedLibraryCatalogGridSliver(
                    layoutTier: LibraryLayoutTier.compact,
                    itemCount: 4,
                    positionAnimationKey: 'sort-a',
                    sortFlipEnabled: false,
                    suppressAnimationKey: suppressKey,
                    itemBuilder: (BuildContext context, int index) {
                      return Center(
                        key: ValueKey<String>('item-$index'),
                        child: Text('item-$index'),
                      );
                    },
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => setState(() => suppressKey = pageTwo),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    final Finder gridFadeTransitions = find.descendant(
      of: find.byType(SliverGrid),
      matching: find.byType(FadeTransition),
    );
    expect(gridFadeTransitions, findsNothing);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(gridFadeTransitions, findsWidgets);

    await tester.pumpAndSettle();

    expect(gridFadeTransitions, findsNothing);
    expect(find.byType(SliverGrid), findsOneWidget);
  });
}
