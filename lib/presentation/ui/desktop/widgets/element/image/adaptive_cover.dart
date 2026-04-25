import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/dto/comic_cover_display_data.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/element/image/app_comic_image.dart';

/// Generic adaptive cover widget.
///
/// - Resolves real image aspect ratio from memory/file.
/// - Keeps ratio and tries to fill parent constraints.
/// - Delegates decoding/rendering to [AppComicImage].
class AdaptiveCover extends StatelessWidget {
  const AdaptiveCover({
    super.key,
    required this.coverDisplay,
    this.fallbackAspectRatio = 2 / 3,
    this.fit = BoxFit.cover,
    this.filterQuality = FilterQuality.medium,
    this.placeholder = const SizedBox.expand(),
    this.errorPlaceholder,
    this.backgroundColor,
    this.maxCacheWidth,
    this.clipBorderRadius,
  });

  final ComicCoverDisplayData? coverDisplay;
  final double fallbackAspectRatio;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final Widget placeholder;
  final Widget? errorPlaceholder;
  final Color? backgroundColor;
  final int? maxCacheWidth;
  final BorderRadius? clipBorderRadius;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: resolveCoverAspectRatio(
        coverDisplay: coverDisplay,
        fallbackAspectRatio: fallbackAspectRatio,
      ),
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
        final double resolvedAspectRatio = snapshot.data ?? fallbackAspectRatio;
        Widget image = AspectRatio(
          aspectRatio: resolvedAspectRatio,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int coverCacheWidth = AppComicImage.resolveCacheWidth(
                context: context,
                logicalWidth: constraints.maxWidth,
                maxWidth: maxCacheWidth,
              );
              return SizedBox.expand(
                child: ColoredBox(
                  color: backgroundColor ?? Colors.transparent,
                  child: AppComicImage(
                    memoryBytes: coverDisplay?.memoryBytes,
                    filePath: coverDisplay?.filePath,
                    fit: fit,
                    cacheWidth: coverCacheWidth,
                    filterQuality: filterQuality,
                    placeholder: placeholder,
                    errorPlaceholder: errorPlaceholder ?? placeholder,
                  ),
                ),
              );
            },
          ),
        );
        final BorderRadius? borderRadius = clipBorderRadius;
        if (borderRadius != null) {
          image = ClipRRect(borderRadius: borderRadius, child: image);
        }
        return image;
      },
    );
  }
}

Future<double> resolveCoverAspectRatio({
  required ComicCoverDisplayData? coverDisplay,
  required double fallbackAspectRatio,
}) async {
  final Uint8List? memoryBytes = coverDisplay?.memoryBytes;
  final String? filePath = coverDisplay?.filePath;
  if ((memoryBytes == null || memoryBytes.isEmpty) &&
      (filePath == null || filePath.isEmpty)) {
    return fallbackAspectRatio;
  }
  try {
    final Uint8List sourceBytes =
        memoryBytes ?? await File(filePath!).readAsBytes();
    if (sourceBytes.isEmpty) {
      return fallbackAspectRatio;
    }
    final ui.Codec codec = await ui.instantiateImageCodec(sourceBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;
    if (image.height == 0) {
      return fallbackAspectRatio;
    }
    return image.width / image.height;
  } catch (_) {
    return fallbackAspectRatio;
  }
}
