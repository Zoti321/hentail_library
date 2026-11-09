import 'dart:io';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/widgets.dart';
import 'package:hentai_library/core/image/image_cache_config.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_prefetch_logic.dart'
    show kReaderImageCacheMaxEntries;

/// 阅读器专用内存图缓存名；与 [AppComicImage] 显示及 [precacheImage] 预热共用。
const String kReaderImageCacheName = 'reader';

/// 短生命周期：预热读入的磁盘页字节，供显示侧复用同一 [Uint8List] 对象，
/// 使 Memory provider 与 [precacheImage] 命中同一 [ImageCache] 钥匙。
final Map<String, Uint8List> _readerPathBytes = <String, Uint8List>{};

void putReaderPathBytes(String path, Uint8List bytes) {
  final String trimmed = path.trim();
  if (trimmed.isEmpty || bytes.isEmpty) {
    return;
  }
  _readerPathBytes[trimmed] = bytes;
}

Uint8List? peekReaderPathBytes(String path) {
  final String trimmed = path.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return _readerPathBytes[trimmed];
}

void removeReaderPathBytes(String path) {
  final String trimmed = path.trim();
  if (trimmed.isEmpty) {
    return;
  }
  _readerPathBytes.remove(trimmed);
}

void clearReaderPathBytes() {
  _readerPathBytes.clear();
}

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
  clearReaderPathBytes();
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
  // Prefer precache-owned bytes so display shares the same ImageCache key.
  final Uint8List? pathBytes = peekReaderPathBytes(resolvedPath);
  if (pathBytes != null && pathBytes.isNotEmpty) {
    return ResizeImage.resizeIfNeeded(
      cacheWidth,
      cacheHeight,
      ExtendedMemoryImageProvider(
        pathBytes,
        imageCacheName: kReaderImageCacheName,
      ),
    );
  }
  // 不在此处 existsSync：缺失文件由 ImageProvider 加载失败路径处理，避免 build 同步 IO。
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

/// 磁盘页预热：读入内存、登记 path→bytes，再 precache，使显示侧命中同一 provider。
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
    putReaderPathBytes(trimmed, bytes);
    final ImageProvider<Object>? provider = buildReaderImageProvider(
      filePath: trimmed,
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
