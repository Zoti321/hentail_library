import 'dart:io';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/core/image/image_quality_policy.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_image_cache.dart';

class AppComicImage extends StatelessWidget {
  const AppComicImage({
    super.key,
    this.filePath,
    this.memoryBytes,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
    this.placeholder,
    this.errorPlaceholder,
    this.filterQuality = FilterQuality.medium,
    this.useReaderImageCache = false,
  });

  final String? filePath;
  final Uint8List? memoryBytes;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;
  final Widget? placeholder;
  final Widget? errorPlaceholder;
  final FilterQuality filterQuality;
  final bool useReaderImageCache;

  static int resolveCacheWidth({
    required BuildContext context,
    required double logicalWidth,
    int minWidth = 64,
    int? maxWidth,
  }) {
    final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final ImageQualityPolicy policy = ImageQualityPolicy.current;
    final int effectiveMaxWidth = maxWidth ?? policy.coverDecodeMaxWidth;
    final int rawWidth = (logicalWidth * devicePixelRatio * policy.decodeScale)
        .round();
    return rawWidth.clamp(minWidth, effectiveMaxWidth);
  }

  /// 阅读器页图解码宽度：按槽位逻辑宽与 [ImageQualityPolicy.readerDecodeMaxWidth] 档位约束。
  static int resolveReaderCacheWidth({
    required BuildContext context,
    required double slotLogicalWidth,
    int minWidth = 64,
  }) {
    return resolveCacheWidth(
      context: context,
      logicalWidth: slotLogicalWidth,
      minWidth: minWidth,
      maxWidth: ImageQualityPolicy.current.readerDecodeMaxWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (useReaderImageCache) {
      final ImageProvider<Object>? provider = buildReaderImageProvider(
        filePath: filePath,
        memoryBytes: memoryBytes,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
      );
      if (provider == null) {
        return _buildPlaceholder();
      }
      return _buildExtendedImage(provider);
    }

    final Uint8List? bytes = memoryBytes;

    if (bytes != null && bytes.isNotEmpty) {
      final Widget fallback = _buildErrorPlaceholder();
      return ExtendedImage.memory(
        bytes,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        filterQuality: filterQuality,
        loadStateChanged: (ExtendedImageState state) {
          if (state.extendedImageLoadState == LoadState.failed) {
            return fallback;
          }
          if (state.extendedImageLoadState == LoadState.loading) {
            return _buildPlaceholder();
          }
          return null;
        },
      );
    }

    final String? resolvedPath = filePath;
    if (resolvedPath == null || resolvedPath.trim().isEmpty) {
      return _buildPlaceholder();
    }
    final Widget fallback = _buildErrorPlaceholder();
    return ExtendedImage.file(
      File(resolvedPath),
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      filterQuality: filterQuality,
      loadStateChanged: (ExtendedImageState state) {
        if (state.extendedImageLoadState == LoadState.failed) {
          return fallback;
        }
        if (state.extendedImageLoadState == LoadState.loading) {
          return _buildPlaceholder();
        }
        return null;
      },
    );
  }

  Widget _buildExtendedImage(ImageProvider<Object> provider) {
    final Widget fallback = _buildErrorPlaceholder();
    return ExtendedImage(
      image: provider,
      fit: fit,
      filterQuality: filterQuality,
      loadStateChanged: (ExtendedImageState state) {
        if (state.extendedImageLoadState == LoadState.failed) {
          return fallback;
        }
        if (state.extendedImageLoadState == LoadState.loading) {
          return _buildPlaceholder();
        }
        return null;
      },
    );
  }

  Widget _buildPlaceholder() {
    return placeholder ?? const SizedBox.expand();
  }

  Widget _buildErrorPlaceholder() {
    return errorPlaceholder ?? _buildPlaceholder();
  }
}
