import 'package:flutter/widgets.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_format.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_view_object.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

/// 将领域 [Comic] 映射为 MD3E 漫画详情数据（纯函数，便于测试）。
///
/// 格式化文本（日期、页数）由调用方按 [BuildContext] 计算后传入，映射本身不依赖 context。
ComicDetailViewObject comicDetailEntry({
  required Comic comic,
  required Widget cover,
  required int? pageCount,
  required String? publishedLabel,
  required String? addedAtLabel,
  required String? updatedAtLabel,
  required List<String> seriesTitles,
  required int seriesCurrentIndex,
  required bool showSeriesNav,
}) {
  return ComicDetailViewObject(
    title: comic.title,
    description: comic.description,
    pageCount: pageCount == null || pageCount == 0 ? null : pageCount,
    publishedLabel: publishedLabel,
    parodies: comic.parodies,
    authors: comic.authors,
    characters: comic.characters,
    tags: <String>[for (final tag in comic.tags) tag.name],
    resourceFormat: comic.resourceType.name.toUpperCase(),
    resourceSizeLabel: formatComicResourceSize(comic.resourceSize),
    resourcePath: comic.path,
    addedAtLabel: addedAtLabel,
    updatedAtLabel: updatedAtLabel,
    cover: cover,
    showSeriesNav: showSeriesNav,
    seriesCatalog: seriesTitles,
    seriesCurrentIndex: seriesCurrentIndex,
    showAgeRestrictionChip: comic.contentRating == ContentRating.r18,
  );
}
