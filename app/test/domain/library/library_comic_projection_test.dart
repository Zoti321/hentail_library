import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_comic_filter.dart';
import 'package:hentai_library/domain/library/library_comic_projection.dart';
import 'package:hentai_library/domain/library/library_media_type_filter.dart';
import 'package:hentai_library/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/domain/library/library_tri_state_pick.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/library_author_pick.dart';
import 'package:hentai_library/domain/models/value_objects/library_tag_pick.dart';
import 'package:test/test.dart';

void main() {
  group('LibraryComicProjection', () {
    const LibraryComicProjection projection = LibraryComicProjection();
    const LibraryMetadataFilterSelection emptyMetadataFilter =
        LibraryMetadataFilterSelection();

    test('buildListFilter unrestricted shows all ratings', () {
      final LibraryComicFilter filter = projection.buildListFilter(
        ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
        mediaTypeFilter: const LibraryMediaTypeFilterSelection(),
        tagFilter: emptyMetadataFilter,
        authorFilter: emptyMetadataFilter,
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
        tagFilter: emptyMetadataFilter,
        authorFilter: emptyMetadataFilter,
      );
      expect(filter.showR18, isFalse);
      expect(filter.contentRatings, isNull);
    });

    test('buildListFilter r18Only limits to r18 rating', () {
      final LibraryComicFilter filter = projection.buildListFilter(
        ageRestriction: LibraryAgeRestrictionFilter.r18Only,
        mediaTypeFilter: const LibraryMediaTypeFilterSelection(),
        tagFilter: emptyMetadataFilter,
        authorFilter: emptyMetadataFilter,
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
        tagFilter: emptyMetadataFilter,
        authorFilter: emptyMetadataFilter,
      );
      expect(filter.resourceTypes, <ResourceType>{ResourceType.pdf});
    });

    test('buildListFilter maps tag include-all and author include-any', () {
      final LibraryComicFilter filter = projection.buildListFilter(
        ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
        mediaTypeFilter: const LibraryMediaTypeFilterSelection(),
        tagFilter: LibraryMetadataFilterSelection(
          picks: <String, LibraryTriStatePick>{
            '百合': LibraryTriStatePick.include,
            '校园': LibraryTriStatePick.include,
          },
          includeMode: LibraryMetadataIncludeMode.all,
        ),
        authorFilter: LibraryMetadataFilterSelection(
          picks: <String, LibraryTriStatePick>{
            '画师A': LibraryTriStatePick.include,
          },
          includeMode: LibraryMetadataIncludeMode.any,
        ),
      );
      expect(
        filter.tagsAll,
        <LibraryTagPick>{
          const LibraryTagPick(name: '百合'),
          const LibraryTagPick(name: '校园'),
        },
      );
      expect(filter.tagsAny, isNull);
      expect(
        filter.authorsAny,
        <LibraryAuthorPick>{const LibraryAuthorPick(name: '画师A')},
      );
      expect(filter.authorsAll, isNull);
    });

    test('buildListFilter maps exclude picks', () {
      final LibraryComicFilter filter = projection.buildListFilter(
        ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
        mediaTypeFilter: const LibraryMediaTypeFilterSelection(),
        tagFilter: LibraryMetadataFilterSelection(
          picks: <String, LibraryTriStatePick>{
            'R18': LibraryTriStatePick.exclude,
          },
        ),
        authorFilter: emptyMetadataFilter,
      );
      expect(
        filter.tagsExclude,
        <LibraryTagPick>{const LibraryTagPick(name: 'R18')},
      );
    });
  });
}
