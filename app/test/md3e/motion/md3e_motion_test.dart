import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';

void main() {
  test('Md3eMotion exposes non-zero standard durations', () {
    expect(Md3eMotion.durationShort.inMilliseconds, greaterThan(0));
    expect(Md3eMotion.durationMedium.inMilliseconds, greaterThan(0));
    expect(Md3eMotion.expressiveSpring, isNotNull);
  });
}
