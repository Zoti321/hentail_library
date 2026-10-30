import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/pages/md3e_settings_page.dart';

import '../../support/pump_md3e_app.dart';

/// 详情页外层最近的 SlideTransition（即切换器加的那一层，直接包着 FadeTransition）。
Finder _detailSlide() => find.ancestor(
  of: find.byKey(const Key('md3e_settings_detail')),
  matching: find.byWidgetPredicate(
    (Widget w) => w is SlideTransition && w.child is FadeTransition,
  ),
);

double _detailDx(WidgetTester tester) {
  // 最近的祖先排在最前。
  return tester
      .widgetList<SlideTransition>(_detailSlide())
      .first
      .position
      .value
      .dx;
}

Future<void> _pumpCompactSettings(
  WidgetTester tester, {
  bool reduceMotion = false,
}) async {
  await pumpMd3eApp(
    tester,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: const SizedBox(width: 390, height: 800, child: Md3eSettingsPage()),
    ),
  );
}

Future<void> _tapFirstMasterItem(WidgetTester tester) async {
  await tester.tap(
    find
        .descendant(
          of: find.byKey(const Key('md3e_settings_master')),
          matching: find.byType(InkWell),
        )
        .first,
  );
}

void main() {
  testWidgets('detail slides in with spring overshoot and settles at zero', (
    WidgetTester tester,
  ) async {
    await _pumpCompactSettings(tester);
    await _tapFirstMasterItem(tester);

    // 点击后详情页挂载时机不固定，轮询直到出现，再开始采样。
    for (int i = 0; i < 20 && _detailSlide().evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 8));
    }
    expect(_detailSlide(), findsWidgets);

    double minDx = _detailDx(tester);
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 8));
      if (_detailSlide().evaluate().isEmpty) {
        break;
      }
      final double dx = _detailDx(tester);
      if (dx < minDx) {
        minDx = dx;
      }
    }

    // 弹簧回弹：中间帧位移应越过终点 0（负向过冲）。
    expect(minDx, lessThan(-0.001), reason: '详情页进场应有弹簧过冲');

    await tester.pumpAndSettle();
    expect(_detailDx(tester), closeTo(0, 0.001));
  });

  testWidgets('reduce motion switches to detail without any slide', (
    WidgetTester tester,
  ) async {
    await _pumpCompactSettings(tester, reduceMotion: true);
    await _tapFirstMasterItem(tester);
    await tester.pump();

    expect(find.byKey(const Key('md3e_settings_detail')), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const Key('md3e_settings_detail')),
        matching: find.byType(AnimatedSwitcher),
      ),
      findsNothing,
    );
  });
}
