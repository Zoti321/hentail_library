import 'package:hentai_library/data/adapters/reader_frb_mapper.dart';
import 'package:hentai_library/domain/library/library_comic_filter.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/library_tag_pick.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust;

Comic mapRustComic(rust.ComicDto dto) {
  return Comic(
    comicId: dto.comicId,
    path: dto.path,
    resourceType: ResourceType.values.byName(dto.resourceType),
    resourceSize: dto.resourceSize.toInt(),
    createdAt: comicTimestampFromMs(dto.createdAt.toInt()),
    lastUpdatedAt: comicTimestampFromMs(dto.lastUpdatedAt.toInt()),
    title: dto.title,
    authors: dto.authors.map((String n) => Author(name: n)).toList(),
    contentRating: ContentRating.values.byName(dto.contentRating),
    tags: dto.tags.map((String n) => Tag(name: n)).toList(),
    pageCount: dto.pageCount,
    description: dto.description,
    publishedAt: dto.publishedAt == null
        ? null
        : comicTimestampFromMs(dto.publishedAt!.toInt()),
  );
}

rust.ComicFilterDto mapLibraryFilter(LibraryComicFilter filter) {
  return rust.ComicFilterDto(
    showR18: filter.showR18,
    query: filter.query,
    resourceTypes:
        filter.resourceTypes?.map(mapResourceType).toList() ??
        const <String>[],
    contentRatings:
        filter.contentRatings?.map((ContentRating e) => e.name).toList() ??
        const <String>[],
    tagsAll: _mapTagPicks(filter.tagsAll),
    tagsAny: _mapTagPicks(filter.tagsAny),
    tagsExclude: _mapTagPicks(filter.tagsExclude),
    excludeComicsInAnySeries: filter.comicIdsExcludedBySeriesMembership != null,
  );
}

List<String> _mapTagPicks(Set<LibraryTagPick>? picks) {
  if (picks == null || picks.isEmpty) {
    return const <String>[];
  }
  return picks
      .map((LibraryTagPick pick) => pick.name.trim().toLowerCase())
      .where((String name) => name.isNotEmpty)
      .toList();
}

rust.PageRequestDto mapPageRequest(PageRequest request) {
  return rust.PageRequestDto(page: request.page, pageSize: request.pageSize);
}

rust.ComicSortOptionDto mapSortOption(LibraryComicSortOption sortOption) {
  return rust.ComicSortOptionDto(
    field: mapSortField(sortOption.field),
    descending: sortOption.descending,
  );
}

rust.ComicSortFieldDto mapSortField(LibraryComicSortField field) {
  return switch (field) {
    LibraryComicSortField.title => rust.ComicSortFieldDto.title,
    LibraryComicSortField.createdAt => rust.ComicSortFieldDto.createdAt,
    LibraryComicSortField.lastUpdatedAt => rust.ComicSortFieldDto.lastUpdatedAt,
    LibraryComicSortField.publishedAt => rust.ComicSortFieldDto.publishedAt,
    LibraryComicSortField.readAt => rust.ComicSortFieldDto.readAt,
    LibraryComicSortField.fileSize => rust.ComicSortFieldDto.fileSize,
    LibraryComicSortField.pageCount => rust.ComicSortFieldDto.pageCount,
  };
}

PagedResult<Comic> mapPagedResult(rust.PagedComicResultDto page) {
  return PagedResult<Comic>(
    items: page.items.map(mapRustComic).toList(),
    totalCount: page.totalCount.toInt(),
    page: page.page,
    pageSize: page.pageSize,
  );
}

rust.ComicFilterDto unrestrictedListFilter() {
  return const rust.ComicFilterDto(
    showR18: true,
    resourceTypes: <String>[],
    contentRatings: <String>[],
    tagsAll: <String>[],
    tagsAny: <String>[],
    tagsExclude: <String>[],
    excludeComicsInAnySeries: false,
  );
}
