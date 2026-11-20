import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_cover_providers.dart';
import 'package:hentai_library/shared/ui/image/catalog_image_filter_quality.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Catalog cover for an Image set (persisted ≤512 JPEG, not page-bytes).
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
    final AsyncValue<Uint8List?> bytes = ref.watch(
      imageSetCoverBytesProvider((
        libraryId: libraryId,
        imageSetId: imageSetId,
      )),
    );

    return bytes.when(
      data: (Uint8List? data) {
        if (data == null || data.isEmpty) {
          return _ImageSetCoverPlaceholder(theme: theme);
        }
        return Image.memory(
          data,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          filterQuality: kCatalogImageFilterQuality,
          errorBuilder:
              (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) => _ImageSetCoverPlaceholder(theme: theme, broken: true),
        );
      },
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
