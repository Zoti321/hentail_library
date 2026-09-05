import 'package:hentai_library/core/utils/name_contains_filter.dart';
import 'package:test/test.dart';

void main() {
  group('nameMatchesContainsFilter', () {
    test('empty or whitespace query matches all', () {
      expect(nameMatchesContainsFilter('Alpha', ''), isTrue);
      expect(nameMatchesContainsFilter('Alpha', '   '), isTrue);
    });

    test('trims and matches case-insensitively by contains', () {
      expect(nameMatchesContainsFilter('Alpha', '  alP  '), isTrue);
      expect(nameMatchesContainsFilter('Beta', 'zzz'), isFalse);
    });
  });
}
