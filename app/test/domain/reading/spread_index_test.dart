import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/domain/reading/spread_index.dart';
import 'package:test/test.dart';

void main() {
  group('SpreadIndex.totalSpreads', () {
    test('paged equals page count', () {
      expect(
        SpreadIndex.totalSpreads(
          mode: ReadingMode.paged,
          totalPages: 5,
        ),
        5,
      );
    });

    test('dualPageNoCover counts cover spread separately', () {
      expect(
        SpreadIndex.totalSpreads(
          mode: ReadingMode.dualPageNoCover,
          totalPages: 1,
        ),
        1,
      );
      expect(
        SpreadIndex.totalSpreads(
          mode: ReadingMode.dualPageNoCover,
          totalPages: 4,
        ),
        3,
      );
    });

    test('dualPage pairs all pages', () {
      expect(
        SpreadIndex.totalSpreads(mode: ReadingMode.dualPage, totalPages: 3),
        2,
      );
    });
  });

  group('SpreadIndex.pagesInSpread dualPageNoCover', () {
    test('cover alone then pairs', () {
      expect(
        SpreadIndex.pagesInSpread(
          mode: ReadingMode.dualPageNoCover,
          totalPages: 4,
          spreadIndex: 0,
        ),
        <int>[1],
      );
      expect(
        SpreadIndex.pagesInSpread(
          mode: ReadingMode.dualPageNoCover,
          totalPages: 4,
          spreadIndex: 1,
        ),
        <int>[2, 3],
      );
      expect(
        SpreadIndex.pagesInSpread(
          mode: ReadingMode.dualPageNoCover,
          totalPages: 4,
          spreadIndex: 2,
        ),
        <int>[4],
      );
    });
  });

  group('SpreadIndex.spreadIndexForPage', () {
    test('maps page back to spread for dualPageNoCover', () {
      expect(
        SpreadIndex.spreadIndexForPage(
          mode: ReadingMode.dualPageNoCover,
          totalPages: 4,
          pageIndex: 1,
        ),
        0,
      );
      expect(
        SpreadIndex.spreadIndexForPage(
          mode: ReadingMode.dualPageNoCover,
          totalPages: 4,
          pageIndex: 3,
        ),
        1,
      );
      expect(
        SpreadIndex.spreadIndexForPage(
          mode: ReadingMode.dualPageNoCover,
          totalPages: 4,
          pageIndex: 4,
        ),
        2,
      );
    });
  });
}
