import 'package:hentai_library/domain/library/smart_facet_match_preference.dart';
import 'package:test/test.dart';

void main() {
  group('SmartFacetMatchPreference.fromStorage', () {
    test('null defaults to enabled', () {
      expect(SmartFacetMatchPreference.fromStorage(null), isTrue);
    });

    test('false is preserved', () {
      expect(SmartFacetMatchPreference.fromStorage(false), isFalse);
    });

    test('true is preserved', () {
      expect(SmartFacetMatchPreference.fromStorage(true), isTrue);
    });
  });
}
