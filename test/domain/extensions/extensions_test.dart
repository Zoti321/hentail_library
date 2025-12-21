import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/entity/entities.dart';
import 'package:hentai_library/domain/extensions/extensions.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/domain/value_objects/comic_filter.dart';
import 'package:hentai_library/domain/value_objects/comic_sort_option.dart';

void main() {
  Comic comic({
    String id = '1',
    String title = 'A',
    DateTime? lastUpdatedAt,
    int? totalViews,
    int chapterCount = 1,
    bool isR18 = false,
  }) {
    return Comic(
      id: id,
      title: title,
      isR18: isR18,
      chapters: List.generate(
        chapterCount,
        (i) => Chapter(id: 'c$i', imageDir: '/d', pageCount: 1),
      ),
      lastUpdatedAt: lastUpdatedAt,
      totalViews: totalViews,
    );
  }

  group('ComicSortX.sortedWith', () {
    test('sorts by option and does not mutate original list', () {
      final list = [
        comic(id: '2', title: 'B'),
        comic(id: '1', title: 'A'),
      ];
      final option = ComicSortOption(field: ComicSortType.title, descending: false);
      final sorted = list.sortedWith(option);
      expect(sorted.map((c) => c.title), ['A', 'B']);
      expect(list.map((c) => c.title), ['B', 'A']);
    });

    test('descending reverses order', () {
      final list = [
        comic(title: 'A'),
        comic(title: 'B'),
      ];
      final option = ComicSortOption(field: ComicSortType.title, descending: true);
      final sorted = list.sortedWith(option);
      expect(sorted.map((c) => c.title), ['B', 'A']);
    });
  });

  group('ComicFilterX.applyFilter', () {
    test('delegates to filter.matches', () {
      final list = [
        comic(title: 'Match'),
        comic(title: 'Other'),
      ];
      final filter = ComicFilter(query: 'Match');
      final result = list.applyFilter(filter);
      expect(result.length, 1);
      expect(result.single.title, 'Match');
    });

    test('empty list returns empty', () {
      final filter = ComicFilter(query: 'x');
      expect(<Comic>[].applyFilter(filter), isEmpty);
    });

    test('filter with showR18 false excludes R18', () {
      final list = [
        comic(id: '1', title: 'A', isR18: false),
        comic(id: '2', title: 'B', isR18: true),
      ];
      final filter = ComicFilter(showR18: false);
      final result = list.applyFilter(filter);
      expect(result.length, 1);
      expect(result.single.id, '1');
    });
  });
}
