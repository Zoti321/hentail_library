import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_form_candidate.dart';

void main() {
  test('validateNamedFacetFormCandidateName', () {
    expect(validateNamedFacetFormCandidateName(''), isNotNull);
    expect(validateNamedFacetFormCandidateName('  '), isNotNull);
    expect(validateNamedFacetFormCandidateName('tag'), isNull);
  });

  test('namedFacetFormCandidate trims name', () {
    expect(
      namedFacetFormCandidate(name: '  x  ', attachmentCount: 1).name,
      'x',
    );
  });
}
