import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/entity/entities.dart';

void main() {
  group('Comic', () {
    test('totalChapterCount returns chapters.length', () {
      final noChapters = Comic(id: '1', title: 'T', chapters: []);
      expect(noChapters.totalChapterCount, 0);

      final three = Comic(
        id: '1',
        title: 'T',
        chapters: [
          Chapter(id: 'c1', imageDir: '/d1', pageCount: 1),
          Chapter(id: 'c2', imageDir: '/d2', pageCount: 2),
          Chapter(id: 'c3', imageDir: '/d3', pageCount: 3),
        ],
      );
      expect(three.totalChapterCount, 3);
    });

    test('totalPageCount sums chapter pageCount', () {
      final comic = Comic(
        id: '1',
        title: 'T',
        chapters: [
          Chapter(id: 'c1', imageDir: '/d1', pageCount: 5),
          Chapter(id: 'c2', imageDir: '/d2', pageCount: 10),
        ],
      );
      expect(comic.totalPageCount, 15);
    });

    test('totalPageCount is 0 when no chapters', () {
      final comic = Comic(id: '1', title: 'T', chapters: []);
      expect(comic.totalPageCount, 0);
    });
  });
}
