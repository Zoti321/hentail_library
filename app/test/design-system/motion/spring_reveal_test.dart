import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:motor/motor.dart';

import '../../support/pump_app.dart';

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

  await pumpApp(tester, home: build(visible: false));
  await pumpApp(tester, home: build(visible: true));

  final List<double> samples = <double>[];
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    samples.add(_dx(tester));
  }
  await tester.pumpAndSettle();
  return samples;
}

void main() {
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
    await pumpApp(
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

    await pumpApp(
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
    await pumpApp(
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
