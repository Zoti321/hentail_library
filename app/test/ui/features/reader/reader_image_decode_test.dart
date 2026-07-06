import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_viewport_constants.dart';

void main() {
  group('reader viewport slot widths', () {
    test('continuous slot clamps to 480..1600', () {
      expect(readerContinuousSlotLogicalWidth(400), 480);
      expect(readerContinuousSlotLogicalWidth(1000), 800);
      expect(readerContinuousSlotLogicalWidth(3000), 1600);
    });

    test('dual page slot is half viewport width', () {
      expect(readerDualPageSlotLogicalWidth(1200), 600);
    });
  });

  testWidgets('resolveReaderCacheWidth uses max of width and height', (
    WidgetTester tester,
  ) async {
    late int cacheWidth;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(1000, 1400),
            devicePixelRatio: 2,
          ),
          child: Builder(
            builder: (BuildContext context) {
              cacheWidth = AppComicImage.resolveReaderCacheWidth(
                context: context,
                slotLogicalWidth: readerContinuousSlotLogicalWidth(1000),
                slotLogicalHeight: 1400,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(cacheWidth, 2800);
  });

  testWidgets('resolveReaderCacheWidth clamps to kReaderDecodeMaxWidth', (
    WidgetTester tester,
  ) async {
    late int cacheWidth;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(3000, 2400),
            devicePixelRatio: 2,
          ),
          child: Builder(
            builder: (BuildContext context) {
              cacheWidth = AppComicImage.resolveReaderCacheWidth(
                context: context,
                slotLogicalWidth: readerPagedSlotLogicalWidth(3000),
                slotLogicalHeight: 2400,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(cacheWidth, kReaderDecodeMaxWidth);
  });

  testWidgets('resolveReaderCacheWidth uses viewport height by default', (
    WidgetTester tester,
  ) async {
    late int cacheWidth;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1000, 800), devicePixelRatio: 2),
          child: Builder(
            builder: (BuildContext context) {
              cacheWidth = AppComicImage.resolveReaderCacheWidth(
                context: context,
                slotLogicalWidth: readerContinuousSlotLogicalWidth(1000),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(cacheWidth, 1600);
  });
}
