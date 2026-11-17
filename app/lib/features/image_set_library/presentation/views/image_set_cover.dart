import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/shared/ui/image/catalog_image_filter_quality.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// First catalog image cover for an Image set (page-bytes path).
class ImageSetCover extends ConsumerWidget {
  const ImageSetCover({
    super.key,
    required this.libraryId,
    required this.imageSetId,
    this.fit = BoxFit.cover,
  });

  final String libraryId;
  final String imageSetId;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final M3EThemeData theme = M3ETheme.of(context);
    final AsyncValue<List<ImageSetImage>> images = ref.watch(
      imageSetImagesProvider((libraryId: libraryId, imageSetId: imageSetId)),
    );

    return images.when(
      data: (List<ImageSetImage> list) {
        if (list.isEmpty) {
          return _ImageSetCoverPlaceholder(theme: theme);
        }
        return _ImageSetCoverBytes(
          libraryId: libraryId,
          image: list.first,
          fit: fit,
          theme: theme,
        );
      },
      loading: () => _ImageSetCoverPlaceholder(theme: theme),
      error: (Object _, StackTrace _) =>
          _ImageSetCoverPlaceholder(theme: theme, broken: true),
    );
  }
}

class _ImageSetCoverBytes extends ConsumerWidget {
  const _ImageSetCoverBytes({
    required this.libraryId,
    required this.image,
    required this.fit,
    required this.theme,
  });

  final String libraryId;
  final ImageSetImage image;
  final BoxFit fit;
  final M3EThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Uint8List> bytes = ref.watch(
      imageSetPageBytesProvider((libraryId: libraryId, image: image)),
    );

    return bytes.when(
      data: (Uint8List data) => Image.memory(
        data,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        filterQuality: kCatalogImageFilterQuality,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) => _ImageSetCoverPlaceholder(theme: theme, broken: true),
      ),
      loading: () => _ImageSetCoverPlaceholder(theme: theme),
      error: (Object _, StackTrace _) =>
          _ImageSetCoverPlaceholder(theme: theme, broken: true),
    );
  }
}

class _ImageSetCoverPlaceholder extends StatelessWidget {
  const _ImageSetCoverPlaceholder({required this.theme, this.broken = false});

  final M3EThemeData theme;
  final bool broken;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          broken ? Icons.broken_image_outlined : Icons.collections_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
