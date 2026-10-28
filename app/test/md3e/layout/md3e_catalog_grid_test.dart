import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/layout/md3e_catalog_grid.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_card.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('Md3eCatalogGridSliver uses fixed cross axis count delegate', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: SizedBox(
        width: 800,
        height: 600,
        child: Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              Md3eCatalogGridSliver(
                itemCount: 2,
                itemBuilder: (BuildContext context, int index, _) {
                  return Md3eComicCard(
                    title: 'Item $index',
                    subtitle: '12 页',
                    cover: const ColoredBox(color: Color(0xFFE0E0E0)),
                    onTap: () {},
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    final Finder grid = find.byType(SliverGrid);
    expect(grid, findsOneWidget);
    final SliverGrid sliverGrid = tester.widget<SliverGrid>(grid);
    final SliverGridDelegateWithFixedCrossAxisCount delegate =
        sliverGrid.gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, greaterThan(1));
    expect(delegate.mainAxisExtent, greaterThan(200));
  });
}
