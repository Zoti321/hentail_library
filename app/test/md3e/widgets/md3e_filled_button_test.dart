import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/widgets/actions/md3e_filled_button.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('Md3eFilledButton shows label and responds to tap', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await pumpMd3eApp(
      tester,
      home: Center(
        child: Md3eFilledButton(
          label: '继续',
          onPressed: () => tapped = true,
        ),
      ),
    );
    expect(find.text('继续'), findsOneWidget);
    await tester.tap(find.text('继续'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
