import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_source.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_placeholder.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/cover_letterbox.dart';

/// Catalog-card cover: MD3 letterbox + soft-crop [BoxFit] after decode.
///
/// No [cacheWidth]: library thumbs are already ≤512px; omitting ResizeImage
/// keeps the same [ImageProvider] while Hero resizes the flight child.
/// Soft-crop prefers a JPEG/PNG header peek so first paint already matches
/// the settled fit (avoids Hero landing contain→cover jitter).
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
  Size? _imageSize;

  @override
  void didUpdateWidget(covariant CardLetterboxedCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cover.filePath != widget.cover.filePath ||
        !identical(oldWidget.cover.memoryBytes, widget.cover.memoryBytes)) {
      _imageSize = null;
    }
  }

  void _onImageSize(Size size) {
    if (!mounted || _imageSize == size) {
      return;
    }
    // Header peek already drove the same fit — record size without rebuild.
    final Size? peeked = peekCoverImageSize(widget.cover.memoryBytes);
    if (_imageSize == null && peeked == size) {
      _imageSize = size;
      return;
    }
    setState(() => _imageSize = size);
  }

  BoxFit _fitForBoxAspect(double boxAspect) {
    if (widget.fit != null) {
      return widget.fit!;
    }
    final Size? known =
        _imageSize ?? peekCoverImageSize(widget.cover.memoryBytes);
    return coverFitForImageSize(imageSize: known, boxAspect: boxAspect);
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
        final BoxFit fit = boxAspect > 0
            ? _fitForBoxAspect(boxAspect)
            : (widget.fit ?? BoxFit.contain);
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
            onImageSize: boxAspect > 0 ? _onImageSize : null,
          ),
        );
      },
    );
  }
}
