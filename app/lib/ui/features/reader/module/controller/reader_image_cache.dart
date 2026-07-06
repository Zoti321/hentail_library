import 'dart:io';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/widgets.dart';
import 'package:hentai_library/core/image/image_cache_config.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_logic.dart';

/// 阅读器专用内存图缓存名；与 [AppComicImage] 显示及 [precacheImage] 预热共用。
const String kReaderImageCacheName = 'reader';

void ensureReaderImageCacheConfigured() {
  final ImageCache cache = imageCaches.putIfAbsent(
    kReaderImageCacheName,
    ImageCache.new,
  );
  cache.maximumSize = kReaderPrefetchNeighborCount * 2 + 3;
  cache.maximumSizeBytes = kReaderImageCacheMaxBytes;
}

void clearReaderImageCache() {
  clearMemoryImageCache(kReaderImageCacheName);
}

ImageProvider<Object>? buildReaderImageProvider({
  String? filePath,
  Uint8List? memoryBytes,
  int? cacheWidth,
  int? cacheHeight,
}) {
  ensureReaderImageCacheConfigured();
  final Uint8List? bytes = memoryBytes;
  if (bytes != null && bytes.isNotEmpty) {
    return ResizeImage.resizeIfNeeded(
      cacheWidth,
      cacheHeight,
      ExtendedMemoryImageProvider(
        bytes,
        imageCacheName: kReaderImageCacheName,
      ),
    );
  }
  final String? resolvedPath = filePath?.trim();
  if (resolvedPath == null || resolvedPath.isEmpty) {
    return null;
  }
  return ResizeImage.resizeIfNeeded(
    cacheWidth,
    cacheHeight,
    ExtendedFileImageProvider(
      File(resolvedPath),
      imageCacheName: kReaderImageCacheName,
    ),
  );
}

Future<void> precacheReaderImage({
  required BuildContext context,
  required ImageProvider<Object> provider,
}) {
  return precacheImage(provider, context);
}
