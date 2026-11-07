import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_source.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_placeholder.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/cover_letterbox.dart';

/// Catalog-card cover: MD3 letterbox + soft-crop [BoxFit] after decode.
///
/// No [cacheWidth]: library thumbs are already ≤512px; omitting ResizeImage
/// keeps the same [ImageProvider] while Hero resizes the flight child.
class CardLetterboxedCoverImage extends StatefulWidget {
  const CardLetterboxedCoverImage({
    super.key,
    required this.cover,
    this.onDecodeError,
    this.fit,
    this.alignment = Alignment.center,
    /// Hero / 软裁切切换时保留上一帧，避免飞行中露出 letterbox 纯色。
    this.gaplessPlayback = true,
  });

  final ComicCoverSource cover;
  final VoidCallback? onDecodeError;

  /// When non-null, overrides soft-crop selection (e.g. forced [BoxFit.cover]).
  final BoxFit? fit;
  final AlignmentGeometry alignment;

  final bool gaplessPlayback;

  @override
  State<CardLetterboxedCoverImage> createState() =>
      _CardLetterboxedCoverImageState();
}

class _CardLetterboxedCoverImageState extends State<CardLetterboxedCoverImage> {
  BoxFit _resolvedFit = BoxFit.contain;
  Size? _imageSize;

  @override
  void didUpdateWidget(covariant CardLetterboxedCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cover.filePath != widget.cover.filePath ||
        !identical(oldWidget.cover.memoryBytes, widget.cover.memoryBytes)) {
      _imageSize = null;
      _resolvedFit = widget.fit ?? BoxFit.contain;
    } else if (oldWidget.fit != widget.fit && widget.fit != null) {
      _resolvedFit = widget.fit!;
    }
  }

  void _applySoftFit(Size size, double boxAspect) {
    if (!mounted || widget.fit != null) {
      return;
    }
    final BoxFit next = coverFitForAspects(
      imageAspect: size.width / size.height,
      boxAspect: boxAspect,
    );
    if (next != _resolvedFit) {
      setState(() => _resolvedFit = next);
    }
  }

  void _onImageSize(Size size, double boxAspect) {
    if (!mounted) {
      return;
    }
    if (_imageSize == size && widget.fit == null) {
      return;
    }
    _imageSize = size;
    if (widget.fit != null) {
      return;
    }
    // 路由 / Hero 动画中途改 fit 会触发重绘闪烁；等落地后再软裁切。
    runAfterCoverRouteSettled(
      context,
      () => _applySoftFit(size, boxAspect),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double boxWidth = constraints.maxWidth;
        final double boxHeight = constraints.maxHeight;
        final double boxAspect = boxWidth > 0 && boxHeight > 0
            ? boxWidth / boxHeight
            : 0;
        final BoxFit fit = widget.fit ?? _resolvedFit;
        return ColoredBox(
          color: coverLetterboxColor(context),
          child: AppComicImage(
            filePath: widget.cover.filePath,
            memoryBytes: widget.cover.memoryBytes,
            fit: fit,
            alignment: widget.alignment,
            gaplessPlayback: widget.gaplessPlayback,
            placeholder: const ComicCoverPlaceholder(
              variant: ComicCoverPlaceholderVariant.card,
              kind: ComicCoverPlaceholderKind.loading,
            ),
            errorPlaceholder: const ComicCoverPlaceholder(
              variant: ComicCoverPlaceholderVariant.card,
              kind: ComicCoverPlaceholderKind.error,
            ),
            onDecodeError: widget.onDecodeError,
            onImageSize: boxAspect > 0
                ? (Size size) => _onImageSize(size, boxAspect)
                : null,
          ),
        );
      },
    );
  }
}
