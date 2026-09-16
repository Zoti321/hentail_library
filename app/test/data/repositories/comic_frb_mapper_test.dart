import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/repositories/comic_frb_mapper.dart';
import 'package:hentai_library/domain/library/library_comic_filter.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
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

  test('mapLibraryFilter maps language parody and character include sets', () {
    final LibraryComicFilter filter = LibraryComicFilter(
      languages: <String>{'Chinese', ' Japanese '},
      parodies: <String>{'Naruto'},
      characters: <String>{'Sakura'},
    );

    final rust.ComicFilterDto mapped = mapLibraryFilter(filter);

    expect(mapped.languages, unorderedEquals(<String>['chinese', 'japanese']));
    expect(mapped.parodies, unorderedEquals(<String>['naruto']));
    expect(mapped.characters, unorderedEquals(<String>['sakura']));
  });

  test('mapRustComic maps identity facets UTC timestamps and locks', () {
    final rust.ComicDto dto = _comicDto(
      description: '简介',
      publishedAt: PlatformInt64Util.from(1600000000000),
      lastReadTimeMs: PlatformInt64Util.from(1700000900000),
    );

    final Comic mapped = mapRustComic(dto);

    expect(mapped.comicId, 'c1');
    expect(mapped.path, '/lib/c1.cbz');
    expect(mapped.resourceType, ResourceType.cbz);
    expect(mapped.resourceSize, 2048);
    expect(mapped.title, 'Title');
    expect(mapped.contentRating, ContentRating.r18);
    expect(mapped.pageCount, 12);
    expect(mapped.description, '简介');
    expect(mapped.authors.map((Author a) => a.name), <String>['Alice', 'Bob']);
    expect(mapped.tags.map((Tag t) => t.name), <String>['tag-a']);
    expect(mapped.languages, <String>['zh']);
    expect(mapped.parodies, <String>['p']);
    expect(mapped.characters, <String>['c']);

    expect(
      mapped.createdAt,
      DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
    );
    expect(mapped.createdAt.isUtc, isTrue);
    expect(
      mapped.lastUpdatedAt,
      DateTime.fromMillisecondsSinceEpoch(1700000600000, isUtc: true),
    );
    expect(
      mapped.publishedAt,
      DateTime.fromMillisecondsSinceEpoch(1600000000000, isUtc: true),
    );
    expect(
      mapped.lastReadTime,
      DateTime.fromMillisecondsSinceEpoch(1700000900000, isUtc: true),
    );

    expect(mapped.locks.title, isTrue);
    expect(mapped.locks.description, isFalse);
    expect(mapped.locks.publishedAt, isTrue);
    expect(mapped.locks.contentRating, isFalse);
    expect(mapped.locks.authors, isTrue);
    expect(mapped.locks.tags, isFalse);
    expect(mapped.locks.languages, isTrue);
    expect(mapped.locks.parodies, isFalse);
    expect(mapped.locks.characters, isTrue);
  });

  test('mapRustComic keeps absent optional metadata null', () {
    final Comic mapped = mapRustComic(_comicDto());

    expect(mapped.description, isNull);
    expect(mapped.publishedAt, isNull);
    expect(mapped.lastReadTime, isNull);
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
    authors: const <String>['Alice', 'Bob'],
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
