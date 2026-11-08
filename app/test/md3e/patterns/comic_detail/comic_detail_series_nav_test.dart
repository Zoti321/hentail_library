import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_series_nav.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../support/pump_app.dart';

void main() {
  const List<String> catalog = <String>['第一话', '第二话', '第三话'];

  testWidgets('shows only catalog and opens bottom sheet at any width', (
    WidgetTester tester,
  ) async {
    int? selected;

    await pumpApp(
      tester,
      home: MediaQuery(
        data: const MediaQueryData(size: Size(1024, 800)),
        child: Scaffold(
          body: Center(
            child: ComicDetailSeriesNav(
              catalog: catalog,
              currentIndex: 0,
              onSelectIndex: (int index) => selected = index,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Symbols.chevron_left), findsNothing);
    expect(find.byIcon(Symbols.chevron_right), findsNothing);
    expect(find.byIcon(Symbols.list_alt), findsOneWidget);

    await tester.tap(find.byIcon(Symbols.list_alt));
    await tester.pumpAndSettle();
    expect(find.text('第二话'), findsOneWidget);

    await tester.tap(find.text('第二话'));
    await tester.pumpAndSettle();
    expect(selected, 1);
  });
}
