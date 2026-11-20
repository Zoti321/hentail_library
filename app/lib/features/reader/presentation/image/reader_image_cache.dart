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
/// 避免 precache 后再读盘（与 [ImageCache] 中的解码位图正交）。
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
    ReaderPageDecodeImageKey(path: trimmed, maxEdge: kReaderPageDecodeMaxEdge),
  );
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

ImageProvider<Object>? buildReaderImageProvider({
  String? filePath,
  Uint8List? memoryBytes,
}) {
  ensureReaderImageCacheConfigured();
  final Uint8List? bytes = memoryBytes;
  if (bytes != null && bytes.isNotEmpty) {
    return ReaderPageDecodeImageProvider(memoryBytes: bytes);
  }
  final String? resolvedPath = filePath?.trim();
  if (resolvedPath == null || resolvedPath.isEmpty) {
    return null;
  }
  return ReaderPageDecodeImageProvider(filePath: resolvedPath);
}

/// 磁盘页缓存是否可交给文件路径解码（存在且非空）。
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

/// 磁盘页预热：读入内存、登记 path→bytes，再 precache，使显示侧免再读盘。
Future<void> precacheReaderFilePath({
  required BuildContext context,
  required String filePath,
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
}) async {
  if (!context.mounted) return;
  switch (page) {
    case ReaderPageFilePath(:final path):
      await precacheReaderFilePath(context: context, filePath: path);
    case ReaderPageBytes(:final data):
      final provider = buildReaderImageProvider(memoryBytes: data);
      if (provider == null) return;
      try {
        await precacheReaderImage(context: context, provider: provider);
      } on Object {
        // A failed speculative decode must not stop the remaining warm window.
      }
  }
}

/// Read session page [ImageProvider] with max-edge decode safety.
///
/// [obtainKey] is cheap (path or bytes identity + [maxEdge] only). On cache
/// miss, [loadImage] reads bytes once and decodes in a single pass via
/// [ImageDecoderCallback] + [getTargetSize] applying [pageDecodeSizeForSource].
@immutable
class ReaderPageDecodeImageProvider
    extends ImageProvider<ReaderPageDecodeImageKey>
    with ExtendedImageProvider<ReaderPageDecodeImageKey> {
  const ReaderPageDecodeImageProvider({
    this.filePath,
    this.memoryBytes,
    this.maxEdge = kReaderPageDecodeMaxEdge,
  });

  final String? filePath;
  final Uint8List? memoryBytes;

  /// Production default is [kReaderPageDecodeMaxEdge]; tests may lower it.
  final int maxEdge;

  @override
  bool get cacheRawData => false;

  @override
  String? get imageCacheName => kReaderImageCacheName;

  @override
  Future<ReaderPageDecodeImageKey> obtainKey(
    ImageConfiguration configuration,
  ) {
    ensureReaderImageCacheConfigured();
    final String? path = filePath?.trim();
    if (path != null && path.isNotEmpty) {
      return SynchronousFuture<ReaderPageDecodeImageKey>(
        ReaderPageDecodeImageKey(path: path, maxEdge: maxEdge),
      );
    }
    final Uint8List? bytes = memoryBytes;
    if (bytes == null || bytes.isEmpty) {
      return Future<ReaderPageDecodeImageKey>.error(
        StateError('ReaderPageDecodeImageProvider requires bytes or path'),
      );
    }
    return SynchronousFuture<ReaderPageDecodeImageKey>(
      ReaderPageDecodeImageKey(memoryBytes: bytes, maxEdge: maxEdge),
    );
  }

  @override
  ImageStreamCompleter loadImage(
    ReaderPageDecodeImageKey key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _instantiateCodec(key, decode),
      scale: 1,
      debugLabel: key.path ?? 'reader-page-bytes',
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('Path: ${key.path ?? '(memory)'}'),
      ],
    );
  }

  /// Single decode pass: [decode]'s [getTargetSize] sees intrinsic size, then
  /// [pageDecodeSizeForSource] chooses full resolution or max-edge targets.
  Future<ui.Codec> _instantiateCodec(
    ReaderPageDecodeImageKey key,
    ImageDecoderCallback decode,
  ) async {
    final Uint8List bytes = await _resolveBytes(key);
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
      bytes,
    );
    return decode(
      buffer,
      getTargetSize: (int intrinsicWidth, int intrinsicHeight) {
        final PageDecodeSize size = pageDecodeSizeForSource(
          sourceWidth: intrinsicWidth,
          sourceHeight: intrinsicHeight,
          maxEdge: key.maxEdge,
        );
        if (!size.capped) {
          return ui.TargetImageSize(
            width: intrinsicWidth,
            height: intrinsicHeight,
          );
        }
        return ui.TargetImageSize(
          width: size.cacheWidth,
          height: size.cacheHeight,
        );
      },
    );
  }

  Future<Uint8List> _resolveBytes(ReaderPageDecodeImageKey key) async {
    final Uint8List? memory = key.memoryBytes ?? memoryBytes;
    if (memory != null && memory.isNotEmpty) {
      return memory;
    }
    final String? path = key.path ?? filePath?.trim();
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
        maxEdge == other.maxEdge;
  }

  @override
  int get hashCode =>
      Object.hash(filePath, identityHashCode(memoryBytes), maxEdge);
}

/// Cheap cache identity for Read session page images.
@immutable
class ReaderPageDecodeImageKey {
  const ReaderPageDecodeImageKey({
    this.path,
    this.memoryBytes,
    required this.maxEdge,
  });

  final String? path;
  final Uint8List? memoryBytes;
  final int maxEdge;

  @override
  bool operator ==(Object other) {
    if (other is! ReaderPageDecodeImageKey || maxEdge != other.maxEdge) {
      return false;
    }
    final String? selfPath = path;
    final String? otherPath = other.path;
    if (selfPath != null &&
        selfPath.isNotEmpty &&
        otherPath != null &&
        otherPath == selfPath) {
      return true;
    }
    return identical(memoryBytes, other.memoryBytes);
  }

  @override
  int get hashCode {
    final String? selfPath = path;
    if (selfPath != null && selfPath.isNotEmpty) {
      return Object.hash(selfPath, maxEdge);
    }
    return Object.hash(identityHashCode(memoryBytes), maxEdge);
  }
}
