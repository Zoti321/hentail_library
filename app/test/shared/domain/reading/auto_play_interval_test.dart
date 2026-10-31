import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/domain/reading/auto_play_interval.dart';

void main() {
  group('clampReaderAutoPlayInterval', () {
    test('keeps in-range values unchanged', () {
      expect(clampReaderAutoPlayInterval(5), 5);
      expect(clampReaderAutoPlayInterval(kReaderAutoPlayIntervalMin), 1);
      expect(clampReaderAutoPlayInterval(kReaderAutoPlayIntervalMax), 60);
    });

    test('clamps values below min and above max', () {
      expect(clampReaderAutoPlayInterval(0), kReaderAutoPlayIntervalMin);
      expect(clampReaderAutoPlayInterval(-3), kReaderAutoPlayIntervalMin);
      expect(clampReaderAutoPlayInterval(61), kReaderAutoPlayIntervalMax);
    });
  });
}
