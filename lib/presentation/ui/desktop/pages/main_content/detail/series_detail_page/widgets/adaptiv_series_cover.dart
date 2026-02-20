import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/comic/series_item.dart';
import 'package:hentai_library/presentation/dto/comic_cover_display_data.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/theme/theme.dart';

/// Adaptive series cover with real image ratio and fallback.
class AdaptiveSeriesCover extends ConsumerWidget {
  const AdaptiveSeriesCover({super.key, required this.series});

  final Series series;
  static const double _fallbackAspectRatio = 2 / 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SeriesItem? coverItem = series.coverItem;
    final String? coverComicId = coverItem?.comicId;
    final ComicCoverDisplayData? coverDisplay = coverComicId != null
        ? ref
              .watch(comicCoverDisplayProvider(comicId: coverComicId))
              .maybeWhen(
                data: (ComicCoverDisplayData? v) => v,
                orElse: () => null,
              )
        : null;

    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return FutureBuilder<double>(
      future: _resolveCoverAspectRatio(coverDisplay),
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
        final double resolvedAspectRatio =
            snapshot.data ?? _fallbackAspectRatio;
        return AspectRatio(
          aspectRatio: resolvedAspectRatio,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int coverCacheWidth = AppComicImage.resolveCacheWidth(
                context: context,
                logicalWidth: constraints.maxWidth,
              );
              return ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radius.lg),
                child: SizedBox.expand(
                  child: ColoredBox(
                    color: cs.imagePlaceholder,
                    child: AppComicImage(
                      memoryBytes: coverDisplay?.memoryBytes,
                      filePath: coverDisplay?.filePath,
                      fit: BoxFit.cover,
                      cacheWidth: coverCacheWidth,
                      filterQuality: FilterQuality.medium,
                      placeholder: const SizedBox.expand(),
                      errorPlaceholder: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: cs.iconSecondary,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<double> _resolveCoverAspectRatio(
    ComicCoverDisplayData? coverDisplay,
  ) async {
    final Uint8List? memoryBytes = coverDisplay?.memoryBytes;
    final String? filePath = coverDisplay?.filePath;
    if ((memoryBytes == null || memoryBytes.isEmpty) &&
        (filePath == null || filePath.isEmpty)) {
      return _fallbackAspectRatio;
    }
    try {
      final Uint8List sourceBytes =
          memoryBytes ?? await File(filePath!).readAsBytes();
      if (sourceBytes.isEmpty) {
        return _fallbackAspectRatio;
      }
      final ui.Codec codec = await ui.instantiateImageCodec(sourceBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      if (image.height == 0) {
        return _fallbackAspectRatio;
      }
      return image.width / image.height;
    } catch (_) {
      return _fallbackAspectRatio;
    }
  }
}
