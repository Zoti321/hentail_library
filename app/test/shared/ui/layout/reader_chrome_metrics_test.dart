import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/reader_chrome_metrics.dart';

void main() {
  group('ReaderChromeMetrics.denseChrome', () {
    test('compact and medium stay touch-sized', () {
      expect(
        ReaderChromeMetrics.denseChrome(Breakpoints.previewWidthCompact),
        isFalse,
      );
      expect(
        ReaderChromeMetrics.denseChrome(Breakpoints.previewWidthMedium),
        isFalse,
      );
      expect(ReaderChromeMetrics.actionIconSizeOf(390), 24);
      expect(ReaderChromeMetrics.bottomBarMinHeightOf(390), 68);
      expect(ReaderChromeMetrics.progressSliderTrackThicknessOf(390), isNull);
    });

    test('expanded+ uses denser chrome', () {
      expect(
        ReaderChromeMetrics.denseChrome(Breakpoints.previewWidthExpanded),
        isTrue,
      );
      expect(ReaderChromeMetrics.actionIconSizeOf(1024), 20);
      expect(ReaderChromeMetrics.bottomBarMinHeightOf(1024), 54);
      expect(ReaderChromeMetrics.bottomBarTopPaddingOf(1024), 4);
      expect(ReaderChromeMetrics.edgeGapOf(1024), 2);
      expect(ReaderChromeMetrics.progressControlsGapOf(1024), 0);
      expect(ReaderChromeMetrics.progressSliderTrackThicknessOf(1024), 10);
      expect(ReaderChromeMetrics.progressSliderThumbLengthOf(1024), 32);
    });
  });
}
