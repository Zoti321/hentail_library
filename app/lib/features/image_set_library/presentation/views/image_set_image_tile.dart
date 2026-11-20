import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/image/catalog_image_filter_quality.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Image set detail tile: page-bytes decode, no caption, intrinsic aspect.
class ImageSetImageTile extends ConsumerWidget {
  const ImageSetImageTile({
    super.key,
    required this.libraryId,
    required this.image,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTapDown,
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
  final bool selected;
  final bool selectionMode;

  /// When set, tile uses fixed width; otherwise full width grid cell.
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
    final Widget thumbnail = Opacity(
      opacity: opacity,
      child: bytes.when(
        data: (Uint8List data) => Image.memory(
          data,
          fit: BoxFit.fitWidth,
          width: compactWidth ?? double.infinity,
          gaplessPlayback: true,
          filterQuality: kCatalogImageFilterQuality,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) => _TilePlaceholder(theme: theme, broken: true, width: compactWidth),
        ),
        loading: () => AspectRatio(
          aspectRatio: 2 / 3,
          child: _TilePlaceholder(theme: theme, width: compactWidth),
        ),
        error: (Object _, StackTrace _) => AspectRatio(
          aspectRatio: 2 / 3,
          child: _TilePlaceholder(theme: theme, broken: true, width: compactWidth),
        ),
      ),
    );

  final Widget content = Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        thumbnail,
        if (image.excluded)
          Positioned(
            left: theme.spacing.xs,
            top: theme.spacing.xs,
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
            right: theme.spacing.xs,
            top: theme.spacing.xs,
            child: Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );

    final Widget tiled = affinitySubmissionIndexes.isEmpty
        ? content
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              KeyedSubtree(
                key: Key('imageSetAffinityStrips-${image.imageSetImageId}'),
                child: Column(
                  children: <Widget>[
                    for (final int index in affinitySubmissionIndexes)
                      ColoredBox(
                        key: Key(
                          'imageSetAffinityStrip-${image.imageSetImageId}-$index',
                        ),
                        color: _affinityStripColor(theme.colorScheme, index),
                        child: SizedBox(height: theme.spacing.xs / 2),
                      ),
                  ],
                ),
              ),
              content,
            ],
          );

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTapDown: onSecondaryTapDown,
        child: compactWidth != null
            ? SizedBox(width: compactWidth, child: tiled)
            : tiled,
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

class _TilePlaceholder extends StatelessWidget {
  const _TilePlaceholder({
    required this.theme,
    this.broken = false,
    this.width,
  });

  final M3EThemeData theme;
  final bool broken;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerHigh,
        child: Center(
          child: Icon(
            broken ? Icons.broken_image_outlined : Icons.image_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}