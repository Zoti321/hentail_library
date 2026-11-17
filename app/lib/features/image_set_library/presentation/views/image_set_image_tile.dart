import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/shared/ui/image/catalog_image_filter_quality.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Image set detail tile: page-bytes decode, no caption, intrinsic aspect.
class ImageSetImageTile extends ConsumerWidget {
  const ImageSetImageTile({
    super.key,
    required this.libraryId,
    required this.image,
    required this.onTap,
  });

  final String libraryId;
  final ImageSetImage image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final M3EThemeData theme = M3ETheme.of(context);
    final AsyncValue<Uint8List> bytes = ref.watch(
      imageSetPageBytesProvider((libraryId: libraryId, image: image)),
    );

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: onTap,
        child: bytes.when(
          data: (Uint8List data) => Image.memory(
            data,
            fit: BoxFit.fitWidth,
            width: double.infinity,
            gaplessPlayback: true,
            filterQuality: kCatalogImageFilterQuality,
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) =>
                    _TilePlaceholder(theme: theme, broken: true),
          ),
          loading: () => AspectRatio(
            aspectRatio: 2 / 3,
            child: _TilePlaceholder(theme: theme),
          ),
          error: (Object _, StackTrace _) => AspectRatio(
            aspectRatio: 2 / 3,
            child: _TilePlaceholder(theme: theme, broken: true),
          ),
        ),
      ),
    );
  }
}

class _TilePlaceholder extends StatelessWidget {
  const _TilePlaceholder({required this.theme, this.broken = false});

  final M3EThemeData theme;
  final bool broken;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          broken ? Icons.broken_image_outlined : Icons.image_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
