import 'dart:io';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/widgets.dart';
import 'package:hentai_library/core/image/image_cache_config.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_prefetch_logic.dart';

/// 阅读器专用内存图缓存名；与 [AppComicImage] 显示及 [precacheImage] 预热共用。
const String kReaderImageCacheName = 'reader';

void ensureReaderImageCacheConfigured() {
  final ImageCache cache = imageCaches.putIfAbsent(
    kReaderImageCacheName,
    ImageCache.new,
  );
  cache.maximumSize = kReaderImageCacheMaxEntries;
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
      ExtendedMemoryImageProvider(bytes, imageCacheName: kReaderImageCacheName),
    );
  }
  final String? resolvedPath = filePath?.trim();
  if (resolvedPath == null || resolvedPath.isEmpty) {
    return null;
  }
  // 不在此处 existsSync：缺失文件由 ImageProvider 加载失败路径处理，避免 build 同步 IO。
  // 预取 / 展示侧在调用前用 [isUsableReaderCacheFile] 过滤空文件与已驱逐路径。
  return ResizeImage.resizeIfNeeded(
    cacheWidth,
    cacheHeight,
    ExtendedFileImageProvider(
      File(resolvedPath),
      imageCacheName: kReaderImageCacheName,
    ),
  );
}

/// 磁盘页缓存是否可交给 [ExtendedFileImageProvider]（存在且非空）。
bool isUsableReaderCacheFile(String path) {
  final String trimmed = path.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  final File file = File(trimmed);
  try {
    return file.existsSync() && file.lengthSync() > 0;
  } on FileSystemException {
    return false;
  }
}

Future<void> precacheReaderImage({
  required BuildContext context,
  required ImageProvider<Object> provider,
}) {
  return precacheImage(provider, context);
}

/// 磁盘页预热：读入内存再 precache，避免 [ExtendedFileImageProvider] 在
/// Rust `evict_outside_pages` 与异步解码之间的竞态下打 PathNotFound 日志。
Future<void> precacheReaderFilePath({
  required BuildContext context,
  required String filePath,
  int? cacheWidth,
  int? cacheHeight,
}) async {
  final String trimmed = filePath.trim();
  if (!isUsableReaderCacheFile(trimmed)) {
    return;
  }
  try {
    final Uint8List bytes = await File(trimmed).readAsBytes();
    if (bytes.isEmpty) {
      return;
    }
    final ImageProvider<Object>? provider = buildReaderImageProvider(
      memoryBytes: bytes,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
    if (provider == null) {
      return;
    }
    await precacheReaderImage(context: context, provider: provider);
  } on FileSystemException {
    // 预取窗口已滑走、磁盘缓存被驱逐。
  }
}
