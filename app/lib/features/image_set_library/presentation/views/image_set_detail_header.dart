import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_cover.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/shared/detail_metadata_chip_rows.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Image set detail chrome: cover, title, count, read-only facet chips.
///
/// Unbound Author / Tag / Parody / Character rows are omitted (no Comic
/// metadata binding and no empty placeholders).
class ImageSetDetailHeader extends ConsumerWidget {
  const ImageSetDetailHeader({
    super.key,
    required this.libraryId,
    required this.imageSetId,
    required this.title,
    required this.imageCount,
  });

  final String libraryId;
  final String imageSetId;
  final String title;
  final int imageCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;
    final AsyncValue<ImageSetFacets> facetsAsync = ref.watch(
      imageSetFacetsProvider(imageSetId),
    );
    final ImageSetFacets? facets = facetsAsync.asData?.value;
    final bool showFacets = facets != null && !facets.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              key: const Key('imageSetDetailCover'),
              width: 168,
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: ImageSetCover(
                  libraryId: libraryId,
                  imageSetId: imageSetId,
                ),
              ),
            ),
            SizedBox(width: spacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.typeScale.titleLarge.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    l10n.imageSetDetailImageCount(imageCount),
                    style: theme.typeScale.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showFacets) ...<Widget>[
          SizedBox(height: spacing.md),
          DetailMetadataChipRows(
            parodies: facets.parodies,
            authors: facets.authors
                .map((String name) => AuthorRef(name: name))
                .toList(),
            characters: facets.characters,
            tags: facets.tags,
          ),
        ],
      ],
    );
  }
}
