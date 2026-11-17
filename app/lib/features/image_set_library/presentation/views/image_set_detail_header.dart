import 'package:flutter/material.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_cover.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Image set detail chrome: cover, title, count.
///
/// Author / Tags / Parody / Character omit when empty (no metadata binding in
/// this slice, so those sections are not rendered).
class ImageSetDetailHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 120,
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: ImageSetCover(libraryId: libraryId, imageSetId: imageSetId),
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
    );
  }
}
