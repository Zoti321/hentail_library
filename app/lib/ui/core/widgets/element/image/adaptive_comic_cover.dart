import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_display_data.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/image/app_comic_image.dart';

/// Adaptive comic cover with two layout modes:
///
/// - [containerAspectRatio] is `null`: container follows image aspect ratio
///   and uses [fit] (default [BoxFit.cover]).
/// - [containerAspectRatio] is set: fixed container ratio, [BoxFit.contain],
///   and letterboxing via [backgroundColor] (defaults to white).
class AdaptiveComicCover extends StatelessWidget {
  const AdaptiveComicCover({
    super.key,
    required this.coverDisplay,
    this.fallbackAspectRatio = 2 / 3,
    this.containerAspectRatio,
    this.fit = BoxFit.cover,
    this.filterQuality = FilterQuality.medium,
    this.placeholder = const SizedBox.expand(),
    this.errorPlaceholder,
    this.backgroundColor,
    this.maxCacheWidth,
    this.clipBorderRadius,
    this.showShadow = false,
  });

  final ComicCoverDisplayData? coverDisplay;
  final double fallbackAspectRatio;
  final double? containerAspectRatio;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final Widget placeholder;
  final Widget? errorPlaceholder;
  final Color? backgroundColor;
  final int? maxCacheWidth;
  final BorderRadius? clipBorderRadius;
  final bool showShadow;

  bool get _usesFixedContainer => containerAspectRatio != null;

  BoxFit get _effectiveFit => _usesFixedContainer ? BoxFit.contain : fit;

  Color _resolveBackgroundColor() {
    if (backgroundColor != null) {
      return backgroundColor!;
    }
    if (_usesFixedContainer) {
      return Colors.white;
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final double? fixedAspectRatio = containerAspectRatio;
    if (fixedAspectRatio != null) {
      return _wrapChrome(
        context,
        _buildAspectRatioCover(context, fixedAspectRatio),
      );
    }
    return FutureBuilder<double>(
      future: resolveCoverAspectRatio(
        coverDisplay: coverDisplay,
        fallbackAspectRatio: fallbackAspectRatio,
      ),
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
        final double resolvedAspectRatio = snapshot.data ?? fallbackAspectRatio;
        return _wrapChrome(
          context,
          _buildAspectRatioCover(context, resolvedAspectRatio),
        );
      },
    );
  }

  Widget _buildAspectRatioCover(BuildContext context, double aspectRatio) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int coverCacheWidth = AppComicImage.resolveCacheWidth(
            context: context,
            logicalWidth: constraints.maxWidth,
            maxWidth: maxCacheWidth,
          );
          return ColoredBox(
            color: _resolveBackgroundColor(),
            child: AppComicImage(
              memoryBytes: coverDisplay?.memoryBytes,
              filePath: coverDisplay?.filePath,
              fit: _effectiveFit,
              cacheWidth: coverCacheWidth,
              filterQuality: filterQuality,
              placeholder: placeholder,
              errorPlaceholder: errorPlaceholder ?? placeholder,
            ),
          );
        },
      ),
    );
  }

  Widget _wrapChrome(BuildContext context, Widget child) {
    final BorderRadius? borderRadius = clipBorderRadius;
    Widget result = child;
    if (borderRadius != null) {
      result = ClipRRect(borderRadius: borderRadius, child: result);
    }
    if (!showShadow) {
      return result;
    }
    final ColorScheme cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: cs.hentai.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: result,
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

@Deprecated('Use AdaptiveComicCover instead.')
typedef AdaptiveCover = AdaptiveComicCover;
