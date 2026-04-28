import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/model/enums.dart';
import 'package:hentai_library/model/value_objects/comic_filter.dart';

void main() {
  test(
    'matches excludes comic ids listed in comicIdsExcludedBySeriesMembership',
    () {
      final Comic inSeries = Comic(
        comicId: 'a',
        path: '/x',
        resourceType: ResourceType.dir,
        title: 'T',
      );
      final Comic standalone = Comic(
        comicId: 'b',
        path: '/y',
        resourceType: ResourceType.dir,
        title: 'U',
      );
      final LibraryComicFilter filter = LibraryComicFilter(
        showR18: true,
        comicIdsExcludedBySeriesMembership: <String>{'a'},
      );
      expect(filter.matches(inSeries), isFalse);
      expect(filter.matches(standalone), isTrue);
    },
  );
}
