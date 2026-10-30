import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/motion/md3e_spring_reveal.dart';
import 'package:hentai_library/md3e/widgets/navigation/md3e_library_scroll_to_top_button.dart';

import '../../support/pump_md3e_app.dart';

Finder _revealTransform() => find.descendant(
  of: find.byType(Md3eSpringReveal),
  matching: find.byWidgetPredicate(
    (Widget w) => w is Transform && w.child is Opacity,
  ),
);

// 组件内部（M3EFab）也有 Transform / Opacity，树序第一个即外层显隐节点。
double _revealDy(WidgetTester tester) => tester
    .widgetList<Transform>(_revealTransform())
    .first
    .transform
    .getTranslation()
    .y;

double _revealOpacity(WidgetTester tester) => tester
    .widgetList<Opacity>(
      find.descendant(
        of: find.byType(Md3eSpringReveal),
        matching: find.byType(Opacity),
      ),
    )
    .first
    .opacity;

Future<ScrollController> _pumpLibrary(WidgetTester tester) async {
  final ScrollController controller = ScrollController();
  addTearDown(controller.dispose);
  await pumpMd3eApp(
    tester,
    home: SizedBox(
      width: 390,
      height: 800,
      child: Stack(
        children: <Widget>[
          ListView.builder(
            controller: controller,
            itemCount: 200,
            itemBuilder: (BuildContext context, int index) =>
                SizedBox(height: 80, child: Text('item $index')),
          ),
          Md3eLibraryScrollToTopButton(
            scrollController: controller,
            horizontalPadding: 16,
          ),
        ],
      ),
    ),
  );
  return controller;
}

void main() {
  testWidgets('button springs in past threshold and fades out back at top', (
    WidgetTester tester,
  ) async {
    final ScrollController controller = await _pumpLibrary(tester);
    expect(_revealOpacity(tester), closeTo(0, 0.001));

    controller.jumpTo(3000);
    await tester.pump();

    // 进场中间帧：位移越过原位（负向回弹），透明度在 [0, 1] 内。
    double minDy = double.infinity;
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 8));
      final double dy = _revealDy(tester);
      if (dy < minDy) {
        minDy = dy;
      }
      expect(_revealOpacity(tester), inInclusiveRange(0, 1));
    }
    expect(minDy, lessThan(-0.001), reason: '按钮出现时应有弹簧回弹');
    await tester.pumpAndSettle();
    expect(_revealDy(tester), closeTo(0, 0.001));
    expect(_revealOpacity(tester), closeTo(1, 0.001));

    controller.jumpTo(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final double midOpacity = _revealOpacity(tester);
    expect(midOpacity, lessThan(1), reason: '消失时应平滑退场');
    expect(midOpacity, greaterThan(0));

    await tester.pumpAndSettle();
    expect(_revealOpacity(tester), closeTo(0, 0.001));
  });
}
