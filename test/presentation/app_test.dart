import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/app/app.dart';

void main() {
  testWidgets('MyApp smoke - pumps and shows home', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('首页'), findsAtLeast(1));
  });
}
