import 'package:hentai_library/features/reader/domain/reader_page_payload.dart';
import 'package:hentai_library/features/reader/presentation/image/page_decode_size_policy.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hentai_library/shared/ui/image/image_cache_config.dart';
import 'package:hentai_library/features/reader/domain/page_prefetch_window.dart'
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

/// 丢掉 path→bytes，并 evict 命名 ImageCache 中同路径条目（失败态重载前调用）。
///
/// 调用方应 await：否则 remount 可能仍命中失败态 ImageCache 条目。
Future<void> forgetReaderCachedFile(String path) async {
  final String trimmed = path.trim();
  if (trimmed.isEmpty) {
    return;
  }
  removeReaderPathBytes(trimmed);
  ensureReaderImageCacheConfigured();
  imageCaches[kReaderImageCacheName]?.evict(
    ReaderPageDecodeImageKey(
      bytes: Uint8List(0),
      cacheWidth: null,
      cacheHeight: null,
      path: trimmed,
    ),
  );
  await ExtendedFileImageProvider(
    File(trimmed),
    imageCacheName: kReaderImageCacheName,
  ).evict();
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
  cache.maximumSizeBytes = kGlobalImageCacheMaxBytes ~/ 2;
}

void clearReaderImageCache() {
  clearMemoryImageCache(kReaderImageCacheName);
  clearReaderPathBytes();
}

/// Probes encoded image dimensions and applies [pageDecodeSizeForSource].
Future<PageDecodeSize> pageDecodeSizeForImageBytes(
  Uint8List bytes, {
  int maxEdge = kReaderPageDecodeMaxEdge,
}) async {
  if (bytes.isEmpty) {
    return (cacheWidth: null, cacheHeight: null, capped: false);
  }
  final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
    bytes,
  );
  final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(
    buffer,
  );
  try {
    return pageDecodeSizeForSource(
      sourceWidth: descriptor.width,
      sourceHeight: descriptor.height,
      maxEdge: maxEdge,
    );
  } finally {
    descriptor.dispose();
  }
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
    return ReaderPageDecodeImageProvider(
      memoryBytes: bytes,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }
  final String? resolvedPath = filePath?.trim();
  if (resolvedPath == null || resolvedPath.isEmpty) {
    return null;
  }
  return ReaderPageDecodeImageProvider(
    filePath: resolvedPath,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
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
    if (provider == null || !context.mounted) {
      return;
    }
    await precacheReaderImage(context: context, provider: provider);
  } on FileSystemException {
    // 预取窗口已滑走、磁盘缓存被驱逐。
  }
}

Future<void> precacheReaderPayload({
  required BuildContext context,
  required ReaderPagePayload page,
  int? cacheWidth,
}) async {
  if (!context.mounted) return;
  switch (page) {
    case ReaderPageFilePath(:final path):
      await precacheReaderFilePath(
        context: context,
        filePath: path,
        cacheWidth: cacheWidth,
      );
    case ReaderPageBytes(:final data):
      final provider = buildReaderImageProvider(
        memoryBytes: data,
        cacheWidth: cacheWidth,
      );
      if (provider == null) return;
      try {
        await precacheReaderImage(context: context, provider: provider);
      } on Object {
        // A failed speculative decode must not stop the remaining warm window.
      }
  }
}

