import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_lab_reader_navigation.dart';
import 'package:hentai_library/md3e/pages/md3e_reader_page_lab_host.dart';

import '../../support/pump_md3e_app.dart';

Finder _routeSlide() => find.ancestor(
  of: find.byType(Md3eReaderPageLabHost),
  matching: find.byType(SlideTransition),
);

double _routeDx(WidgetTester tester) {
  return tester.widget<SlideTransition>(_routeSlide().first).position.value.dx;
}

/// 点击后路由挂载时机不固定，轮询直到页面出现（最多约 160ms）。
Future<void> _pumpUntilRouteMounted(WidgetTester tester) async {
  for (int i = 0; i < 20 && _routeSlide().evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 8));
  }
}

Future<void> _pumpLauncher(WidgetTester tester) async {
  await pumpMd3eApp(
    tester,
    home: Builder(
      builder: (BuildContext context) {
        return TextButton(
          onPressed: () => openMd3eLabReader(context),
          child: const Text('open'),
        );
      },
    ),
  );
}

void main() {
  testWidgets('forward route slides in from the right with spring overshoot', (
    WidgetTester tester,
  ) async {
    await _pumpLauncher(tester);
    await tester.tap(find.text('open'));
    await _pumpUntilRouteMounted(tester);

    expect(_routeDx(tester), greaterThan(0), reason: '进场起点应在右侧');

    double minDx = double.infinity;
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 8));
      final double dx = _routeDx(tester);
      if (dx < minDx) {
        minDx = dx;
      }
    }
    // 弹簧过冲：位移会越过终点（dx < 0）。固定曲线不会出现这一现象。
    expect(minDx, lessThan(0));

    await tester.pumpAndSettle();
    expect(_routeDx(tester), closeTo(0, 0.001));
  });

  testWidgets('back route reverses direction and removes the page', (
    WidgetTester tester,
  ) async {
    await _pumpLauncher(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(_routeDx(tester), closeTo(0, 0.001));

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    // 第一帧确定反向动画起点，之后再推进 50ms 观察位移。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_routeDx(tester), greaterThan(0), reason: '后退时页面应向右滑出');

    await tester.pumpAndSettle();
    expect(find.byType(Md3eReaderPageLabHost), findsNothing);
  });

  testWidgets('reduce motion switches route without any slide', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () => openMd3eLabReader(context),
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();

    expect(_routeSlide(), findsNothing);
    expect(find.byType(Md3eReaderPageLabHost), findsOneWidget);
  });
}
