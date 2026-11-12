import 'dart:io';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

/// Builds a reader-scoped [ImageProvider] (injected from read_session).
typedef ReaderComicImageProviderBuilder = ImageProvider<Object>? Function({
  String? filePath,
  Uint8List? memoryBytes,
  int? cacheWidth,
  int? cacheHeight,
});

class AppComicImage extends StatelessWidget {
  const AppComicImage({
    super.key,
    this.filePath,
    this.memoryBytes,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.cacheWidth,
    this.cacheHeight,
    this.placeholder,
    this.loadingPlaceholder,
    this.errorPlaceholder,
    this.filterQuality = FilterQuality.medium,
    this.gaplessPlayback = false,
    this.useReaderImageCache = false,
    this.readerImageProviderBuilder,
    this.onDecodeError,
    this.onImageSize,
  });

  final String? filePath;
  final Uint8List? memoryBytes;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final int? cacheWidth;
  final int? cacheHeight;

  /// Fallback for loading when [loadingPlaceholder] is null.
  final Widget? placeholder;

  /// Shown while the image is loading. Falls back to [placeholder].
  final Widget? loadingPlaceholder;
  final Widget? errorPlaceholder;
  final FilterQuality filterQuality;

  /// 封面 Hero 等场景：provider 切换时保留上一帧，对齐 Kazumi 详情侧
  /// `fadeInDuration: Duration.zero`（避免加载占位闪一下）。
  final bool gaplessPlayback;
  final bool useReaderImageCache;
  final ReaderComicImageProviderBuilder? readerImageProviderBuilder;
  final VoidCallback? onDecodeError;

  /// Fired once per successful decode with intrinsic pixel size.
  final ValueChanged<Size>? onImageSize;

  @override
  Widget build(BuildContext context) {
    final Widget errorWidget =
        errorPlaceholder ?? placeholder ?? const SizedBox.expand();
    final Widget loadingWidget =
        loadingPlaceholder ?? placeholder ?? const SizedBox.expand();

    if (useReaderImageCache) {
      final ReaderComicImageProviderBuilder? buildProvider =
          readerImageProviderBuilder;
      final ImageProvider<Object>? provider = buildProvider == null
          ? null
          : buildProvider(
              filePath: filePath,
              memoryBytes: memoryBytes,
              cacheWidth: cacheWidth,
              cacheHeight: cacheHeight,
            );
      if (provider == null) {
        return errorWidget;
      }
      return ExtendedImage(
        image: provider,
        fit: fit,
        alignment: alignment,
        filterQuality: filterQuality,
        gaplessPlayback: gaplessPlayback,
        loadStateChanged: _loadStateChanged(errorWidget, loadingWidget),
      );
    }

    final Uint8List? bytes = memoryBytes;

    if (bytes != null && bytes.isNotEmpty) {
      return ExtendedImage.memory(
        bytes,
        fit: fit,
        alignment: alignment,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        filterQuality: filterQuality,
        gaplessPlayback: gaplessPlayback,
        loadStateChanged: _loadStateChanged(errorWidget, loadingWidget),
      );
    }

    final String? resolvedPath = filePath;
    if (resolvedPath == null || resolvedPath.trim().isEmpty) {
      return errorWidget;
    }
    return ExtendedImage.file(
      File(resolvedPath),
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      filterQuality: filterQuality,
      gaplessPlayback: gaplessPlayback,
      loadStateChanged: _loadStateChanged(errorWidget, loadingWidget),
    );
  }

  /// [gaplessPlayback] 时不替换 loading 占位，避免 Hero 落地瞬间闪一下。
  Widget? Function(ExtendedImageState state) _loadStateChanged(
    Widget fallback,
    Widget loading,
  ) {
    return (ExtendedImageState state) {
      if (state.extendedImageLoadState == LoadState.failed) {
        onDecodeError?.call();
        return fallback;
      }
      if (state.extendedImageLoadState == LoadState.loading) {
        if (gaplessPlayback) {
          return null;
        }
        return loading;
      }
      if (state.extendedImageLoadState == LoadState.completed) {
        final ValueChanged<Size>? reportSize = onImageSize;
        final ImageInfo? info = state.extendedImageInfo;
        if (reportSize != null && info != null) {
          final int width = info.image.width;
          final int height = info.image.height;
          if (width > 0 && height > 0) {
            // Defer so we never setState during build of ExtendedImage.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              reportSize(Size(width.toDouble(), height.toDouble()));
            });
          }
        }
      }
      return null;
    };
  }
}
