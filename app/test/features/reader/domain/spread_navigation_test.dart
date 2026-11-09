import 'package:hentai_library/features/reader/domain/reading_mode.dart';
import 'package:hentai_library/features/reader/domain/spread_navigation.dart';
import 'package:test/test.dart';

void main() {
  group('SpreadNavigation.totalSpreads', () {
    test('paged equals page count', () {
      expect(
        SpreadNavigation.totalSpreads(mode: ReadingMode.paged, totalPages: 5),
        5,
      );
    });

    test('dualPage pairs all pages', () {
      expect(
        SpreadNavigation.totalSpreads(mode: ReadingMode.dualPage, totalPages: 3),
        2,
      );
      expect(
        SpreadNavigation.totalSpreads(mode: ReadingMode.dualPage, totalPages: 4),
        2,
      );
    });
  });

  group('SpreadNavigation.pagesInSpread dualPage', () {
    test('pairs pages and leaves odd last page alone', () {
      expect(
        SpreadNavigation.pagesInSpread(
          mode: ReadingMode.dualPage,
          totalPages: 3,
          spreadIndex: 0,
        ),
        <int>[1, 2],
      );
      expect(
        SpreadNavigation.pagesInSpread(
          mode: ReadingMode.dualPage,
          totalPages: 3,
          spreadIndex: 1,
        ),
        <int>[3],
      );
    });
  });

  group('SpreadNavigation.spreadIndexForPage', () {
    test('maps page back to spread for dualPage', () {
      expect(
        SpreadNavigation.spreadIndexForPage(
          mode: ReadingMode.dualPage,
          totalPages: 4,
          pageIndex: 1,
        ),
        0,
      );
      expect(
        SpreadNavigation.spreadIndexForPage(
          mode: ReadingMode.dualPage,
          totalPages: 4,
          pageIndex: 2,
        ),
        0,
      );
      expect(
        SpreadNavigation.spreadIndexForPage(
          mode: ReadingMode.dualPage,
          totalPages: 4,
          pageIndex: 3,
        ),
        1,
      );
    });
  });

  group('SpreadNavigation.nextPrimaryPage', () {
    test('dualPage pairs advance two pages at a time', () {
      expect(
        SpreadNavigation.nextPrimaryPage(
          mode: ReadingMode.dualPage,
          totalPages: 3,
          currentPageIndex: 1,
        ),
        3,
      );
      expect(
        SpreadNavigation.nextPrimaryPage(
          mode: ReadingMode.dualPage,
          totalPages: 3,
          currentPageIndex: 3,
        ),
        isNull,
      );
    });
  });

  group('SpreadNavigation.isOnLastSpread', () {
    test('detects last spread for dualPage', () {
      expect(
        SpreadNavigation.isOnLastSpread(
          mode: ReadingMode.dualPage,
          totalPages: 4,
          currentPageIndex: 3,
        ),
        isTrue,
      );
      expect(
        SpreadNavigation.isOnLastSpread(
          mode: ReadingMode.dualPage,
          totalPages: 4,
          currentPageIndex: 1,
        ),
        isFalse,
      );
    });
  });

  group('SpreadNavigation.isOnFirstSpread', () {
    test('detects first spread for paged and dualPage', () {
      expect(
        SpreadNavigation.isOnFirstSpread(
          mode: ReadingMode.paged,
          totalPages: 5,
          currentPageIndex: 1,
        ),
        isTrue,
      );
      expect(
        SpreadNavigation.isOnFirstSpread(
          mode: ReadingMode.paged,
          totalPages: 5,
          currentPageIndex: 2,
        ),
        isFalse,
      );
      expect(
        SpreadNavigation.isOnFirstSpread(
          mode: ReadingMode.dualPage,
          totalPages: 5,
          currentPageIndex: 1,
        ),
        isTrue,
      );
      expect(
        SpreadNavigation.isOnFirstSpread(
          mode: ReadingMode.dualPage,
          totalPages: 5,
          currentPageIndex: 3,
        ),
        isFalse,
      );
    });
  });

  group('SpreadNavigation.remapPageForModeSwitch', () {
    test('dualPage to paged uses max page in spread', () {
      expect(
        SpreadNavigation.remapPageForModeSwitch(
          fromMode: ReadingMode.dualPage,
          toMode: ReadingMode.paged,
          currentPageIndex: 3,
          totalPages: 5,
        ),
        4,
      );
      expect(
        SpreadNavigation.remapPageForModeSwitch(
          fromMode: ReadingMode.dualPage,
          toMode: ReadingMode.paged,
          currentPageIndex: 5,
          totalPages: 6,
        ),
        6,
      );
    });

    test('dualPage to webtoon uses max page in spread', () {
      expect(
        SpreadNavigation.remapPageForModeSwitch(
          fromMode: ReadingMode.dualPage,
          toMode: ReadingMode.webtoon,
          currentPageIndex: 1,
          totalPages: 4,
        ),
        2,
      );
    });

    test('single-page spread keeps page when leaving dual mode', () {
      expect(
        SpreadNavigation.remapPageForModeSwitch(
          fromMode: ReadingMode.dualPage,
          toMode: ReadingMode.paged,
          currentPageIndex: 5,
          totalPages: 5,
        ),
        5,
      );
    });

    test('paged to dual keeps current page', () {
      expect(
        SpreadNavigation.remapPageForModeSwitch(
          fromMode: ReadingMode.paged,
          toMode: ReadingMode.dualPage,
          currentPageIndex: 5,
          totalPages: 10,
        ),
        5,
      );
    });

    test('paged to webtoon does not remap', () {
      expect(
        SpreadNavigation.remapPageForModeSwitch(
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
