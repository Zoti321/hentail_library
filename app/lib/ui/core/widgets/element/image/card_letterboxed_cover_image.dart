import 'package:flutter/material.dart';
import 'package:hentai_library/core/image/image_decode_cache_size.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_image.dart';
import 'package:hentai_library/ui/core/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_placeholder.dart';

/// Catalog-card cover: white letterbox + [BoxFit.contain].
///
/// Decode uses [cacheWidth] only so intrinsic aspect is preserved.
class CardLetterboxedCoverImage extends StatelessWidget {
  const CardLetterboxedCoverImage({
    super.key,
    required this.cover,
    this.onDecodeError,
  });

  final ComicCoverImage cover;
  final VoidCallback? onDecodeError;

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
            fit: BoxFit.contain,
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
