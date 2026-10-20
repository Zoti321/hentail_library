import 'package:flutter/material.dart';
import 'package:hentai_library/core/image/image_decode_cache_size.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_source.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_placeholder.dart';

/// Catalog-card cover: white letterbox + [BoxFit.contain] by default.
///
/// Decode uses [cacheWidth] only so intrinsic aspect is preserved.
class CardLetterboxedCoverImage extends StatelessWidget {
  const CardLetterboxedCoverImage({
    super.key,
    required this.cover,
    this.onDecodeError,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final ComicCoverSource cover;
  final VoidCallback? onDecodeError;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final ImageDecodeCacheSize cacheSize = decodeCacheSizeForContext(
          context,
          logicalWidth: constraints.maxWidth,
          logicalHeight: constraints.maxHeight,
        );
        return ColoredBox(
          color: Colors.white,
          child: AppComicImage(
            filePath: cover.filePath,
            memoryBytes: cover.memoryBytes,
            fit: fit,
            alignment: alignment,
            cacheWidth: cacheSize.cacheWidth,
            placeholder: const ComicCoverPlaceholder(
              variant: ComicCoverPlaceholderVariant.card,
              kind: ComicCoverPlaceholderKind.loading,
            ),
            errorPlaceholder: const ComicCoverPlaceholder(
              variant: ComicCoverPlaceholderVariant.card,
              kind: ComicCoverPlaceholderKind.error,
            ),
            onDecodeError: onDecodeError,
          ),
        );
      },
    );
  }
}
