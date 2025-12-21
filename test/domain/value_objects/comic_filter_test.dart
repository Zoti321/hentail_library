import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/entity/entities.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/domain/value_objects/comic_filter.dart';

void main() {
  Comic comic({
    String id = '1',
    String title = 'Test Comic',
    String? description,
    bool isR18 = false,
    String? status,
    int totalChapterCount = 1,
    List<CategoryTag>? tags,
  }) {
    final chapters = List.generate(
      totalChapterCount,
      (i) => Chapter(id: 'ch-$i', imageDir: '/dir/$i', pageCount: 1),
    );
    return Comic(
      id: id,
      title: title,
      description: description,
      isR18: isR18,
      status: status,
      tags: tags ?? [],
      chapters: chapters,
    );
  }

  group('ComicFilter.matches', () {
    test('empty filter matches any comic', () {
      final filter = ComicFilter();
      expect(filter.matches(comic()), isTrue);
      expect(filter.matches(comic(title: 'Other')), isTrue);
    });

    test('query: matches title', () {
      final filter = ComicFilter(query: 'Test');
      expect(filter.matches(comic(title: 'Test Comic')), isTrue);
      expect(filter.matches(comic(title: 'Test')), isTrue);
      expect(filter.matches(comic(title: 'Other')), isFalse);
    });

    test('query: matches description when title does not', () {
      final filter = ComicFilter(query: 'desc');
      expect(
        filter.matches(comic(title: 'X', description: 'has desc here')),
        isTrue,
      );
      expect(
        filter.matches(comic(title: 'X', description: 'other')),
        isFalse,
      );
    });

    test('query: empty string does not filter', () {
      final filter = ComicFilter(query: '');
      expect(filter.matches(comic()), isTrue);
    });

    test('query: null does not filter', () {
      final filter = ComicFilter(query: null);
      expect(filter.matches(comic()), isTrue);
    });

    test('showR18 false excludes R18 comic', () {
      final filter = ComicFilter(showR18: false);
      expect(filter.matches(comic(isR18: false)), isTrue);
      expect(filter.matches(comic(isR18: true)), isFalse);
    });

    test('showR18 true includes R18 comic', () {
      final filter = ComicFilter(showR18: true);
      expect(filter.matches(comic(isR18: true)), isTrue);
    });

    test('tags: comic must contain all selected tags', () {
      final tagA = CategoryTag(name: 'A', type: CategoryTagType.tag);
      final tagB = CategoryTag(name: 'B', type: CategoryTagType.tag);
      final filter = ComicFilter(tags: {tagA, tagB});
      expect(
        filter.matches(comic(tags: [tagA, tagB])),
        isTrue,
      );
      expect(
        filter.matches(comic(tags: [tagA])),
        isFalse,
      );
      expect(
        filter.matches(comic(tags: [])),
        isFalse,
      );
    });

    test('tags: empty set does not filter', () {
      final filter = ComicFilter(tags: {});
      expect(filter.matches(comic()), isTrue);
    });

    test('tags: null does not filter', () {
      final filter = ComicFilter(tags: null);
      expect(filter.matches(comic()), isTrue);
    });

    test('status: must match exactly', () {
      final filter = ComicFilter(status: '连载中');
      expect(filter.matches(comic(status: '连载中')), isTrue);
      expect(filter.matches(comic(status: '已完结')), isFalse);
      expect(filter.matches(comic(status: null)), isFalse);
    });

    test('status: null in filter does not filter', () {
      final filter = ComicFilter(status: null);
      expect(filter.matches(comic(status: '连载中')), isTrue);
    });

    test('minChapters: excludes comic with fewer chapters', () {
      final filter = ComicFilter(minChapters: 3);
      expect(filter.matches(comic(totalChapterCount: 3)), isTrue);
      expect(filter.matches(comic(totalChapterCount: 4)), isTrue);
      expect(filter.matches(comic(totalChapterCount: 2)), isFalse);
    });

    test('minChapters: null does not filter', () {
      final filter = ComicFilter(minChapters: null);
      expect(filter.matches(comic(totalChapterCount: 0)), isTrue);
    });
  });
}
