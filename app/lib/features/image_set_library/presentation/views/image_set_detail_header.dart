import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_cover.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Stub metadata chrome for Image set detail (no comic_metadata binding).
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
    final String empty = l10n.imageSetDetailMetaEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 120,
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
              SizedBox(height: spacing.md),
              _StubMetaRow(label: l10n.comicDetailAuthors, value: empty),
              SizedBox(height: spacing.sm),
              _StubMetaRow(label: l10n.comicDetailTags, value: empty),
              SizedBox(height: spacing.sm),
              _StubMetaRow(label: l10n.comicDetailParodies, value: empty),
              SizedBox(height: spacing.sm),
              _StubMetaRow(label: l10n.comicDetailCharacters, value: empty),
            ],
          ),
        ),
      ],
    );
  }
}

class _StubMetaRow extends StatelessWidget {
  const _StubMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ETypeScale type = theme.typeScale;
    final M3EColorScheme scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: kComicDetailMetaLabelWidth,
          child: Text(
            label,
            style: type.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
        ),
        SizedBox(width: theme.spacing.lg),
        Expanded(
          child: Text(
            value,
            style: type.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
