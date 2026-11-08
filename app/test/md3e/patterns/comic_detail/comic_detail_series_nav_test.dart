import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_series_nav.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../support/pump_app.dart';

Widget _host({required double width, required Widget child}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 800)),
    child: Scaffold(body: Center(child: child)),
  );
}

void main() {
  const List<String> catalog = <String>['第一话', '第二话', '第三话'];

  testWidgets('medium- opens bottom sheet without title', (
    WidgetTester tester,
  ) async {
    int? selected;

    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      home: _host(
        width: 390,
        child: ComicDetailSeriesNav(
          catalog: catalog,
          currentIndex: 0,
          onSelectIndex: (int index) => selected = index,
        ),
      ),
    );

    await tester.tap(find.byIcon(Symbols.list_alt));
    await tester.pumpAndSettle();

    expect(find.text('系列目录'), findsNothing);
    expect(find.text('第二话'), findsOneWidget);

    await tester.tap(find.text('第二话'));
    await tester.pumpAndSettle();
    expect(selected, 1);
  });

  testWidgets('expanded+ opens side sheet with title', (
    WidgetTester tester,
  ) async {
    int? selected;

    await tester.binding.setSurfaceSize(const Size(1024, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      home: _host(
        width: 1024,
        child: ComicDetailSeriesNav(
          catalog: catalog,
          currentIndex: 0,
          onSelectIndex: (int index) => selected = index,
        ),
      ),
    );

    await tester.tap(find.byIcon(Symbols.list_alt));
    await tester.pumpAndSettle();

    expect(find.text('系列目录'), findsOneWidget);
    expect(find.text('第二话'), findsOneWidget);

    await tester.tap(find.text('第二话'));
    await tester.pumpAndSettle();
    expect(selected, 1);
  });
}
