import 'package:flutter/material.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/thumbnail/series_cover_source.dart';
import 'package:hentai_library/ui/core/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_content.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_placeholder.dart';
import 'package:hentai_library/ui/providers/series_cover_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 系列封面：优先自定义系列缩略图，否则回退到成员漫画封面。
class SeriesCoverContent extends ConsumerWidget {
  const SeriesCoverContent({
    super.key,
    required this.seriesId,
    this.priority = ThumbnailPriority.high,
  });

  final String seriesId;
  final ThumbnailPriority priority;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SeriesCoverSource> async = ref.watch(
      seriesCoverSourceProvider(seriesId),
    );
    return async.when(
      loading: () => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.card,
        kind: ComicCoverPlaceholderKind.loading,
      ),
      error: (_, _) => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.card,
        kind: ComicCoverPlaceholderKind.error,
      ),
      data: (SeriesCoverSource source) => switch (source) {
        SeriesCoverCustomThumbnail(:final thumbnail) => AppComicImage(
          memoryBytes: thumbnail,
          fit: BoxFit.cover,
          placeholder: const ComicCoverPlaceholder(
            variant: ComicCoverPlaceholderVariant.card,
            kind: ComicCoverPlaceholderKind.loading,
          ),
          errorPlaceholder: const ComicCoverPlaceholder(
            variant: ComicCoverPlaceholderVariant.card,
            kind: ComicCoverPlaceholderKind.error,
          ),
        ),
        SeriesCoverFallbackComic(:final comicId) => ComicCoverContent(
          comicId: comicId,
          priority: priority,
        ),
        SeriesCoverMissing() => const ComicCoverPlaceholder(
          variant: ComicCoverPlaceholderVariant.card,
          kind: ComicCoverPlaceholderKind.noCover,
        ),
      },
    );
  }
}
