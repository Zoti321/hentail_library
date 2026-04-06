import 'package:hentai_library/core/util/filename_natural_compare.dart';
import 'package:test/test.dart';

void main() {
  group('compareFilenameNatural', () {
    test('numeric prefix: larger id sorts after smaller lexicographic trap', () {
      const String smallerNumericLargerLex = '92313559_p0-anastasia.png';
      const String largerNumericSmallerLex =
          '142918999_p0-\u5e02\u5ddd\u96cf\u83dc \uff0f Hinana.png';
      expect(
        compareFilenameNatural(smallerNumericLargerLex, largerNumericSmallerLex),
        lessThan(0),
      );
      expect(
        compareFilenameNatural(largerNumericSmallerLex, smallerNumericLargerLex),
        greaterThan(0),
      );
    });

    test('a1 a2 a10 order', () {
      final List<String> names = <String>['a10.png', 'a2.png', 'a1.png'];
      names.sort(compareFilenameNatural);
      expect(names, <String>['a1.png', 'a2.png', 'a10.png']);
    });

    test('leading zeros normalize as integers', () {
      expect(compareFilenameNatural('img01.jpg', 'img1.jpg'), 0);
      expect(compareFilenameNatural('img001.jpg', 'img02.jpg'), lessThan(0));
    });

    test('ties with extra suffix', () {
      expect(compareFilenameNatural('1', '1a'), lessThan(0));
      expect(compareFilenameNatural('1a', '1'), greaterThan(0));
    });
  });
}
