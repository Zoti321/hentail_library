import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/interaction/app_motion.dart';

void main() {
  group('motionDuration', () {
    test('keeps duration when motion is allowed', () {
      const Duration duration = Duration(milliseconds: 200);
      expect(motionDuration(false, duration), duration);
    });

    test('collapses duration when reduced motion is on', () {
      expect(
        motionDuration(true, const Duration(milliseconds: 200)),
        Duration.zero,
      );
    });
  });

  group('readerAutoPlayAllowed', () {
    test('allows autoplay only when enabled and motion is allowed', () {
      expect(
        readerAutoPlayAllowed(userEnabled: true, reduceMotion: false),
        isTrue,
      );
      expect(
        readerAutoPlayAllowed(userEnabled: true, reduceMotion: true),
        isFalse,
      );
      expect(
        readerAutoPlayAllowed(userEnabled: false, reduceMotion: false),
        isFalse,
      );
    });
  });
}
