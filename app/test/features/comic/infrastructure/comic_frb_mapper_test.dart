import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic/infrastructure/comic_frb_mapper.dart';
import 'package:hentai_library/features/comic/domain/value_objects/library_comic_filter.dart';
import 'package:hentai_library/features/comic/domain/value_objects/library_comic_sort_option.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust;

void main() {
  test('mapSortOption forwards field and descending to Rust DTO', () {
    final LibraryComicSortOption sortOption = LibraryComicSortOption(
      field: LibraryComicSortField.pageCount,
      descending: true,
    );

    final rust.ComicSortOptionDto mapped = mapSortOption(sortOption);

    expect(mapped.field, rust.ComicSortFieldDto.pageCount);
    expect(mapped.descending, isTrue);
  });

  test(
    'mapLibraryFilter maps language parody and character all/any/exclude',
    () {
      final LibraryComicFilter filter = LibraryComicFilter(
        languages: <String>{'Chinese', ' Japanese '},
        parodiesAll: <String>{'Fate'},
        parodiesAny: <String>{'Naruto'},
        parodiesExclude: <String>{'Original'},
        charactersAny: <String>{'Sakura'},
        charactersExclude: <String>{'Extra'},
      );

      final rust.ComicFilterDto mapped = mapLibraryFilter(filter);

      expect(
        mapped.languages,
        unorderedEquals(<String>['chinese', 'japanese']),
      );
      expect(mapped.parodiesAll, unorderedEquals(<String>['fate']));
      expect(mapped.parodiesAny, unorderedEquals(<String>['naruto']));
      expect(mapped.parodiesExclude, unorderedEquals(<String>['original']));
      expect(mapped.charactersAny, unorderedEquals(<String>['sakura']));
      expect(mapped.charactersExclude, unorderedEquals(<String>['extra']));
    },
  );

  test('mapLibraryFilter forwards needs metadata flag', () {
    expect(mapLibraryFilter(LibraryComicFilter()).needsMetadataOnly, isFalse);
    expect(
      mapLibraryFilter(LibraryComicFilter(needsMetadataOnly: true))
          .needsMetadataOnly,
      isTrue,
    );
  });

  test('unrestrictedListFilter keeps needs metadata off', () {
    expect(unrestrictedListFilter().needsMetadataOnly, isFalse);
  });

  test('mapPagedResult maps page envelope and items', () {
    final rust.PagedComicResultDto page = rust.PagedComicResultDto(
      items: <rust.ComicDto>[_comicDto()],
      totalCount: PlatformInt64Util.from(41),
      page: 2,
      pageSize: 20,
    );

    final PagedResult<Comic> mapped = mapPagedResult(page);

    expect(mapped.items.single.comicId, 'c1');
    expect(mapped.totalCount, 41);
    expect(mapped.page, 2);
    expect(mapped.pageSize, 20);
  });
}

rust.ComicDto _comicDto({
  String? description,
  PlatformInt64? publishedAt,
  PlatformInt64? lastReadTimeMs,
}) {
  return rust.ComicDto(
    comicId: 'c1',
    path: '/lib/c1.cbz',
    resourceType: 'cbz',
    resourceSize: PlatformInt64Util.from(2048),
    createdAt: PlatformInt64Util.from(1700000000000),
    lastUpdatedAt: PlatformInt64Util.from(1700000600000),
    title: 'Title',
    contentRating: 'r18',
    pageCount: 12,
    description: description,
    publishedAt: publishedAt,
    lastReadTimeMs: lastReadTimeMs,
    authors: const <rust.ComicAuthorDto>[
      rust.ComicAuthorDto(id: 1, name: 'Alice'),
      rust.ComicAuthorDto(id: 2, name: 'Bob'),
    ],
    tags: const <String>['tag-a'],
    languages: const <String>['zh'],
    parodies: const <String>['p'],
    characters: const <String>['c'],
    locks: const rust.ComicMetaLocksDto(
      title: true,
      description: false,
      publishedAt: true,
      contentRating: false,
      authors: true,
      tags: false,
      languages: true,
      parodies: false,
      characters: true,
    ),
    libraryId: 'lib-1',
  );
}
