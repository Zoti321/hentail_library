import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_cover.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Image-set catalog card: cover + name + image count (not [ComicCard]).
class ImageSetCard extends StatelessWidget {
  const ImageSetCard({
    super.key,
    required this.libraryId,
    required this.imageSetId,
    required this.title,
    required this.imageCount,
    required this.onTap,
  });

  final String libraryId;
  final String imageSetId;
  final String title;
  final int imageCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ESpacing spacing = theme.spacing;
    final M3ETypeScale type = theme.typeScale;
    final AppLocalizations l10n = context.l10n;
    final String countLabel = l10n.imageSetDetailImageCount(imageCount);

    return ComicCatalogCardShell(
      enabled: true,
      trackHover: true,
      onPressed: onTap,
      semanticLabel: '$title, $countLabel',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: comicCatalogTitleStyle(type, scheme),
                ),
                Text(
                  countLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: comicCatalogSubtitleStyle(type, scheme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
