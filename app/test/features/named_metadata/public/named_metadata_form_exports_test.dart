import 'package:hentai_library/features/named_metadata/public/named_metadata_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('named_metadata_form narrow barrel exposes form listing only', () {
    expect(NamedFacetFormKind, isNotNull);
    expect(NamedFacetFormListing, isNotNull);
    expect(listNamedFacetForMetadataForm, isNotNull);
  });
}
