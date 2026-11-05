import 'package:flutter/material.dart';
import 'package:hentai_library/features/comic/public/di/comic_cover_providers.dart';
import 'package:hentai_library/features/series/di/series_cover_providers.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/thumbnail/series_cover_source.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_source.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_state.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/adaptive_comic_cover.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_placeholder.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// MD3E 系列详情封面：沿用系列封面来源（[seriesCoverSourceProvider]），填充到 MD3E 封面容器内。
class SeriesDetailMd3eCover extends ConsumerWidget {
  const SeriesDetailMd3eCover({super.key, required this.seriesId});

  final String seriesId;

  static const double _aspectRatio = 2 / 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SeriesCoverSource> async = ref.watch(
      seriesCoverSourceProvider(seriesId),
    );
    return async.when(
      loading: () => _cover(null, ComicCoverPlaceholderKind.loading),
      error: (_, _) => _cover(null, ComicCoverPlaceholderKind.error),
      data: (SeriesCoverSource source) => switch (source) {
        SeriesCoverCustomThumbnail(:final thumbnail) => _cover(
          ComicCoverSource.bytes(thumbnail),
          ComicCoverPlaceholderKind.loading,
        ),
        SeriesCoverFallbackComic(:final comicId) => _fallbackComicCover(
          ref,
          comicId,
        ),
        SeriesCoverMissing() => _cover(null, ComicCoverPlaceholderKind.noCover),
      },
    );
  }

  Widget _fallbackComicCover(WidgetRef ref, String coverComicId) {
    ref
        .read(comicCoverProvider(coverComicId).notifier)
        .ensureLoaded(priority: ThumbnailPriority.critical);
    final ComicCoverState state = ref.watch(comicCoverProvider(coverComicId));
    return _cover(
      comicCoverSourceOrPrevious(state),
      ComicCoverPlaceholderKind.loading,
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
      backgroundColor: Colors.white,
      showShadow: false,
      placeholder: placeholder,
      errorPlaceholder: placeholder,
    );
  }
}
