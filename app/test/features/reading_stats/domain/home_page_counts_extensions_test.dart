import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/reading_stats/domain/home_page_counts_extensions.dart';
import 'package:hentai_library/features/reading_stats/domain/home_page_counts.dart';

void main() {
  test('HomePageCounts.isCatalogEmpty', () {
    expect(
      const HomePageCounts(
        comicCount: 0,
        tagCount: 0,
        seriesCount: 0,
        authorCount: 0,
        parodyCount: 0,
        characterCount: 0,
        libraryCount: 1,
      ).isCatalogEmpty,
      isTrue,
    );
    expect(
      const HomePageCounts(
        comicCount: 1,
        tagCount: 0,
        seriesCount: 0,
        authorCount: 0,
        parodyCount: 0,
        characterCount: 0,
        libraryCount: 1,
      ).isCatalogEmpty,
      isFalse,
    );
  });
}
