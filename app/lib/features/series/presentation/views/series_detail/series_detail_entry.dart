import 'package:flutter/widgets.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_comic_page_item.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_comics_metadata.dart';

/// 将领域 [Series] 与当前页漫画映射为 MD3E 系列详情数据（纯函数，便于测试）。
///
/// [pageItems] 仅为当前页（服务端分页）；页码与页大小由页面层通过受控参数传入。
SeriesDetailViewObject seriesDetailEntry({
  required Series series,
  required Widget cover,
  required SeriesComicsMetadata? metadata,
  required List<SeriesComicPageItem> pageItems,
  required int page,
  required int pageSize,
  Widget Function(String comicId, int index)? comicCoverBuilder,
}) {
  final bool hasMetadata =
      metadata != null &&
      (metadata.authors.isNotEmpty ||
          metadata.tags.isNotEmpty ||
          metadata.parodies.isNotEmpty ||
          metadata.characters.isNotEmpty);
  return SeriesDetailViewObject(
    title: series.name,
    cover: cover,
    serializationStatus: _mapStatus(series.serializationStatus),
    languages: metadata?.languages ?? const <String>[],
    showAgeRestrictionChip: metadata?.hasR18 ?? false,
    volumeCurrent: series.items.length,
    volumeTotal: series.totalCount,
    showMetadataBlock: hasMetadata,
    parodies: metadata?.parodies ?? const <String>[],
    authors: metadata?.authors ?? const <AuthorRef>[],
    characters: metadata?.characters ?? const <String>[],
    tags: metadata?.tags ?? const <String>[],
    comics: <SeriesDetailComicItem>[
      for (int index = 0; index < pageItems.length; index++)
        SeriesDetailComicItem(
          title: pageItems[index].comic.title,
          pageCount: pageItems[index].comic.pageCount,
          comic: pageItems[index].comic,
          cover: comicCoverBuilder?.call(pageItems[index].comic.comicId, index),
        ),
    ],
    initialPage: page,
    initialPageSize: pageSize,
  );
}

SeriesSerializationStatus _mapStatus(SerializationStatus status) {
  return switch (status) {
    SerializationStatus.unknown => SeriesSerializationStatus.unknown,
    SerializationStatus.ongoing => SeriesSerializationStatus.ongoing,
    SerializationStatus.ended => SeriesSerializationStatus.ended,
    SerializationStatus.hiatus => SeriesSerializationStatus.hiatus,
  };
}
