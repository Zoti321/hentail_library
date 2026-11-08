import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/read_session/domain/auto_play_interval.dart';

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

  group('readerAutoPlaySliderWavelength', () {
    test('maps default interval to M3E token wavelength', () {
      expect(
        readerAutoPlaySliderWavelength(kReaderAutoPlayIntervalDefault),
        40,
      );
    });

    test('grows with interval and clamps extremes', () {
      expect(readerAutoPlaySliderWavelength(1), 16);
      expect(readerAutoPlaySliderWavelength(2), 16);
      expect(readerAutoPlaySliderWavelength(3), 24);
      expect(readerAutoPlaySliderWavelength(60), 96);
      expect(readerAutoPlaySliderWavelength(999), 96);
    });
  });
}
