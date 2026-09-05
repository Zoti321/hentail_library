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
    expect(cache!.maximumSize, kReaderImageCacheMaxEntries);
    expect(cache.maximumSizeBytes, kReaderImageCacheMaxBytes);
  });

  test('buildReaderImageProvider wraps file path with named cache', () {
    ensureReaderImageCacheConfigured();

    // Skip existsSync gate by using memory bytes for ResizeImage shape checks.
    final ImageProvider<Object>? provider = buildReaderImageProvider(
      memoryBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
      cacheWidth: 800,
    );

    expect(provider, isA<ResizeImage>());
    final ResizeImage resize = provider! as ResizeImage;
    expect(resize.width, 800);
    expect(resize.imageProvider, isA<ExtendedMemoryImageProvider>());
  });

  test('buildReaderImageProvider without cacheWidth uses native decode', () {
    ensureReaderImageCacheConfigured();

    final ImageProvider<Object>? provider = buildReaderImageProvider(
      memoryBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
    );

    expect(provider, isA<ExtendedMemoryImageProvider>());
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

  test(
    'prefetch and display share ResizeImage cacheWidth for the same slot',
    () {
      ensureReaderImageCacheConfigured();
      const int cacheWidth = 720;
      final Uint8List bytes = Uint8List.fromList(<int>[9, 9, 9]);

      final ImageProvider<Object>? display = buildReaderImageProvider(
        memoryBytes: bytes,
        cacheWidth: cacheWidth,
      );
      final ImageProvider<Object>? prefetch = buildReaderImageProvider(
        memoryBytes: bytes,
        cacheWidth: cacheWidth,
      );

      expect(display, isA<ResizeImage>());
      expect(prefetch, isA<ResizeImage>());
      final ResizeImage displayResize = display! as ResizeImage;
      final ResizeImage prefetchResize = prefetch! as ResizeImage;
      expect(displayResize.width, cacheWidth);
      expect(prefetchResize.width, cacheWidth);
      expect(displayResize, prefetchResize);
    },
  );

  test('clearReaderImageCache removes named cache', () {
    ensureReaderImageCacheConfigured();
    expect(getMemoryImageCache(kReaderImageCacheName), isNotNull);

    clearReaderImageCache();

    expect(getMemoryImageCache(kReaderImageCacheName), isNull);
  });
}
