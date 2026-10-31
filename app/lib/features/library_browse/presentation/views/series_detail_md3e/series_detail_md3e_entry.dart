import 'package:flutter/widgets.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_comic_page_item.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_comics_metadata.dart';

/// 将领域 [Series] 与当前页漫画映射为 MD3E 系列详情数据（纯函数，便于测试）。
///
/// [pageItems] 仅为当前页（服务端分页）；页码与页大小由页面层通过受控参数传入。
Md3eSeriesDetailEntry seriesDetailMd3eEntry({
  required Series series,
  required Widget cover,
  required SeriesComicsMetadata? metadata,
  required List<SeriesComicPageItem> pageItems,
  required int page,
  required int pageSize,
  Widget Function(String comicId)? comicCoverBuilder,
}) {
  final bool hasMetadata =
      metadata != null &&
      (metadata.authors.isNotEmpty ||
          metadata.tags.isNotEmpty ||
          metadata.parodies.isNotEmpty ||
          metadata.characters.isNotEmpty);
  return Md3eSeriesDetailEntry(
    title: series.name,
    cover: cover,
    serializationStatus: _mapStatus(series.serializationStatus),
    languages: metadata?.languages ?? const <String>[],
    showAgeRestrictionChip: metadata?.hasR18 ?? false,
    volumeCurrent: series.items.length,
    volumeTotal: series.totalCount,
    showMetadataBlock: hasMetadata,
    parodies: metadata?.parodies ?? const <String>[],
    authors: metadata?.authors ?? const <String>[],
    characters: metadata?.characters ?? const <String>[],
    tags: metadata?.tags ?? const <String>[],
    comics: <Md3eSeriesDetailComicItem>[
      for (final SeriesComicPageItem item in pageItems)
        Md3eSeriesDetailComicItem(
          title: item.comic.title,
          pageCount: item.comic.pageCount,
          cover: comicCoverBuilder?.call(item.comic.comicId),
        ),
    ],
    initialPage: page,
    initialPageSize: pageSize,
  );
}

Md3eSeriesSerializationStatus _mapStatus(SerializationStatus status) {
  return switch (status) {
    SerializationStatus.unknown => Md3eSeriesSerializationStatus.unknown,
    SerializationStatus.ongoing => Md3eSeriesSerializationStatus.ongoing,
    SerializationStatus.ended => Md3eSeriesSerializationStatus.ended,
    SerializationStatus.hiatus => Md3eSeriesSerializationStatus.hiatus,
  };
}
