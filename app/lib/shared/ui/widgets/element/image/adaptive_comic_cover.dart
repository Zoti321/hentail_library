import 'package:flutter/material.dart';
import 'package:hentai_library/core/image/image_decode_cache_size.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_source.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/app_comic_image.dart';

/// Adaptive comic cover with a fixed container aspect ratio and letterboxing.
class AdaptiveComicCover extends StatelessWidget {
  const AdaptiveComicCover({
    super.key,
    required this.coverDisplay,
    required this.containerAspectRatio,
    this.filterQuality = FilterQuality.medium,
    this.placeholder = const SizedBox.expand(),
    this.errorPlaceholder,
    this.backgroundColor,
    this.clipBorderRadius,
    this.showShadow = false,
    this.gaplessPlayback = true,
    this.onDecodeError,
  });

  final ComicCoverSource? coverDisplay;
  final double containerAspectRatio;
  final FilterQuality filterQuality;
  final Widget placeholder;
  final Widget? errorPlaceholder;
  final Color? backgroundColor;
  final BorderRadius? clipBorderRadius;
  final bool showShadow;

  /// 详情 / Hero 场景默认 true，避免交接闪烁。
  final bool gaplessPlayback;
  final VoidCallback? onDecodeError;

  Color _resolveBackgroundColor() {
    return backgroundColor ?? Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return _wrapChrome(
      context,
      AspectRatio(
        aspectRatio: containerAspectRatio,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final ImageDecodeCacheSize cacheSize = decodeCacheSizeForContext(
              context,
              logicalWidth: constraints.maxWidth,
              logicalHeight: constraints.maxHeight,
            );
            return ColoredBox(
              color: _resolveBackgroundColor(),
              child: AppComicImage(
                memoryBytes: coverDisplay?.memoryBytes,
                filePath: coverDisplay?.filePath,
                fit: BoxFit.contain,
                filterQuality: filterQuality,
                cacheWidth: cacheSize.cacheWidth,
                gaplessPlayback: gaplessPlayback,
                placeholder: placeholder,
                errorPlaceholder: errorPlaceholder ?? placeholder,
                onDecodeError: onDecodeError,
              ),
            );
          },
        ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: context.shadows.catalogCardRest,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: result,
    );
  }
}
