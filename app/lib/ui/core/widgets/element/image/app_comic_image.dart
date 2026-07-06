import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_image_cache.dart';

/// 阅读器页图解码宽度上限（物理像素）。
const int kReaderDecodeMaxWidth = 3840;

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

  /// 阅读器页图解码宽度：按槽位逻辑尺寸与 [kReaderDecodeMaxWidth] 约束。
  ///
  /// [BoxFit.contain] 下显示边长取决于宽、高中较大的一侧，故取
  /// `max(slotLogicalWidth, slotLogicalHeight)` 估算解码像素预算。
  static int resolveReaderCacheWidth({
    required BuildContext context,
    required double slotLogicalWidth,
    double? slotLogicalHeight,
    int minWidth = 64,
  }) {
    final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final double height =
        slotLogicalHeight ?? MediaQuery.sizeOf(context).height;
    final double logicalBase = math.max(slotLogicalWidth, height);
    final int rawWidth = (logicalBase * devicePixelRatio).round();
    return rawWidth.clamp(minWidth, kReaderDecodeMaxWidth);
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
