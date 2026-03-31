import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:hentai_library/domain/mappers/comic_mapper.dart';

void main() {
  group('LibraryComicMapper', () {
    test('comicIdFromPath is stable for normalized paths', () {
      final m = ComicMapper();
      final a = m.comicIdFromPath(r'E:\a\b\c\');
      final b = m.comicIdFromPath(r'E:/a/b/c');
      expect(a, b);
    });

    test('fromParsedResource maps meta and type', () {
      final m = ComicMapper();
      final r = (
        path: '/x/y.zip',
        type: ResourceType.zip,
        meta: (title: 'T', authors: <String>['A']),
      );
      final comic = m.fromParsedResource(r);
      expect(comic.path, '/x/y.zip');
      expect(comic.resourceType, ResourceType.zip);
      expect(comic.title, 'T');
      expect(comic.authors, ['A']);
      expect(comic.comicId, isNotEmpty);
    });
  });
}
