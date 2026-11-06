import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/widgets/actions/filled_button.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('ExpressiveFilledButton shows label and responds to tap', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await pumpApp(
      tester,
      home: Center(
        child: ExpressiveFilledButton(label: '继续', onPressed: () => tapped = true),
      ),
    );
    expect(find.text('继续'), findsOneWidget);
    await tester.tap(find.text('继续'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
