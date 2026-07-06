import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/image/image_quality_policy.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_image_cache.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_logic.dart';

void main() {
  tearDown(clearReaderImageCache);

  test('ensureReaderImageCacheConfigured sizes cache for prefetch window', () {
    ImageQualityPolicy.current = const ImageQualityPolicy(
      tier: ImageQualityTier.medium,
      decodeScale: 1.0,
      coverDecodeMaxWidth: 1024,
      readerDecodeMaxWidth: 2560,
      readerPrecacheNeighborCount: 2,
      imageCacheMaxEntries: 600,
      imageCacheMaxBytes: 256 * 1024 * 1024,
    );

    ensureReaderImageCacheConfigured();

    final ImageCache? cache = getMemoryImageCache(kReaderImageCacheName);
    expect(cache, isNotNull);
    expect(cache!.maximumSize, kReaderPrefetchNeighborCount * 2 + 3);
    expect(cache.maximumSizeBytes, 128 * 1024 * 1024);
  });

  test('buildReaderImageProvider wraps file path with named cache', () {
    ensureReaderImageCacheConfigured();

    final ImageProvider<Object>? provider = buildReaderImageProvider(
      filePath: r'C:\tmp\page.jpg',
      cacheWidth: 800,
    );

    expect(provider, isA<ExtendedResizeImage>());
    final ExtendedResizeImage resize = provider! as ExtendedResizeImage;
    expect(resize.width, 800);
    expect(resize.imageCacheName, kReaderImageCacheName);
    expect(resize.imageProvider, isA<ExtendedFileImageProvider>());
  });

  test('buildReaderImageProvider wraps memory bytes with named cache', () {
    ensureReaderImageCacheConfigured();

    final ImageProvider<Object>? provider = buildReaderImageProvider(
      memoryBytes: Uint8List.fromList(<int>[1, 2, 3]),
      cacheWidth: 640,
    );

    expect(provider, isA<ExtendedResizeImage>());
    final ExtendedResizeImage resize = provider! as ExtendedResizeImage;
    expect(resize.imageProvider, isA<ExtendedMemoryImageProvider>());
    expect(resize.imageCacheName, kReaderImageCacheName);
  });

  test('clearReaderImageCache removes named cache', () {
    ensureReaderImageCacheConfigured();
    expect(getMemoryImageCache(kReaderImageCacheName), isNotNull);

    clearReaderImageCache();

    expect(getMemoryImageCache(kReaderImageCacheName), isNull);
  });
}
