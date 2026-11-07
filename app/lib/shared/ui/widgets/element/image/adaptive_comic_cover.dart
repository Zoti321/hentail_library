import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_source.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/cover_letterbox.dart';

/// Adaptive comic cover with a fixed container aspect ratio and soft letterbox.
class AdaptiveComicCover extends StatefulWidget {
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

  @override
  State<AdaptiveComicCover> createState() => _AdaptiveComicCoverState();
}

class _AdaptiveComicCoverState extends State<AdaptiveComicCover> {
  BoxFit _resolvedFit = BoxFit.contain;
  Size? _imageSize;

  @override
  void didUpdateWidget(covariant AdaptiveComicCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ComicCoverSource? oldCover = oldWidget.coverDisplay;
    final ComicCoverSource? nextCover = widget.coverDisplay;
    if (oldCover?.filePath != nextCover?.filePath ||
        !identical(oldCover?.memoryBytes, nextCover?.memoryBytes)) {
      _imageSize = null;
      _resolvedFit = BoxFit.contain;
    }
  }

  Color _resolveBackgroundColor(BuildContext context) {
    return widget.backgroundColor ?? coverLetterboxColor(context);
  }

  void _applySoftFit(Size size) {
    if (!mounted) {
      return;
    }
    final BoxFit next = coverFitForAspects(
      imageAspect: size.width / size.height,
      boxAspect: widget.containerAspectRatio,
    );
    if (next != _resolvedFit) {
      setState(() => _resolvedFit = next);
    }
  }

  void _onImageSize(Size size) {
    if (!mounted) {
      return;
    }
    if (_imageSize == size) {
      return;
    }
    _imageSize = size;
    runAfterCoverRouteSettled(context, () => _applySoftFit(size));
  }

  @override
  Widget build(BuildContext context) {
    return _wrapChrome(
      context,
      AspectRatio(
        aspectRatio: widget.containerAspectRatio,
        child: ColoredBox(
          color: _resolveBackgroundColor(context),
          child: AppComicImage(
            memoryBytes: widget.coverDisplay?.memoryBytes,
            filePath: widget.coverDisplay?.filePath,
            fit: _resolvedFit,
            filterQuality: widget.filterQuality,
            gaplessPlayback: widget.gaplessPlayback,
            placeholder: widget.placeholder,
            errorPlaceholder: widget.errorPlaceholder ?? widget.placeholder,
            onDecodeError: widget.onDecodeError,
            onImageSize: _onImageSize,
          ),
        ),
      ),
    );
  }

  Widget _wrapChrome(BuildContext context, Widget child) {
    final BorderRadius? borderRadius = widget.clipBorderRadius;
    Widget result = child;
    if (borderRadius != null) {
      result = ClipRRect(borderRadius: borderRadius, child: result);
    }
    if (!widget.showShadow) {
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
