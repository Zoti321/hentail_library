import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/layout/reading_history_list_layout.dart';
import 'package:hentai_library/shared/ui/motion/spring_expand_panel.dart';
import 'package:hentai_library/shared/ui/widgets/history/reading_history_list_item_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

void main() {
  group('ReadingHistoryListGrid virtualization', () {
    test('readingHistoryGridTotalHeight matches rowHeight and gaps', () {
      final ReadingHistoryListLayoutSpec layout =
          ReadingHistoryListItemMetrics.layoutForViewportWidth(
            700,
            horizontalInset: 0,
          );
      final int columns = layout.columnCount;
      const int itemCount = 50;
      final int rowCount = (itemCount + columns - 1) ~/ columns;
      final double expected =
          rowCount * layout.itemSpec.rowHeight +
          (rowCount - 1) * layout.gap;

      expect(
        readingHistoryGridTotalHeight(itemCount: itemCount, layout: layout),
        expected,
      );
      expect(
        readingHistoryGridTotalHeight(itemCount: 0, layout: layout),
        0,
      );
    });

    testWidgets('does not mount every item for a large bucket', (
      WidgetTester tester,
    ) async {
      const int itemCount = 200;
      await tester.binding.setSurfaceSize(const Size(700, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: M3ETheme(
            data: M3EThemeData.light(),
            child: Scaffold(
              body: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: ReadingHistoryListGrid(
                      itemCount: itemCount,
                      itemBuilder: (BuildContext context, int index) {
                        return SizedBox(
                          height: 48,
                          child: Text('item-$index'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final int mounted = tester
          .widgetList<Text>(
            find.byWidgetPredicate(
              (Widget w) => w is Text && w.data!.startsWith('item-'),
            ),
          )
          .length;

      expect(mounted, greaterThan(0));
      expect(mounted, lessThan(itemCount));
      expect(find.text('item-0'), findsOneWidget);
      expect(find.text('item-${itemCount - 1}'), findsNothing);
    });

    testWidgets('keeps SpringExpandPanel while virtualizing group body', (
      WidgetTester tester,
    ) async {
      const int itemCount = 120;
      await tester.binding.setSurfaceSize(const Size(700, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: M3ETheme(
            data: M3EThemeData.light(),
            child: Scaffold(
              body: CustomScrollView(
                slivers: <Widget>[
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  const SliverToBoxAdapter(child: Text('section-header')),
                  SliverToBoxAdapter(
                    child: SpringExpandPanel(
                      expanded: true,
                      child: ReadingHistoryListGrid(
                        itemCount: itemCount,
                        itemBuilder: (BuildContext context, int index) {
                          return SizedBox(
                            height: 48,
                            child: Text('cell-$index'),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SpringExpandPanel), findsOneWidget);
      expect(find.byType(ReadingHistoryListGrid), findsOneWidget);

      final int mounted = tester
          .widgetList<Text>(
            find.byWidgetPredicate(
              (Widget w) => w is Text && w.data!.startsWith('cell-'),
            ),
          )
          .length;
      expect(mounted, greaterThan(0));
      expect(mounted, lessThan(itemCount));
    });

    testWidgets('scroll reveals later rows without mounting the whole bucket', (
      WidgetTester tester,
    ) async {
      const int itemCount = 200;
      await tester.binding.setSurfaceSize(const Size(700, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: M3ETheme(
            data: M3EThemeData.light(),
            child: Scaffold(
              body: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: ReadingHistoryListGrid(
                      itemCount: itemCount,
                      itemBuilder: (BuildContext context, int index) {
                        return SizedBox(
                          height: 48,
                          child: Text('scroll-$index'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('scroll-0'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2400));
      await tester.pump();
      await tester.pump();

      final int mounted = tester
          .widgetList<Text>(
            find.byWidgetPredicate(
              (Widget w) => w is Text && w.data!.startsWith('scroll-'),
            ),
          )
          .length;
      expect(mounted, lessThan(itemCount));
      expect(find.text('scroll-0'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Text &&
              w.data != null &&
              w.data!.startsWith('scroll-') &&
              int.parse(w.data!.substring('scroll-'.length)) > 20,
        ),
        findsWidgets,
      );
    });
  });
}
