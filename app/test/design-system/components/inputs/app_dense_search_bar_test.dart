import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../support/pump_design_system_app.dart';

void main() {
  for (final width in [240.0, double.infinity]) {
    testWidgets('search fits local width $width with result count', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final field = AppDenseSearchBar(
        controller: controller,
        hintText: 'Search',
        matchCountLabel: '100 results',
        onChanged: (_) {},
      );
      await pumpDesignSystemApp(
        tester,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: width.isFinite
                ? SizedBox(width: width, child: field)
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: field,
                  ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(M3ESearchBar)).width,
        lessThanOrEqualTo(width.isFinite ? width : AppDenseSearchBar.maxWidth),
      );
      expect(find.text('100 results'), findsOneWidget);
    });
  }
}
