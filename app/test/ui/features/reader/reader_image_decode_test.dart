import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_image_cache.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_viewport_constants.dart';

void main() {
  group('reader viewport slot widths', () {
    test('continuous fitWidth slot uses margin percent without clamp', () {
      expect(readerContinuousSlotLogicalWidth(1000, marginPercent: 0), 1000);
      expect(readerContinuousSlotLogicalWidth(1000, marginPercent: 20), 800);
      expect(readerContinuousSlotLogicalWidth(1000, marginPercent: 40), 600);
      expect(readerContinuousSlotLogicalWidth(400, marginPercent: 20), 320);
      expect(readerContinuousSlotLogicalWidth(3000, marginPercent: 20), 2400);
    });

    test('dual page slot is half viewport width', () {
      expect(readerDualPageSlotLogicalWidth(1200), 600);
    });
  });

  test('buildReaderImageProvider returns null for missing file path', () {
    ensureReaderImageCacheConfigured();

    final ImageProvider<Object>? provider = buildReaderImageProvider(
      filePath: r'C:\hentai_library_tests\missing_reader_page.jpg',
    );

    expect(provider, isNull);
  });

  test(
    'buildReaderImageProvider skips decode resize for existing reader pages',
    () async {
      ensureReaderImageCacheConfigured();
      final File file = File(
        '${Directory.systemTemp.path}/reader_image_decode_test.jpg',
      );
      await file.writeAsBytes(const <int>[0xFF, 0xD8, 0xFF]);
      addTearDown(() {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });

      final ImageProvider<Object>? provider = buildReaderImageProvider(
        filePath: file.path,
      );

      expect(provider, isA<ExtendedFileImageProvider>());
      expect(provider, isNot(isA<ResizeImage>()));
    },
  );
}
