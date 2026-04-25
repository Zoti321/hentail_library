import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/presentation/dto/comic_cover_display_data.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ComicDetailCover extends ConsumerWidget {
  const ComicDetailCover({super.key, required this.comic});

  final Comic comic;
  static const double fallbackAspectRatio = 2 / 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final ComicCoverDisplayData? coverData = ref
        .watch(comicCoverDisplayProvider(comicId: comic.comicId))
        .maybeWhen(data: (ComicCoverDisplayData? v) => v, orElse: () => null);

    return FutureBuilder<double>(
      future: resolveCoverAspectRatio(coverData),
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
        final double resolvedAspectRatio = snapshot.data ?? fallbackAspectRatio;
        return AspectRatio(
          aspectRatio: resolvedAspectRatio,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int coverCacheWidth = AppComicImage.resolveCacheWidth(
                context: context,
                logicalWidth: constraints.maxWidth,
                maxWidth: 1600,
              );
              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(tokens.radius.lg),
                  border: Border.all(color: cs.borderSubtle),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: cs.cardShadow,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(tokens.radius.lg),
                  child: ColoredBox(
                    color: cs.surfaceContainerHighest,
                    child: AppComicImage(
                      filePath: coverData?.filePath,
                      memoryBytes: coverData?.memoryBytes,
                      fit: BoxFit.cover,
                      cacheWidth: coverCacheWidth,
                      filterQuality: FilterQuality.medium,
                      placeholder: const SizedBox.expand(),
                      errorPlaceholder: Icon(
                        LucideIcons.imageOff,
                        size: 36,
                        color: cs.imageFallback,
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

  Future<double> resolveCoverAspectRatio(ComicCoverDisplayData? coverData) async {
    final Uint8List? memoryBytes = coverData?.memoryBytes;
    final String? filePath = coverData?.filePath;
    if ((memoryBytes == null || memoryBytes.isEmpty) &&
        (filePath == null || filePath.isEmpty)) {
      return fallbackAspectRatio;
    }
    try {
      final Uint8List sourceBytes =
          memoryBytes ?? await File(filePath!).readAsBytes();
      if (sourceBytes.isEmpty) {
        return fallbackAspectRatio;
      }
      final ui.Codec codec = await ui.instantiateImageCodec(sourceBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      if (image.height == 0) {
        return fallbackAspectRatio;
      }
      return image.width / image.height;
    } catch (_) {
      return fallbackAspectRatio;
    }
  }
}
