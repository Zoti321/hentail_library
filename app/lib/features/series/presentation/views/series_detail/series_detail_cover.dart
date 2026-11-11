import 'package:flutter/material.dart';
import 'package:hentai_library/features/series/di/series_cover_providers.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/thumbnail/series_cover_source.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_source.dart';
import 'package:hentai_library/shared/di/series_slot_providers.dart';
import 'package:hentai_library/shared/ui/slots/series_slots.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/catalog_cover_hero.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/adaptive_comic_cover.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_placeholder.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// MD3E 系列详情封面：沿用系列封面来源（[seriesCoverSourceProvider]），填充到 MD3E 封面容器内。
class SeriesDetailCover extends ConsumerWidget {
  const SeriesDetailCover({super.key, required this.seriesId});

  final String seriesId;

  static const double _aspectRatio = 2 / 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SeriesCoverSource> async = ref.watch(
      seriesCoverSourceProvider(seriesId),
    );
    final Widget cover = async.when(
      loading: () => _cover(null, ComicCoverPlaceholderKind.loading),
      error: (_, _) => _cover(null, ComicCoverPlaceholderKind.error),
      data: (SeriesCoverSource source) => switch (source) {
        SeriesCoverCustomThumbnail(:final thumbnail) => _cover(
          ComicCoverSource.bytes(thumbnail),
          ComicCoverPlaceholderKind.loading,
        ),
        SeriesCoverFallbackComic(:final comicId) =>
          ref.watch(seriesCoverSlotProvider)(
            SeriesCoverSlotArgs(
              seriesId: seriesId,
              fallbackComicId: comicId,
              priority: ThumbnailPriority.critical.index,
            ),
          ),
        SeriesCoverMissing() => _cover(null, ComicCoverPlaceholderKind.noCover),
      },
    );

    return CatalogCoverHero.wrap(
      tag: CatalogCoverHero.seriesTag(seriesId),
      child: cover,
    );
  }

  Widget _cover(
    ComicCoverSource? coverDisplay,
    ComicCoverPlaceholderKind kind,
  ) {
    final Widget placeholder = ComicCoverPlaceholder(
      variant: ComicCoverPlaceholderVariant.detail,
      kind: kind,
    );
    return AdaptiveComicCover(
      coverDisplay: coverDisplay,
      containerAspectRatio: _aspectRatio,
      showShadow: false,
      placeholder: placeholder,
      errorPlaceholder: placeholder,
    );
  }
}
