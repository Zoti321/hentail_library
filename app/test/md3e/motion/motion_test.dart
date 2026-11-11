import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';

void main() {
  test('Motion exposes non-zero standard durations', () {
    expect(LabMotion.durationShort.inMilliseconds, greaterThan(0));
    expect(LabMotion.durationMedium.inMilliseconds, greaterThan(0));
    expect(LabMotion.expressiveSpring, isNotNull);
    expect(
      LabMotion.curveForStateEnter(reduceMotion: false),
      LabMotion.curveEmphasizedDecelerate,
    );
    expect(
      LabMotion.curveForStateExit(reduceMotion: false),
      LabMotion.curveEmphasizedAccelerate,
    );
  });
}
