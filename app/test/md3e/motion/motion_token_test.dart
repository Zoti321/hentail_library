import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:motor/motor.dart';

void main() {
  test('spatial spring matches M3E expressive spatial default token', () {
    // 期望值取自 M3E 包 token，不取自 Motion 实现。
    expect(
      LabMotion.readerChromeReveal.stiffness,
      M3EMotion.expressiveSpatialDefault.stiffness,
    );
    expect(
      LabMotion.readerChromeReveal.damping,
      M3EMotion.expressiveSpatialDefault.damping,
    );
  });

  test('effects spring matches M3E expressive effects default token', () {
    expect(
      LabMotion.effectsSpring.stiffness,
      M3EMotion.effectsDefault.stiffness,
    );
    expect(LabMotion.effectsSpring.damping, M3EMotion.effectsDefault.damping);
  });

  test('lab simulated save duration is 280ms and named', () {
    expect(
      LabMotion.labSimulatedSaveDuration,
      const Duration(milliseconds: 280),
    );
  });

  testWidgets('motionDurationOf returns zero when reduce motion is on', (
    WidgetTester tester,
  ) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (BuildContext context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(
      LabMotion.motionDurationOf(captured, const Duration(milliseconds: 300)),
      Duration.zero,
    );
  });

  testWidgets('motionDurationOf keeps duration when reduce motion is off', (
    WidgetTester tester,
  ) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (BuildContext context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(
      LabMotion.motionDurationOf(captured, const Duration(milliseconds: 300)),
      const Duration(milliseconds: 300),
    );
  });

  test('effects spring is a MaterialSpringMotion instance', () {
    expect(LabMotion.effectsSpring, isA<SpringMotion>());
  });
}
