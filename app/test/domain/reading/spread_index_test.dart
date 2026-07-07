import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/domain/reading/spread_index.dart';
import 'package:test/test.dart';

void main() {
  group('SpreadIndex.totalSpreads', () {
    test('paged equals page count', () {
      expect(
        SpreadIndex.totalSpreads(mode: ReadingMode.paged, totalPages: 5),
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

  group('SpreadIndex.remapPageForModeSwitch', () {
    test('dualPage to paged uses max page in spread', () {
      expect(
        SpreadIndex.remapPageForModeSwitch(
          fromMode: ReadingMode.dualPage,
          toMode: ReadingMode.paged,
          currentPageIndex: 3,
          totalPages: 5,
        ),
        4,
      );
      expect(
        SpreadIndex.remapPageForModeSwitch(
          fromMode: ReadingMode.dualPage,
          toMode: ReadingMode.paged,
          currentPageIndex: 5,
          totalPages: 6,
        ),
        6,
      );
    });

    test('dualPageNoCover to webtoon uses max page in spread', () {
      expect(
        SpreadIndex.remapPageForModeSwitch(
          fromMode: ReadingMode.dualPageNoCover,
          toMode: ReadingMode.webtoon,
          currentPageIndex: 2,
          totalPages: 4,
        ),
        3,
      );
    });

    test('single-page spread keeps page when leaving dual mode', () {
      expect(
        SpreadIndex.remapPageForModeSwitch(
          fromMode: ReadingMode.dualPageNoCover,
          toMode: ReadingMode.paged,
          currentPageIndex: 1,
          totalPages: 4,
        ),
        1,
      );
      expect(
        SpreadIndex.remapPageForModeSwitch(
          fromMode: ReadingMode.dualPageNoCover,
          toMode: ReadingMode.paged,
          currentPageIndex: 4,
          totalPages: 4,
        ),
        4,
      );
    });

    test('paged to dual keeps current page', () {
      expect(
        SpreadIndex.remapPageForModeSwitch(
          fromMode: ReadingMode.paged,
          toMode: ReadingMode.dualPageNoCover,
          currentPageIndex: 5,
          totalPages: 10,
        ),
        5,
      );
    });

    test('dualPage variants do not remap', () {
      expect(
        SpreadIndex.remapPageForModeSwitch(
          fromMode: ReadingMode.dualPage,
          toMode: ReadingMode.dualPageNoCover,
          currentPageIndex: 3,
          totalPages: 10,
        ),
        3,
      );
    });

    test('paged to webtoon does not remap', () {
      expect(
        SpreadIndex.remapPageForModeSwitch(
          fromMode: ReadingMode.paged,
          toMode: ReadingMode.webtoon,
          currentPageIndex: 7,
          totalPages: 20,
        ),
        7,
      );
    });
  });
}
