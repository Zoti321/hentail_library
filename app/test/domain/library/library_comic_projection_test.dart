import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_comic_filter.dart';
import 'package:hentai_library/domain/library/library_comic_projection.dart';
import 'package:hentai_library/domain/library/library_media_type_filter.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:test/test.dart';

void main() {
  group('LibraryComicProjection', () {
    const LibraryComicProjection projection = LibraryComicProjection();

    test('buildListFilter unrestricted shows all ratings', () {
      final LibraryComicFilter filter = projection.buildListFilter(
        ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
        mediaTypeFilter: const LibraryMediaTypeFilterSelection(),
        keyword: '  abc  ',
      );
      expect(filter.showR18, isTrue);
      expect(filter.contentRatings, isNull);
      expect(filter.resourceTypes, isNull);
      expect(filter.query, 'abc');
    });

    test('buildListFilter allAges excludes r18', () {
      final LibraryComicFilter filter = projection.buildListFilter(
        ageRestriction: LibraryAgeRestrictionFilter.allAges,
        mediaTypeFilter: const LibraryMediaTypeFilterSelection(),
      );
      expect(filter.showR18, isFalse);
      expect(filter.contentRatings, isNull);
    });

    test('buildListFilter r18Only limits to r18 rating', () {
      final LibraryComicFilter filter = projection.buildListFilter(
        ageRestriction: LibraryAgeRestrictionFilter.r18Only,
        mediaTypeFilter: const LibraryMediaTypeFilterSelection(),
      );
      expect(filter.showR18, isTrue);
      expect(filter.contentRatings, <ContentRating>{ContentRating.r18});
    });

    test('buildListFilter applies active media type filter', () {
      final LibraryComicFilter filter = projection.buildListFilter(
        ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
        mediaTypeFilter: const LibraryMediaTypeFilterSelection({
          LibraryMediaTypeFilterOption.pdf,
        }),
      );
      expect(filter.resourceTypes, <ResourceType>{ResourceType.pdf});
    });
  });
}
