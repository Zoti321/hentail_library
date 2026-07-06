import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/image/image_cache_config.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_image_cache.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_logic.dart';

void main() {
  tearDown(clearReaderImageCache);

  test('ensureReaderImageCacheConfigured sizes cache for prefetch window', () {
    ensureReaderImageCacheConfigured();

    final ImageCache? cache = getMemoryImageCache(kReaderImageCacheName);
    expect(cache, isNotNull);
    expect(cache!.maximumSize, kReaderPrefetchNeighborCount * 2 + 3);
    expect(cache.maximumSizeBytes, kReaderImageCacheMaxBytes);
  });

  test('buildReaderImageProvider wraps file path with named cache', () {
    ensureReaderImageCacheConfigured();

    final ImageProvider<Object>? provider = buildReaderImageProvider(
      filePath: r'C:\tmp\page.jpg',
      cacheWidth: 800,
    );

    expect(provider, isA<ResizeImage>());
    final ResizeImage resize = provider! as ResizeImage;
    expect(resize.width, 800);
    expect(resize.imageProvider, isA<ExtendedFileImageProvider>());
  });

  test('buildReaderImageProvider without cacheWidth uses native decode', () {
    ensureReaderImageCacheConfigured();

    final ImageProvider<Object>? provider = buildReaderImageProvider(
      filePath: r'C:\tmp\page.jpg',
    );

    expect(provider, isA<ExtendedFileImageProvider>());
    expect(provider, isNot(isA<ResizeImage>()));
  });

  test('buildReaderImageProvider wraps memory bytes with named cache', () {
    ensureReaderImageCacheConfigured();

    final ImageProvider<Object>? provider = buildReaderImageProvider(
      memoryBytes: Uint8List.fromList(<int>[1, 2, 3]),
      cacheWidth: 640,
    );

    expect(provider, isA<ResizeImage>());
    final ResizeImage resize = provider! as ResizeImage;
    expect(resize.imageProvider, isA<ExtendedMemoryImageProvider>());
  });

  test('clearReaderImageCache removes named cache', () {
    ensureReaderImageCacheConfigured();
    expect(getMemoryImageCache(kReaderImageCacheName), isNotNull);

    clearReaderImageCache();

    expect(getMemoryImageCache(kReaderImageCacheName), isNull);
  });
}
