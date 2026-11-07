import 'package:hentai_library/shared/domain/models/resource_type_frb_wire.dart';
import 'package:hentai_library/features/comic/domain/library_comic_filter.dart';
import 'package:hentai_library/features/comic/domain/library_comic_sort_option.dart';
import 'package:hentai_library/shared/data/frb/comic_entity_mapper.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/library_author_pick.dart';
import 'package:hentai_library/shared/domain/models/value_objects/library_tag_pick.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust;

rust.ComicFilterDto mapLibraryFilter(LibraryComicFilter filter) {
  return rust.ComicFilterDto(
    showR18: filter.showR18,
    query: filter.query,
    resourceTypes:
        filter.resourceTypes?.map(mapResourceType).toList() ?? const <String>[],
    contentRatings:
        filter.contentRatings?.map((ContentRating e) => e.name).toList() ??
        const <String>[],
    tagsAll: _mapTagPicks(filter.tagsAll),
    tagsAny: _mapTagPicks(filter.tagsAny),
    tagsExclude: _mapTagPicks(filter.tagsExclude),
    authorsAll: _mapAuthorPicks(filter.authorsAll),
    authorsAny: _mapAuthorPicks(filter.authorsAny),
    authorsExclude: _mapAuthorPicks(filter.authorsExclude),
    languages: _mapStringSet(filter.languages),
    parodies: _mapStringSet(filter.parodies),
    characters: _mapStringSet(filter.characters),
    needsMetadataOnly: filter.needsMetadataOnly,
    libraryId: filter.libraryId,
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

List<String> _mapStringSet(Set<String>? items) {
  if (items == null || items.isEmpty) {
    return const <String>[];
  }
  return items
      .map((String s) => s.trim().toLowerCase())
      .where((String s) => s.isNotEmpty)
      .toList();
}

List<String> _mapAuthorPicks(Set<LibraryAuthorPick>? picks) {
  if (picks == null || picks.isEmpty) {
    return const <String>[];
  }
  return picks.map((LibraryAuthorPick pick) => '${pick.id}').toList();
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
    authorsAll: <String>[],
    authorsAny: <String>[],
    authorsExclude: <String>[],
    languages: <String>[],
    parodies: <String>[],
    characters: <String>[],
    needsMetadataOnly: false,
  );
}
