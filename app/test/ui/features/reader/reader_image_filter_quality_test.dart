import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_image_filter_quality.dart';

void main() {
  group('readerImageFilterQuality', () {
    test('uses medium while scrolling', () {
      expect(
        readerImageFilterQuality(isScrolling: true),
        FilterQuality.medium,
      );
    });

    test('uses high when idle', () {
      expect(
        readerImageFilterQuality(isScrolling: false),
        FilterQuality.high,
      );
    });
  });
}
