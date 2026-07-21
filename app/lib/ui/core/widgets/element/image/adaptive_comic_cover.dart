import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_image.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/image/app_comic_image.dart';

/// Adaptive comic cover with a fixed container aspect ratio and letterboxing.
class AdaptiveComicCover extends StatelessWidget {
  const AdaptiveComicCover({
    super.key,
    required this.coverDisplay,
    required this.containerAspectRatio,
    this.fallbackAspectRatio = 2 / 3,
    this.fit = BoxFit.cover,
    this.filterQuality = FilterQuality.medium,
    this.placeholder = const SizedBox.expand(),
    this.errorPlaceholder,
    this.backgroundColor,
    this.clipBorderRadius,
    this.showShadow = false,
    this.onDecodeError,
  });

  final ComicCoverImage? coverDisplay;
  final double containerAspectRatio;
  final double fallbackAspectRatio;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final Widget placeholder;
  final Widget? errorPlaceholder;
  final Color? backgroundColor;
  final BorderRadius? clipBorderRadius;
  final bool showShadow;
  final VoidCallback? onDecodeError;

  BoxFit get _effectiveFit => BoxFit.contain;

  Color _resolveBackgroundColor() {
    return backgroundColor ?? Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return _wrapChrome(
      context,
      _buildAspectRatioCover(context, containerAspectRatio),
    );
  }

  Widget _buildAspectRatioCover(BuildContext context, double aspectRatio) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return ColoredBox(
            color: _resolveBackgroundColor(),
            child: AppComicImage(
              memoryBytes: coverDisplay?.memoryBytes,
              filePath: coverDisplay?.filePath,
              fit: _effectiveFit,
              filterQuality: filterQuality,
              placeholder: placeholder,
              errorPlaceholder: errorPlaceholder ?? placeholder,
              onDecodeError: onDecodeError,
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
