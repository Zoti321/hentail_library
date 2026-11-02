import 'package:flutter/widgets.dart';
import 'package:hentai_library/features/library_browse/presentation/comic/views/comic_detail_md3e/comic_detail_format.dart';
import 'package:hentai_library/features/library_browse/presentation/comic/views/comic_detail_md3e/comic_detail_page_entry.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

/// 将领域 [Comic] 映射为 MD3E 漫画详情数据（纯函数，便于测试）。
///
/// 格式化文本（日期、页数）由调用方按 [BuildContext] 计算后传入，映射本身不依赖 context。
Md3eComicDetailEntry comicDetailMd3eEntry({
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
  return Md3eComicDetailEntry(
    title: comic.title,
    description: comic.description,
    pageCount: pageCount == null || pageCount == 0 ? null : pageCount,
    publishedLabel: publishedLabel,
    parodies: comic.parodies,
    authors: <String>[for (final author in comic.authors) author.name],
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
