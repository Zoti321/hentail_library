import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/image/image_decode_cache_size.dart';

void main() {
  test('decodeCacheSizeForLogicalSize scales by device pixel ratio', () {
    final ImageDecodeCacheSize size = decodeCacheSizeForLogicalSize(
      logicalWidth: 200,
      logicalHeight: 300,
      devicePixelRatio: 2,
    );

    expect(size.cacheWidth, 400);
    expect(size.cacheHeight, 600);
  });

  test('decodeCacheSizeForLogicalSize returns null for invalid input', () {
    expect(
      decodeCacheSizeForLogicalSize(
        logicalWidth: 0,
        logicalHeight: 100,
        devicePixelRatio: 2,
      ).cacheWidth,
      isNull,
    );
  });
}
