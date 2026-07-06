import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/image/image_quality_policy.dart';
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

  testWidgets('resolveReaderCacheWidth uses reader decode max width', (
    WidgetTester tester,
  ) async {
    ImageQualityPolicy.current = const ImageQualityPolicy(
      tier: ImageQualityTier.medium,
      decodeScale: 1.0,
      coverDecodeMaxWidth: 1024,
      readerDecodeMaxWidth: 2000,
      readerPrecacheNeighborCount: 2,
      imageCacheMaxEntries: 600,
      imageCacheMaxBytes: 256 * 1024 * 1024,
    );
    addTearDown(() {
      ImageQualityPolicy.current = configureImageQualityPolicy();
    });

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
