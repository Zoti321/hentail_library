import 'package:hentai_library/features/library_browse/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public barrel exports ports, factories, pages, cover UI, and bootstrap hooks', () {
    expect(ComicLookupRepository, isNotNull);
    expect(ComicDetailReturnSeriesPort, isNotNull);
      expect(resolveComicTitleForDisplay, isNotNull);
    expect(LibraryAgeRestrictionFilter, isNotNull);
    expect(createAuthorDetailPort, isNotNull);
    expect(createComicDetailReturnSeriesPort, isNotNull);
    expect(createComicRepository, isNotNull);
    expect(createComicCatalogRepository, isNotNull);
    expect(createComicUserMetadataRepository, isNotNull);
    expect(createComicThumbnailRepository, isNotNull);
    expect(createSeriesRepository, isNotNull);
    expect(comicCoverProvider, isNotNull);
    expect(seriesCoverSourceProvider, isNotNull);
    expect(ComicCoverContent, isNotNull);
    expect(SeriesCoverContent, isNotNull);
    expect(LibraryMd3ePage, isNotNull);
    expect(SearchedMd3ePage, isNotNull);
    expect(ComicDetailMd3ePage, isNotNull);
    expect(SeriesDetailMd3ePage, isNotNull);
    expect(AuthorDetailMd3ePage, isNotNull);
    expect(libraryComicFiltersProvider, isNotNull);
  });
}
