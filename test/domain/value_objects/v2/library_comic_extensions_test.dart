import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:hentai_library/domain/entity/comic/library_comic.dart';
import 'package:hentai_library/domain/entity/comic/library_tag.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/domain/extensions/library_comic_extensions.dart';
import 'package:hentai_library/domain/value_objects/library_comic_filter.dart';
import 'package:hentai_library/domain/value_objects/library_tag_pick.dart';
import 'package:hentai_library/domain/value_objects/library_comic_sort_option.dart';

void main() {
  group('LibraryComic extensions', () {
    test('sortedWith does not mutate original list', () {
      final a = LibraryComic(
        comicId: '1',
        path: '/a',
        resourceType: ResourceType.dir,
        title: 'b',
      );
      final b = LibraryComic(
        comicId: '2',
        path: '/b',
        resourceType: ResourceType.dir,
        title: 'a',
      );
      final list = [a, b];
      final sorted = list.sortedWith(LibraryComicSortOption());

      expect(list.first.title, 'b'); // 原列表不变
      expect(sorted.first.title, 'a');
    });

    test('applyFilter delegates to filter.matches', () {
      final t = LibraryTag(name: 'x');
      final a = LibraryComic(
        comicId: '1',
        path: '/a',
        resourceType: ResourceType.dir,
        title: 'a',
        contentRating: ContentRating.safe,
        tags: [t],
      );
      final b = LibraryComic(
        comicId: '2',
        path: '/b',
        resourceType: ResourceType.zip,
        title: 'b',
        contentRating: ContentRating.safe,
        tags: [],
      );
      final list = [a, b];
      final filtered = list.applyFilter(
        LibraryComicFilter(tagsAll: {LibraryTagPick(name: 'x')}),
      );
      expect(filtered.length, 1);
      expect(filtered.first.comicId, '1');
    });
  });
}
