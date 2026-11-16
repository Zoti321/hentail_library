import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';

import '../../../support/pump_design_system_app.dart';

void main() {
  testWidgets('chip field recomputes multiline insets after local resizing', (
    tester,
  ) async {
    final width = ValueNotifier(560.0);
    addTearDown(width.dispose);
    await pumpDesignSystemApp(
      tester,
      home: Scaffold(
        body: Center(
          child: ValueListenableBuilder<double>(
            valueListenable: width,
            builder: (_, w, _) => SizedBox(
              width: w,
              child: const TagInputField(
                label: 'Tags',
                minWidth: 0,
                tags: ['Alpha tag', 'Beta tag', 'Gamma tag', 'Delta tag'],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final originalHeight = tester.getSize(find.byType(TagInputField)).height;
    width.value = 200;
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(TagInputField)).height,
      greaterThan(originalHeight),
    );
    width.value = 560;
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(TagInputField)).height,
      closeTo(originalHeight, .01),
    );
    expect(tester.takeException(), isNull);
  });
}
