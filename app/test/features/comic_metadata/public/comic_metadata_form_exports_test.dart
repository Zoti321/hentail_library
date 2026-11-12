import 'package:hentai_library/features/comic_metadata/public/comic_metadata_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('comic_metadata_form narrow barrel exposes form listing only', () {
    expect(NamedFacetFormKind, isNotNull);
    expect(NamedFacetFormListing, isNotNull);
  });
}
