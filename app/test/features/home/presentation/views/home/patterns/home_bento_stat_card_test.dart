import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_bento_stat_card.dart';
import 'package:material_3_expressive/components/lists/components/m3e_card_radius_motion.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../../support/pump_app.dart';

Future<void> _pumpCard(
  WidgetTester tester, {
  required HomeBentoStatLayout layout,
  String caption = '说明',
  VoidCallback? onPressed,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await pumpApp(
    tester,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 240,
          child: HomeBentoStatCard(
            label: '标题',
            caption: caption,
            icon: Symbols.history,
            backgroundColor: const Color(0xFF3355FF),
            onBackgroundColor: Colors.white,
            borderRadius: BorderRadius.circular(20),
            layout: layout,
            onPressed: onPressed,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shortcut 布局在可点击时显示右上箭头', (WidgetTester tester) async {
    await _pumpCard(
      tester,
      layout: HomeBentoStatLayout.shortcut,
      onPressed: () {},
    );

    expect(find.byIcon(Symbols.arrow_forward), findsOneWidget);
    expect(find.text('标题'), findsOneWidget);
    expect(find.text('说明'), findsOneWidget);
  });

  testWidgets('shortcut 布局不可点击时隐藏箭头', (WidgetTester tester) async {
    await _pumpCard(tester, layout: HomeBentoStatLayout.shortcut);

    expect(find.byIcon(Symbols.arrow_forward), findsNothing);
  });

  testWidgets('caption 为空时不渲染副文案', (WidgetTester tester) async {
    await _pumpCard(
      tester,
      layout: HomeBentoStatLayout.shortcut,
      caption: '  ',
      onPressed: () {},
    );

    expect(find.text('标题'), findsOneWidget);
    expect(find.text('说明'), findsNothing);
  });

  testWidgets('按下时圆角向 tonal surface 收敛', (WidgetTester tester) async {
    await _pumpCard(
      tester,
      layout: HomeBentoStatLayout.shortcut,
      onPressed: () {},
    );

    expect(
      tester
          .widget<M3ECardRadiusMotion>(find.byType(M3ECardRadiusMotion))
          .radius,
      BorderRadius.circular(20),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(HomeBentoStatCard)),
    );
    await tester.pump();

    expect(
      tester
          .widget<M3ECardRadiusMotion>(find.byType(M3ECardRadiusMotion))
          .radius,
      BorderRadius.circular(kTonalSurfaceRadius),
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
