import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/repositories/comic_frb_mapper.dart';
import 'package:hentai_library/domain/library/library_comic_filter.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
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
}
