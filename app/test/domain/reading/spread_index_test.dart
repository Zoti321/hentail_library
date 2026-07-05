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

  group('SpreadIndex.nextPrimaryPage', () {
    test('dualPageNoCover skips by spread', () {
      expect(
        SpreadIndex.nextPrimaryPage(
          mode: ReadingMode.dualPageNoCover,
          totalPages: 4,
          currentPageIndex: 1,
        ),
        2,
      );
      expect(
        SpreadIndex.nextPrimaryPage(
          mode: ReadingMode.dualPageNoCover,
          totalPages: 4,
          currentPageIndex: 3,
        ),
        4,
      );
      expect(
        SpreadIndex.nextPrimaryPage(
          mode: ReadingMode.dualPageNoCover,
          totalPages: 4,
          currentPageIndex: 4,
        ),
        isNull,
      );
    });

    test('dualPage pairs advance two pages at a time', () {
      expect(
        SpreadIndex.nextPrimaryPage(
          mode: ReadingMode.dualPage,
          totalPages: 3,
          currentPageIndex: 1,
        ),
        3,
      );
    });
  });

  group('SpreadIndex.isOnLastSpread', () {
    test('detects last spread for dualPageNoCover', () {
      expect(
        SpreadIndex.isOnLastSpread(
          mode: ReadingMode.dualPageNoCover,
          totalPages: 4,
          currentPageIndex: 4,
        ),
        isTrue,
      );
      expect(
        SpreadIndex.isOnLastSpread(
          mode: ReadingMode.dualPageNoCover,
          totalPages: 4,
          currentPageIndex: 2,
        ),
        isFalse,
      );
    });
  });
}
