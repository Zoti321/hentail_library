import 'package:flutter/material.dart';
import 'package:hentai_library/features/series/public/di/series_cover_providers.dart';
import 'package:hentai_library/features/comic/public/ui/comic_cover_content.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/thumbnail/series_cover_source.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_source.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/catalog_cover_hero.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/card_letterboxed_cover_image.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_placeholder.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 系列封面：优先自定义系列缩略图，否则回退到成员漫画封面。
class SeriesCoverContent extends ConsumerWidget {
  const SeriesCoverContent({
    super.key,
    required this.seriesId,
    this.priority = ThumbnailPriority.high,
    this.gridIndex,
    this.enableHero = true,
  });

  final String seriesId;
  final ThumbnailPriority priority;
  final int? gridIndex;

  /// 为 false 时不包系列 [Hero]。
  final bool enableHero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SeriesCoverSource> async = ref.watch(
      seriesCoverSourceProvider(seriesId),
    );
    final Widget cover = async.when(
      loading: () => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.card,
        kind: ComicCoverPlaceholderKind.loading,
      ),
      error: (_, _) => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.card,
        kind: ComicCoverPlaceholderKind.error,
      ),
      data: (SeriesCoverSource source) => switch (source) {
        SeriesCoverCustomThumbnail(:final thumbnail) =>
          CardLetterboxedCoverImage(cover: ComicCoverSource.bytes(thumbnail)),
        SeriesCoverFallbackComic(:final comicId) => ComicCoverContent(
          comicId: comicId,
          priority: priority,
          gridIndex: gridIndex,
          // 外层已有系列 Hero，避免嵌套 comic Hero。
          enableHero: false,
        ),
        SeriesCoverMissing() => const ComicCoverPlaceholder(
          variant: ComicCoverPlaceholderVariant.card,
          kind: ComicCoverPlaceholderKind.noCover,
        ),
      },
    );

    return CatalogCoverHero.wrap(
      tag: CatalogCoverHero.seriesTag(seriesId),
      enabled: enableHero,
      child: cover,
    );
  }
}
