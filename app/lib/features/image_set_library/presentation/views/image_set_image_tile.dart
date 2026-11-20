import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/image/catalog_image_filter_quality.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Reserved strip band height for submission affinity (reorder-ready cell geometry).
const double kImageSetAffinityStripBandHeight = 8;

/// Default cover aspect before bytes decode (anti-jitter).
const double kImageSetGalleryAspectRatio = 2 / 3;

/// Image set detail gallery cell: fixed aspect skeleton, affinity band, selection.
class ImageSetImageTile extends ConsumerWidget {
  const ImageSetImageTile({
    super.key,
    required this.libraryId,
    required this.image,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTapDown,
    this.onSelectionChanged,
    this.selected = false,
    this.selectionMode = false,
    this.compactWidth,
    this.affinitySubmissionIndexes = const <int>[],
  });

  final String libraryId;
  final ImageSetImage image;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GestureTapDownCallback? onSecondaryTapDown;
  final ValueChanged<bool>? onSelectionChanged;
  final bool selected;
  final bool selectionMode;

  /// When set, tile uses fixed width; otherwise fills the grid cell.
  final double? compactWidth;

  /// Stable indexes into this Image set's submissions list (multi = stacked strips).
  final List<int> affinitySubmissionIndexes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final M3EThemeData theme = M3ETheme.of(context);
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<Uint8List> bytes = ref.watch(
      imageSetPageBytesProvider((libraryId: libraryId, image: image)),
    );
    final double opacity = image.excluded ? 0.45 : 1;
    final Color skeletonColor = theme.colorScheme.surfaceContainerHighest;

    final Widget imageBody = AspectRatio(
      aspectRatio: kImageSetGalleryAspectRatio,
      child: Opacity(
        opacity: opacity,
        child: bytes.when(
          data: (Uint8List data) => Image.memory(
            data,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
            filterQuality: kCatalogImageFilterQuality,
            errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
            ) => ColoredBox(
              color: skeletonColor,
              child: Icon(
                Icons.broken_image_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          loading: () => ColoredBox(color: skeletonColor),
          error: (Object _, StackTrace _) => ColoredBox(
            color: skeletonColor,
            child: Icon(
              Icons.broken_image_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );

    final Widget cell = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: kImageSetAffinityStripBandHeight,
          child: affinitySubmissionIndexes.isEmpty
              ? const SizedBox.expand()
              : KeyedSubtree(
                  key: Key('imageSetAffinityStrips-${image.imageSetImageId}'),
                  child: Column(
                    children: <Widget>[
                      for (final int index in affinitySubmissionIndexes)
                        Expanded(
                          child: ColoredBox(
                            key: Key(
                              'imageSetAffinityStrip-${image.imageSetImageId}-$index',
                            ),
                            color: _affinityStripColor(
                              theme.colorScheme,
                              index,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            imageBody,
            if (image.excluded)
              Positioned(
                left: theme.spacing.xs,
                bottom: theme.spacing.xs,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.92,
                    ),
                    borderRadius: BorderRadius.circular(theme.spacing.xs),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(theme.spacing.xs),
                    child: Text(
                      l10n.imageSetDetailExcludedBadge,
                      style: theme.typeScale.labelSmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            if (selectionMode)
              Positioned(
                left: kComicCardSelectionInset,
                top: kComicCardSelectionInset,
                child: M3ECheckbox(
                  value: selected,
                  onChanged: onSelectionChanged == null
                      ? null
                      : (bool? value) {
                          if (value == null) {
                            return;
                          }
                          onSelectionChanged!(value);
                        },
                ),
              ),
          ],
        ),
      ],
    );

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTapDown: onSecondaryTapDown,
        child: compactWidth != null
            ? SizedBox(width: compactWidth, child: cell)
            : cell,
      ),
    );
  }
}

Color _affinityStripColor(M3EColorScheme scheme, int submissionIndex) {
  final List<Color> palette = <Color>[
    scheme.primary,
    scheme.secondary,
    scheme.tertiary,
    scheme.error,
  ];
  return palette[submissionIndex % palette.length];
}
