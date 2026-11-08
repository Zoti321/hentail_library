import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_page_header.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../support/pump_app.dart';

void main() {
  testWidgets('places edit, series catalog, more to the right of back', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: const Scaffold(
        body: ComicDetailPageHeader(
          onBack: _noop,
          onEdit: _noop,
          showSeriesNav: true,
          seriesCatalog: <String>['第一话', '第二话'],
          seriesCurrentIndex: 0,
        ),
      ),
    );

    final double backX = tester.getCenter(find.byIcon(Symbols.arrow_back)).dx;
    final double editX = tester.getCenter(find.byIcon(Symbols.edit)).dx;
    final double catalogX = tester.getCenter(find.byIcon(Symbols.list_alt)).dx;
    final double moreX = tester.getCenter(find.byIcon(Icons.more_vert)).dx;

    expect(backX, lessThan(editX));
    expect(editX, lessThan(catalogX));
    expect(catalogX, lessThan(moreX));
    expect(find.byIcon(Symbols.chevron_left), findsNothing);
    expect(find.byIcon(Symbols.chevron_right), findsNothing);
  });
}

void _noop() {}
