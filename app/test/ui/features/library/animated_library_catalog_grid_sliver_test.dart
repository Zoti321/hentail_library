import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_catalog_grid_animation.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_page_widgets.dart';

void main() {
  testWidgets(
    'steady-state catalog grid uses SliverGrid without shrinkWrap GridView',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: Scaffold(
            body: CustomScrollView(
              slivers: <Widget>[
                AnimatedLibraryCatalogGridSliver(
                  layoutTier: LibraryLayoutTier.compact,
                  itemCount: 40,
                  positionAnimationKey: 'sort-a',
                  suppressAnimationKey:
                      const LibraryCatalogGridSuppressAnimationKey(
                        keyword: '',
                        ageRestriction:
                            LibraryAgeRestrictionFilter.unrestricted,
                        page: 0,
                        pageSize: 50,
                      ),
                  itemBuilder: (BuildContext context, int index) {
                    return Center(
                      key: ValueKey<String>('item-$index'),
                      child: Text('item-$index'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SliverGrid), findsOneWidget);
      expect(find.byType(ReorderableBuilder), findsNothing);
      expect(find.byType(GridView), findsNothing);

      // Virtualization: not all 40 items are built in a small viewport.
      expect(find.text('item-0'), findsOneWidget);
      expect(find.text('item-39'), findsNothing);
    },
  );
}
