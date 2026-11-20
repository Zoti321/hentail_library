import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/infrastructure/mappers/image_set_frb_mapper.dart';
import 'package:hentai_library/src/rust/api/image_set.dart' as rust;

void main() {
  test('maps ImageSetFacetsDto into domain facets', () {
    const rust.ImageSetFacetsDto dto = rust.ImageSetFacetsDto(
      authors: <String>['Alice'],
      tags: <String>['tag'],
      parodies: <String>['p'],
      characters: <String>['c'],
    );

    final ImageSetFacets facets = imageSetFacetsFromFrb(dto);
    expect(facets.authors, <String>['Alice']);
    expect(facets.tags, <String>['tag']);
    expect(facets.parodies, <String>['p']);
    expect(facets.characters, <String>['c']);
  });

  test('maps browse preferences into Core filter/sort/grouping DTOs', () {
    const ImageSetBrowsePreferences preferences = ImageSetBrowsePreferences(
      authors: ImageSetFacetFilter(any: <String>{'b', 'a'}, unassigned: false),
      tags: ImageSetFacetFilter(unassigned: true),
      carrierShape: ImageSetCarrierShape.directory,
      requireImages: true,
      sort: ImageSetSortOption(
        field: ImageSetSortField.createdAt,
        descending: true,
      ),
      grouping: ImageSetGrouping.byAuthor,
    );

    final rust.ImageSetFilterDto filter = imageSetFilterToFrb(
      libraryId: 'lib-1',
      preferences: preferences,
    );
    expect(filter.libraryId, 'lib-1');
    expect(filter.authors.any, <String>['a', 'b']);
    expect(filter.tags.unassigned, isTrue);
    expect(filter.carrierShape, rust.ImageSetCarrierShapeDto.directory);
    expect(filter.requireImages, isTrue);

    final rust.ImageSetSortOptionDto sort = imageSetSortToFrb(preferences.sort);
    expect(sort.field, rust.ImageSetSortFieldDto.createdAt);
    expect(sort.descending, isTrue);

    expect(
      imageSetGroupingToFrb(preferences.grouping),
      rust.ImageSetGroupingDto.byAuthor,
    );
  });
}
