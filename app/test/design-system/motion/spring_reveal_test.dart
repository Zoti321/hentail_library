import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:motor/motor.dart';

import '../../support/pump_design_system_app.dart';

const Offset _hidden = Offset(120, 0);

double _dx(WidgetTester tester) {
  final Transform transform = tester.widget<Transform>(
    find.descendant(
      of: find.byType(SpringReveal),
      matching: find.byType(Transform),
    ),
  );
  return transform.transform.getTranslation().x;
}

Future<List<double>> _sampleFirstFrames(
  WidgetTester tester,
  Motion motion,
) async {
  Widget build({required bool visible}) => SizedBox(
    width: 400,
    height: 200,
    child: SpringReveal(
      visible: visible,
      motion: motion,
      hiddenOffset: _hidden,
      child: const SizedBox(height: 40, child: Text('reveal')),
    ),
  );

  await pumpDesignSystemApp(tester, home: build(visible: false));
  await pumpDesignSystemApp(tester, home: build(visible: true));

  final List<double> samples = <double>[];
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    samples.add(_dx(tester));
  }
  await tester.pumpAndSettle();
  return samples;
}

void main() {
  for (final reduceMotion in [false, true]) {
    testWidgets(
      'hidden reveal excludes keyboard focus (reduceMotion=$reduceMotion)',
      (tester) async {
        final focus = FocusNode();
        addTearDown(focus.dispose);
        final visible = ValueNotifier(true);
        addTearDown(visible.dispose);
        await pumpDesignSystemApp(
          tester,
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: ValueListenableBuilder<bool>(
              valueListenable: visible,
              builder: (context, show, _) => SpringReveal(
                visible: show,
                hiddenOffset: _hidden,
                child: TextButton(
                  focusNode: focus,
                  onPressed: () {},
                  child: const Text('action'),
                ),
              ),
            ),
          ),
        );
        focus.requestFocus();
        await tester.pump();
        expect(focus.hasFocus, isTrue);
        visible.value = false;
        await tester.pump();
        expect(focus.canRequestFocus, isFalse);
        await tester.pumpAndSettle();
        expect(focus.hasFocus, isFalse);
        visible.value = true;
        await tester.pumpAndSettle();
        focus.requestFocus();
        await tester.pump();
        expect(focus.hasFocus, isTrue);
      },
    );
  }

  testWidgets('不同 motion 给出不同轨迹', (WidgetTester tester) async {
    final List<double> spatial = await _sampleFirstFrames(
      tester,
      LabMotion.spatialReveal,
    );
    final List<double> effects = await _sampleFirstFrames(
      tester,
      LabMotion.effectsSpring,
    );

    expect(spatial, isNot(effects));
  });

  testWidgets('隐藏后不接收指针，显示后归位', (WidgetTester tester) async {
    await pumpDesignSystemApp(
      tester,
      home: const SizedBox(
        width: 400,
        height: 200,
        child: SpringReveal(
          visible: false,
          hiddenOffset: _hidden,
          child: SizedBox(height: 40, child: Text('reveal')),
        ),
      ),
    );

    expect(
      tester
          .widget<IgnorePointer>(
            find
                .descendant(
                  of: find.byType(SpringReveal),
                  matching: find.byType(IgnorePointer),
                )
                .first,
          )
          .ignoring,
      isTrue,
    );
    expect(_dx(tester), closeTo(_hidden.dx, 0.01));

    await pumpDesignSystemApp(
      tester,
      home: const SizedBox(
        width: 400,
        height: 200,
        child: SpringReveal(
          visible: true,
          hiddenOffset: _hidden,
          child: SizedBox(height: 40, child: Text('reveal')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_dx(tester), closeTo(0, 0.01));
  });

  testWidgets('reduce motion 下直接到位', (WidgetTester tester) async {
    await pumpDesignSystemApp(
      tester,
      home: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: SizedBox(
          width: 400,
          height: 200,
          child: SpringReveal(
            visible: true,
            hiddenOffset: _hidden,
            child: SizedBox(height: 40, child: Text('reveal')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(SpringReveal),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(SpringReveal),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      1,
    );
  });
}
