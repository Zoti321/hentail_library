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
    this.useReaderImageCache = false,
    this.readerImageProviderBuilder,
    this.onDecodeError,
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
  final bool useReaderImageCache;
  final ReaderComicImageProviderBuilder? readerImageProviderBuilder;
  final VoidCallback? onDecodeError;

  @override
  Widget build(BuildContext context) {
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
        return _buildErrorPlaceholder();
      }
      return _buildExtendedImage(provider);
    }

    final Uint8List? bytes = memoryBytes;

    if (bytes != null && bytes.isNotEmpty) {
      final Widget fallback = _buildErrorPlaceholder();
      return ExtendedImage.memory(
        bytes,
        fit: fit,
        alignment: alignment,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        filterQuality: filterQuality,
        loadStateChanged: (ExtendedImageState state) {
          if (state.extendedImageLoadState == LoadState.failed) {
            onDecodeError?.call();
            return fallback;
          }
          if (state.extendedImageLoadState == LoadState.loading) {
            return _buildLoadingPlaceholder();
          }
          return null;
        },
      );
    }

    final String? resolvedPath = filePath;
    if (resolvedPath == null || resolvedPath.trim().isEmpty) {
      return _buildErrorPlaceholder();
    }
    final Widget fallback = _buildErrorPlaceholder();
    return ExtendedImage.file(
      File(resolvedPath),
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      filterQuality: filterQuality,
      loadStateChanged: (ExtendedImageState state) {
        if (state.extendedImageLoadState == LoadState.failed) {
          onDecodeError?.call();
          return fallback;
        }
        if (state.extendedImageLoadState == LoadState.loading) {
          return _buildLoadingPlaceholder();
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
      alignment: alignment,
      filterQuality: filterQuality,
      loadStateChanged: (ExtendedImageState state) {
        if (state.extendedImageLoadState == LoadState.failed) {
          onDecodeError?.call();
          return fallback;
        }
        if (state.extendedImageLoadState == LoadState.loading) {
          return _buildLoadingPlaceholder();
        }
        return null;
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return loadingPlaceholder ?? placeholder ?? const SizedBox.expand();
  }

  Widget _buildErrorPlaceholder() {
    return errorPlaceholder ?? placeholder ?? const SizedBox.expand();
  }
}
