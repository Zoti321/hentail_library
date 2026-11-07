import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hentai_library/features/comic/public/di/comic_cover_providers.dart';
import 'package:hentai_library/features/comic/public/ui/comic_cover_content.dart';
import 'package:hentai_library/features/series/public/di/series_cover_providers.dart';
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
    this.coverViewportScope,
    this.enableHero = true,
  });

  final String seriesId;
  final ThumbnailPriority priority;
  final int? gridIndex;
  final String? coverViewportScope;

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
          _SeriesCustomCoverImage(thumbnail: thumbnail),
        SeriesCoverFallbackComic(:final comicId) => ComicCoverContent(
          comicId: comicId,
          priority: priority,
          gridIndex: gridIndex,
          coverViewportScope: coverViewportScope,
          // 外层 Series 已挂 CoverViewportSensor。
          attachViewportSensor: false,
          // 外层已有系列 Hero，避免嵌套 comic Hero。
          enableHero: false,
        ),
        SeriesCoverMissing() => const ComicCoverPlaceholder(
          variant: ComicCoverPlaceholderVariant.card,
          kind: ComicCoverPlaceholderKind.noCover,
        ),
      },
    );

    Widget result = CatalogCoverHero.wrap(
      tag: CatalogCoverHero.seriesTag(seriesId),
      enabled: enableHero,
      child: cover,
    );

    final int? index = gridIndex;
    final String? scope = coverViewportScope;
    if (index != null && scope != null) {
      result = CoverViewportSensor(scope: scope, index: index, child: result);
    }
    return result;
  }
}

class _SeriesCustomCoverImage extends StatefulWidget {
  const _SeriesCustomCoverImage({required this.thumbnail});

  final Uint8List thumbnail;

  @override
  State<_SeriesCustomCoverImage> createState() =>
      _SeriesCustomCoverImageState();
}

class _SeriesCustomCoverImageState extends State<_SeriesCustomCoverImage> {
  bool _decodeFailed = false;

  @override
  void didUpdateWidget(covariant _SeriesCustomCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.thumbnail, widget.thumbnail)) {
      _decodeFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_decodeFailed) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _decodeFailed = false),
        child: const ComicCoverPlaceholder(
          variant: ComicCoverPlaceholderVariant.card,
          kind: ComicCoverPlaceholderKind.error,
        ),
      );
    }
    return CardLetterboxedCoverImage(
      cover: ComicCoverSource.bytes(widget.thumbnail),
      onDecodeError: () {
        if (!_decodeFailed) {
          setState(() => _decodeFailed = true);
        }
      },
    );
  }
}
