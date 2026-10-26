import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/widgets/actions/md3e_catalog_view_mode_button_group.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('toggles between grid and list modes', (WidgetTester tester) async {
    Md3eCatalogViewMode mode = Md3eCatalogViewMode.grid;

    await pumpMd3eApp(
      tester,
      home: Center(
        child: Md3eCatalogViewModeButtonGroup(
          mode: mode,
          onModeChanged: (Md3eCatalogViewMode value) => mode = value,
        ),
      ),
    );

    expect(find.byType(M3EButtonGroup), findsOneWidget);
    expect(
      Md3eCatalogViewModeButtonGroup.indexForMode(mode),
      0,
    );

    await tester.tap(find.bySemanticsLabel('列表视图'));
    await tester.pumpAndSettle();

    expect(mode, Md3eCatalogViewMode.list);
    expect(
      Md3eCatalogViewModeButtonGroup.indexForMode(mode),
      1,
    );
  });
}