/// Read session page [ImageProvider] that enforces max-edge decode safety.
///
/// When [cacheWidth]/[cacheHeight] are both null, probes source size and
/// applies [pageDecodeSizeForSource]; otherwise uses the explicit limits.
@immutable
class ReaderPageDecodeImageProvider
    extends ImageProvider<ReaderPageDecodeImageKey>
    with ExtendedImageProvider<ReaderPageDecodeImageKey> {
  const ReaderPageDecodeImageProvider({
    this.filePath,
    this.memoryBytes,
    this.cacheWidth,
    this.cacheHeight,
    this.maxEdge = kReaderPageDecodeMaxEdge,
  });

  final String? filePath;
  final Uint8List? memoryBytes;
  final int? cacheWidth;
  final int? cacheHeight;

  /// Production default is [kReaderPageDecodeMaxEdge]; tests may lower it.
  final int maxEdge;

  @override
  bool get cacheRawData => false;

  @override
  String? get imageCacheName => kReaderImageCacheName;

  @override
  Future<ReaderPageDecodeImageKey> obtainKey(
    ImageConfiguration configuration,
  ) async {
    ensureReaderImageCacheConfigured();
    final Uint8List bytes = await _resolveBytes();
    int? width = cacheWidth;
    int? height = cacheHeight;
    if (width == null && height == null) {
      final PageDecodeSize size = await pageDecodeSizeForImageBytes(
        bytes,
        maxEdge: maxEdge,
      );
      width = size.cacheWidth;
      height = size.cacheHeight;
    }
    final String? path = filePath?.trim();
    return ReaderPageDecodeImageKey(
      bytes: bytes,
      cacheWidth: width,
      cacheHeight: height,
      path: (path == null || path.isEmpty) ? null : path,
    );
  }

  @override
  ImageStreamCompleter loadImage(
    ReaderPageDecodeImageKey key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _instantiateCodec(key),
      scale: 1,
      debugLabel: key.path ?? 'reader-page-bytes',
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('Path: ${key.path ?? '(memory)'}'),
      ],
    );
  }

  Future<ui.Codec> _instantiateCodec(ReaderPageDecodeImageKey key) async {
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
      key.bytes,
    );
    final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(
      buffer,
    );
    try {
      if (key.cacheWidth != null || key.cacheHeight != null) {
        return await descriptor.instantiateCodec(
          targetWidth: key.cacheWidth,
          targetHeight: key.cacheHeight,
        );
      }
      return await descriptor.instantiateCodec();
    } finally {
      descriptor.dispose();
    }
  }

  Future<Uint8List> _resolveBytes() async {
    final Uint8List? memory = memoryBytes;
    if (memory != null && memory.isNotEmpty) {
      return memory;
    }
    final String? path = filePath?.trim();
    if (path == null || path.isEmpty) {
      throw StateError('ReaderPageDecodeImageProvider requires bytes or path');
    }
    final Uint8List? peeked = peekReaderPathBytes(path);
    if (peeked != null && peeked.isNotEmpty) {
      return peeked;
    }
    final Uint8List loaded = await File(path).readAsBytes();
    if (loaded.isEmpty) {
      throw StateError('Reader page file is empty: $path');
    }
    putReaderPathBytes(path, loaded);
    return loaded;
  }

  @override
  bool operator ==(Object other) {
    return other is ReaderPageDecodeImageProvider &&
        filePath == other.filePath &&
        identical(memoryBytes, other.memoryBytes) &&
        cacheWidth == other.cacheWidth &&
        cacheHeight == other.cacheHeight &&
        maxEdge == other.maxEdge;
  }

  @override
  int get hashCode => Object.hash(
    filePath,
    identityHashCode(memoryBytes),
    cacheWidth,
    cacheHeight,
    maxEdge,
  );
}

@immutable
class ReaderPageDecodeImageKey {
  const ReaderPageDecodeImageKey({
    required this.bytes,
    required this.cacheWidth,
    required this.cacheHeight,
    this.path,
  });

  final Uint8List bytes;
  final int? cacheWidth;
  final int? cacheHeight;
  final String? path;

  @override
  bool operator ==(Object other) {
    if (other is! ReaderPageDecodeImageKey) {
      return false;
    }
    final String? selfPath = path;
    final String? otherPath = other.path;
    // File-backed pages: path is the stable cache identity (dims follow file).
    if (selfPath != null &&
        selfPath.isNotEmpty &&
        otherPath != null &&
        otherPath == selfPath) {
      return true;
    }
    return identical(bytes, other.bytes) &&
        cacheWidth == other.cacheWidth &&
        cacheHeight == other.cacheHeight;
  }

  @override
  int get hashCode {
    final String? selfPath = path;
    if (selfPath != null && selfPath.isNotEmpty) {
      return selfPath.hashCode;
    }
    return Object.hash(identityHashCode(bytes), cacheWidth, cacheHeight);
  }
}
