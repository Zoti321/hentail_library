import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/thumbnail/series_cover_source.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_image.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_state.dart';
import 'package:hentai_library/ui/core/widgets/element/image/adaptive_comic_cover.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_placeholder.dart';
import 'package:hentai_library/ui/providers.dart';

class SeriesDetailCover extends ConsumerWidget {
  const SeriesDetailCover({super.key, required this.series});

  final Series series;

  static const double containerAspectRatio = 2 / 3;
  static const double _cornerRadius = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SeriesCoverSource> async = ref.watch(
      seriesCoverSourceProvider(series.id),
    );

    return async.when(
      loading: () => _buildAdaptive(
        coverDisplay: null,
        placeholderKind: ComicCoverPlaceholderKind.loading,
      ),
      error: (_, _) => _buildAdaptive(
        coverDisplay: null,
        placeholderKind: ComicCoverPlaceholderKind.error,
      ),
      data: (SeriesCoverSource source) => switch (source) {
        SeriesCoverCustomThumbnail(:final thumbnail) => _buildAdaptive(
          coverDisplay: ComicCoverImage.bytes(thumbnail),
          placeholderKind: ComicCoverPlaceholderKind.loading,
        ),
        SeriesCoverFallbackComic(:final comicId) => _buildFallbackComicCover(
          ref,
          comicId,
        ),
        SeriesCoverMissing() => _buildAdaptive(
          coverDisplay: null,
          placeholderKind: ComicCoverPlaceholderKind.noCover,
        ),
      },
    );
  }

  Widget _buildFallbackComicCover(WidgetRef ref, String coverComicId) {
    ref
        .read(comicCoverProvider(coverComicId).notifier)
        .ensureLoaded(priority: ThumbnailPriority.critical);
    final ComicCoverState state = ref.watch(comicCoverProvider(coverComicId));

    return AdaptiveComicCover(
      coverDisplay: comicCoverImageOrPrevious(state),
      containerAspectRatio: containerAspectRatio,
      backgroundColor: Colors.white,
      showShadow: true,
      placeholder: _buildPlaceholder(state),
      errorPlaceholder: _buildPlaceholder(state),
      clipBorderRadius: BorderRadius.circular(_cornerRadius),
      onDecodeError: () {
        ref.read(comicCoverProvider(coverComicId).notifier).markDecodeError();
      },
    );
  }

  Widget _buildAdaptive({
    required ComicCoverImage? coverDisplay,
    required ComicCoverPlaceholderKind placeholderKind,
  }) {
    return AdaptiveComicCover(
      coverDisplay: coverDisplay,
      containerAspectRatio: containerAspectRatio,
      backgroundColor: Colors.white,
      showShadow: true,
      placeholder: ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.detail,
        kind: placeholderKind,
      ),
      errorPlaceholder: ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.detail,
        kind: placeholderKind,
      ),
      clipBorderRadius: BorderRadius.circular(_cornerRadius),
    );
  }

  Widget _buildPlaceholder(ComicCoverState state) {
    return switch (state) {
      ComicCoverError() => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.detail,
        kind: ComicCoverPlaceholderKind.error,
      ),
      ComicCoverNoCover() => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.detail,
        kind: ComicCoverPlaceholderKind.noCover,
      ),
      _ => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.detail,
        kind: ComicCoverPlaceholderKind.loading,
      ),
    };
  }
}
