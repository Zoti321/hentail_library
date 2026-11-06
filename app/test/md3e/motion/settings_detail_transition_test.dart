import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';
import 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_page_body.dart';

import '../../support/pump_app.dart';

/// 窄屏 master↔detail 仍用弹簧 SlideTransition。
Finder _detailSlide() => find.ancestor(
  of: find.byKey(const Key('_settings_detail')),
  matching: find.byWidgetPredicate(
    (Widget w) => w is SlideTransition && w.child is FadeTransition,
  ),
);

double _detailDx(WidgetTester tester) {
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
  await pumpApp(
    tester,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: const SizedBox(width: 390, height: 800, child: SettingsLayout()),
    ),
  );
}

Future<void> _tapFirstMasterItem(WidgetTester tester) async {
  await tester.tap(
    find
        .descendant(
          of: find.byKey(const Key('_settings_master')),
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

    expect(find.byKey(const Key('_settings_detail')), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const Key('_settings_detail')),
        matching: find.byType(AnimatedSwitcher),
      ),
      findsNothing,
    );
  });

  testWidgets('wide layout detail category switch uses fade through', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(
      tester,
      home: const Center(
        child: SizedBox(
          width: 1280,
          height: 800,
          child: SettingsLayout(
            initialCategory: SettingsCategory.personalization,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('_settings_detail')), findsOneWidget);

    await tester.tap(
      find
          .descendant(
            of: find.byKey(const Key('_settings_master')),
            matching: find.byType(InkWell),
          )
          .at(1),
    );
    await tester.pump();

    expect(find.byType(PageTransitionSwitcher), findsWidgets);
    expect(find.byType(FadeThroughTransition), findsWidgets);

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('_settings_detail')), findsOneWidget);
  });
}
