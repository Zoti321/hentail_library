import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/entity/entities.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/domain/value_objects/comic_sort_option.dart';

void main() {
  Comic comic({
    String id = '1',
    String title = 'A',
    DateTime? firstPublishedAt,
    DateTime? lastUpdatedAt,
    int? totalViews,
    int chapterCount = 1,
  }) {
    return Comic(
      id: id,
      title: title,
      chapters: List.generate(
        chapterCount,
        (i) => Chapter(id: 'c$i', imageDir: '/d', pageCount: 1),
      ),
      firstPublishedAt: firstPublishedAt,
      lastUpdatedAt: lastUpdatedAt,
      totalViews: totalViews,
    );
  }

  group('ComicSortOption.compare', () {
    test('title: ascending order', () {
      final opt = ComicSortOption(field: ComicSortType.title, descending: false);
      final a = comic(title: 'A');
      final b = comic(title: 'B');
      expect(opt.compare(a, b), lessThan(0));
      expect(opt.compare(b, a), greaterThan(0));
      expect(opt.compare(a, comic(title: 'A')), 0);
    });

    test('title: descending order', () {
      final opt = ComicSortOption(field: ComicSortType.title, descending: true);
      final a = comic(title: 'A');
      final b = comic(title: 'B');
      expect(opt.compare(a, b), greaterThan(0));
      expect(opt.compare(b, a), lessThan(0));
    });

    test('lastUpdated: nulls and order', () {
      final opt = ComicSortOption(field: ComicSortType.lastUpdated, descending: false);
      final d1 = DateTime(2024, 1, 1);
      final d2 = DateTime(2024, 6, 1);
      expect(opt.compare(comic(lastUpdatedAt: d1), comic(lastUpdatedAt: d2)), lessThan(0));
      expect(opt.compare(comic(lastUpdatedAt: null), comic(lastUpdatedAt: d1)), greaterThan(0));
      expect(opt.compare(comic(lastUpdatedAt: d1), comic(lastUpdatedAt: null)), lessThan(0));
      expect(opt.compare(comic(lastUpdatedAt: null), comic(lastUpdatedAt: null)), 0);
    });

    test('firstPublished: ascending', () {
      final opt = ComicSortOption(field: ComicSortType.firstPublished, descending: false);
      final d1 = DateTime(2023, 1, 1);
      final d2 = DateTime(2024, 1, 1);
      expect(opt.compare(comic(firstPublishedAt: d1), comic(firstPublishedAt: d2)), lessThan(0));
    });

    test('totalViews: ascending and descending', () {
      final asc = ComicSortOption(field: ComicSortType.totalViews, descending: false);
      expect(asc.compare(comic(totalViews: 10), comic(totalViews: 20)), lessThan(0));
      final desc = ComicSortOption(field: ComicSortType.totalViews, descending: true);
      expect(desc.compare(comic(totalViews: 10), comic(totalViews: 20)), greaterThan(0));
    });

    test('totalViews: null treated as 0', () {
      final opt = ComicSortOption(field: ComicSortType.totalViews, descending: false);
      expect(opt.compare(comic(totalViews: null), comic(totalViews: 1)), lessThan(0));
    });
  });
}
