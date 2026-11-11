import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../support/pump_app.dart';

void main() {
  testWidgets('toggles between grid and list modes', (
    WidgetTester tester,
  ) async {
    CatalogViewMode mode = CatalogViewMode.grid;

    await pumpApp(
      tester,
      home: Center(
        child: CatalogViewModeButtonGroup(
          mode: mode,
          onModeChanged: (CatalogViewMode value) => mode = value,
        ),
      ),
    );

    expect(find.byType(M3EButtonGroup), findsOneWidget);
    expect(CatalogViewModeButtonGroup.indexForMode(mode), 0);

    await tester.tap(find.bySemanticsLabel('列表视图'));
    await tester.pumpAndSettle();

    expect(mode, CatalogViewMode.list);
    expect(CatalogViewModeButtonGroup.indexForMode(mode), 1);
  });
}
