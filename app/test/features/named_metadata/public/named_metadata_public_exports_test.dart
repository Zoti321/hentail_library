import 'package:hentai_library/features/named_metadata/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'public barrel exports cross-feature types, repository factories, and page',
    () {
      expect(AuthorRepository, isNotNull);
      expect(TagRepository, isNotNull);
      expect(NamedFacetManagementRepository, isNotNull);
      expect(NamedFacetDictionaryRepository, isNotNull);
      expect(NamedFacetFormKind, isNotNull);
      expect(namedFacetFormCandidate, isNotNull);
      expect(createAuthorRepository, isNotNull);
      expect(createTagRepository, isNotNull);
      expect(createNamedFacetManagementRepository, isNotNull);
      expect(createNamedFacetDictionaryRepository, isNotNull);
      expect(allTagsProvider, isNotNull);
      expect(allAuthorsProvider, isNotNull);
      expect(MetadataManagementPage, isNotNull);
    },
  );
}
