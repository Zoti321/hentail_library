import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_floating_panel.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_series_nav.dart';

void main() {
  group('readerTargetBarWidth', () {
    test('uses full available width under compact breakpoint', () {
      const double viewport = AppLayoutBreakpoints.compact - 1;
      expect(readerTargetBarWidth(viewport), viewport);
      expect(
        readerTargetBarWidth(viewport, horizontalSafePadding: 40),
        viewport - 40,
      );
    });

    test('keeps floating island formula at and above compact', () {
      expect(
        readerTargetBarWidth(AppLayoutBreakpoints.compact),
        (AppLayoutBreakpoints.compact * 0.8).clamp(560, 1120),
      );
      expect(readerTargetBarWidth(800), (800 * 0.8).clamp(560, 1120));
      expect(readerTargetBarWidth(2000), 1120);
    });
  });

  group('reader popup menu chrome params', () {
    test('shares vertical margin constant for overflow and series menus', () {
      expect(kReaderPopupMenuVerticalMargin, -32);
    });

    test('clamps design width to available viewport', () {
      expect(
        readerClampedPopupMenuWidth(
          designWidth: kReaderOverflowMenuDesignWidth,
          viewportWidth: 200,
        ),
        200 - kReaderPopupMenuHorizontalInset * 2,
      );
      expect(
        readerClampedPopupMenuWidth(
          designWidth: kReaderSeriesMenuWidth,
          viewportWidth: 300,
        ),
        300 - kReaderPopupMenuHorizontalInset * 2,
      );
      expect(
        readerClampedPopupMenuWidth(
          designWidth: kReaderOverflowMenuDesignWidth,
          viewportWidth: 1200,
        ),
        kReaderOverflowMenuDesignWidth,
      );
      expect(
        readerClampedPopupMenuWidth(
          designWidth: kReaderSeriesMenuWidth,
          viewportWidth: 1200,
        ),
        kReaderSeriesMenuWidth,
      );
    });
  });

  group('reader chrome edge inset', () {
    test('keeps a small float gap beyond system safe-area', () {
      expect(kReaderChromeEdgeGap, 8);
      expect(kReaderChromeHideSlide, 16);
    });
  });

  group('reader top bar action size', () {
    test('exports unified action size of 32', () {
      expect(kReaderTopBarActionSize, 32);
    });
  });
}
