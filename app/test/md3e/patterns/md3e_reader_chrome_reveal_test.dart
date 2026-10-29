import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome_overlay.dart';

import '../../support/pump_md3e_app.dart';

/// 底栏在 Transform.translate 下的 dy（bottom=true 时 dy = (1-raw)*hideSlidePx）。
double _bottomDy(WidgetTester tester) {
  final Transform transform = tester.widget<Transform>(
    find.descendant(
      of: find.byKey(const ValueKey<String>('bottom')),
      matching: find.byType(Transform),
    ),
  );
  return transform.transform.getTranslation().y;
}

void main() {
  testWidgets('bottom chrome reveal overshoots like M3E spring, then settles', (
    WidgetTester tester,
  ) async {
    Widget build({required bool visible}) => SizedBox(
      width: 400,
      height: 300,
      child: Md3eReaderChromeReveal(
        key: const ValueKey<String>('bottom'),
        visible: visible,
        top: false,
        child: const SizedBox(height: 48, child: Text('bottom')),
      ),
    );

    await pumpMd3eApp(tester, home: build(visible: false));
    await pumpMd3eApp(tester, home: build(visible: true));

    // 弹簧过冲：显示过程中位移会越过 0（dy < 0）。线性/固定曲线不会出现这一现象。
    double minDy = double.infinity;
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final double dy = _bottomDy(tester);
      if (dy < minDy) {
        minDy = dy;
      }
    }
    expect(minDy, lessThan(0));

    await tester.pumpAndSettle();
    expect(_bottomDy(tester), closeTo(0, 0.01));
  });
}
