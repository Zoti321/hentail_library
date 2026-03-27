import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/comic/v2/resource_types.dart';
import 'package:hentai_library/domain/entity/v2/library_comic.dart';
import 'package:hentai_library/domain/value_objects/v2/library_comic_sort_option.dart';

void main() {
  LibraryComic c(String title) => LibraryComic(
        comicId: title,
        path: '/$title',
        resourceType: ResourceType.dir,
        title: title,
      );

  group('LibraryComicSortOption.compare', () {
    test('sorts by title ascending', () {
      final opt = LibraryComicSortOption(field: LibraryComicSortField.title);
      expect(opt.compare(c('a'), c('b')), lessThan(0));
    });

    test('sorts by title descending', () {
      final opt = LibraryComicSortOption(
        field: LibraryComicSortField.title,
        descending: true,
      );
      expect(opt.compare(c('a'), c('b')), greaterThan(0));
    });
  });
}

