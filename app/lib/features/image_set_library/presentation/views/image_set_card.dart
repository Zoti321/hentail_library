import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_cover.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Image-set catalog card: cover + name (not [ComicCard]).
class ImageSetCard extends StatelessWidget {
  const ImageSetCard({
    super.key,
    required this.libraryId,
    required this.imageSetId,
    required this.title,
    required this.onTap,
  });

  final String libraryId;
  final String imageSetId;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ESpacing spacing = theme.spacing;
    final M3ETypeScale type = theme.typeScale;

    return ComicCatalogCardShell(
      enabled: true,
      trackHover: true,
      onPressed: onTap,
      semanticLabel: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 2 / 3,
            child: ImageSetCover(libraryId: libraryId, imageSetId: imageSetId),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              kComicCatalogContentHorizontalPadding,
              spacing.md,
              kComicCatalogContentHorizontalPadding,
              kComicCatalogContentHorizontalPadding,
            ),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: comicCatalogTitleStyle(type, scheme),
            ),
          ),
        ],
      ),
    );
  }
}
