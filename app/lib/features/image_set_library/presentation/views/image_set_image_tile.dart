import 'dart:typed_data';
import 'dart:ui' as ui;

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

/// Fallback aspect while page bytes / size probe are not ready yet.
const double kImageSetGalleryFallbackAspectRatio = 2 / 3;

/// Page bytes plus the aspect locked before paint (anti-jitter).
typedef ImageSetGalleryPageLayout = ({Uint8List bytes, double aspectRatio});

/// Resolves display aspect from [bytes]: header peek, else codec probe.
Future<double> imageSetGalleryAspectRatioOf(Uint8List bytes) async {
  final Size? peeked = peekCoverImageSize(bytes);
  if (peeked != null && peeked.width > 0 && peeked.height > 0) {
    return peeked.width / peeked.height;
  }
  final ui.Codec codec = await ui.instantiateImageCodec(bytes);
  final ui.FrameInfo frame = await codec.getNextFrame();
  try {
    final int width = frame.image.width;
    final int height = frame.image.height;
    if (width <= 0 || height <= 0) {
      return kImageSetGalleryFallbackAspectRatio;
    }
    return width / height;
  } finally {
    frame.image.dispose();
  }
}

/// Bytes + locked aspect for one gallery cell (size known before [Image] paints).
final imageSetGalleryPageLayoutProvider = FutureProvider.autoDispose
    .family<ImageSetGalleryPageLayout, ImageSetPageBytesKey>((
      Ref ref,
      ImageSetPageBytesKey key,
    ) async {
      final Uint8List bytes = await ref.watch(
        imageSetPageBytesProvider(key).future,
      );
      final double aspectRatio = await imageSetGalleryAspectRatioOf(bytes);
      return (bytes: bytes, aspectRatio: aspectRatio);
    });

/// Image set detail gallery cell: size-probed skeleton, affinity band, selection.
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
    final ImageSetPageBytesKey bytesKey = (
      libraryId: libraryId,
      image: image,
    );
    final AsyncValue<ImageSetGalleryPageLayout> layout = ref.watch(
      imageSetGalleryPageLayoutProvider(bytesKey),
    );
    final double opacity = image.excluded ? 0.45 : 1;
    final Color skeletonColor = theme.colorScheme.surfaceContainerHighest;

    // Do not paint a fixed-grid skeleton: wait until aspect is probed, then
    // lock AspectRatio and keep a solid fill under [Image.memory].
    if (layout.isLoading) {
      return const SizedBox.shrink();
    }
    if (layout.hasError) {
      return AspectRatio(
        aspectRatio: kImageSetGalleryFallbackAspectRatio,
        child: ColoredBox(
          color: skeletonColor,
          child: Icon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final ImageSetGalleryPageLayout page = layout.requireValue;
    final Widget imageBody = AspectRatio(
      aspectRatio: page.aspectRatio,
      child: Opacity(
        opacity: opacity,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(color: skeletonColor),
            Image.memory(
              page.bytes,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              filterQuality: kCatalogImageFilterQuality,
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) => Icon(
                Icons.broken_image_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
