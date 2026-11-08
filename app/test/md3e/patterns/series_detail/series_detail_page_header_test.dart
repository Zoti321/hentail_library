import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/series/presentation/patterns/series_detail/series_detail_page_header.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../support/pump_app.dart';

void main() {
  testWidgets('places page size, edit, more to the right of back', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: Scaffold(
        body: SeriesDetailPageHeader(
          onBack: () {},
          onEdit: () {},
          pageSize: 24,
          onPageSizeChanged: (_) {},
        ),
      ),
    );

    final double backX = tester.getCenter(find.byIcon(Symbols.arrow_back)).dx;
    final double pageSizeX = tester
        .getCenter(find.byIcon(Symbols.grid_view))
        .dx;
    final double editX = tester.getCenter(find.byIcon(Symbols.edit)).dx;
    final double moreX = tester.getCenter(find.byIcon(Icons.more_vert)).dx;

    expect(backX, lessThan(pageSizeX));
    expect(pageSizeX, lessThan(editX));
    expect(editX, lessThan(moreX));
  });
}
