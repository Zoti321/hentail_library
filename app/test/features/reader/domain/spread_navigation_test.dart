import 'package:hentai_library/features/read_session/domain/reading_mode.dart';
import 'package:hentai_library/features/read_session/domain/spread_index.dart';
import 'package:test/test.dart';

void main() {
  group('SpreadIndex.totalSpreads', () {
    test('paged equals page count', () {
      expect(
        SpreadIndex.totalSpreads(mode: ReadingMode.paged, totalPages: 5),
        5,
      );
    });

    test('dualPage pairs all pages', () {
      expect(
        SpreadIndex.totalSpreads(mode: ReadingMode.dualPage, totalPages: 3),
        2,
      );
      expect(
        SpreadIndex.totalSpreads(mode: ReadingMode.dualPage, totalPages: 4),
        2,
      );
    });
  });

  group('SpreadIndex.pagesInSpread dualPage', () {
    test('pairs pages and leaves odd last page alone', () {
      expect(
        SpreadIndex.pagesInSpread(
          mode: ReadingMode.dualPage,
          totalPages: 3,
          spreadIndex: 0,
        ),
        <int>[1, 2],
      );
      expect(
        SpreadIndex.pagesInSpread(
          mode: ReadingMode.dualPage,
          totalPages: 3,
          spreadIndex: 1,
        ),
        <int>[3],
      );
    });
  });

  group('SpreadIndex.spreadIndexForPage', () {
    test('maps page back to spread for dualPage', () {
      expect(
        SpreadIndex.spreadIndexForPage(
          mode: ReadingMode.dualPage,
          totalPages: 4,
          pageIndex: 1,
        ),
        0,
      );
      expect(
        SpreadIndex.spreadIndexForPage(
          mode: ReadingMode.dualPage,
          totalPages: 4,
          pageIndex: 2,
        ),
        0,
      );
      expect(
        SpreadIndex.spreadIndexForPage(
          mode: ReadingMode.dualPage,
          totalPages: 4,
          pageIndex: 3,
        ),
        1,
      );
    });
  });

  group('SpreadIndex.nextPrimaryPage', () {
    test('dualPage pairs advance two pages at a time', () {
      expect(
        SpreadIndex.nextPrimaryPage(
          mode: ReadingMode.dualPage,
          totalPages: 3,
          currentPageIndex: 1,
        ),
        3,
      );
      expect(
        SpreadIndex.nextPrimaryPage(
          mode: ReadingMode.dualPage,
          totalPages: 3,
          currentPageIndex: 3,
        ),
        isNull,
      );
    });
  });

  group('SpreadIndex.isOnLastSpread', () {
    test('detects last spread for dualPage', () {
      expect(
        SpreadIndex.isOnLastSpread(
          mode: ReadingMode.dualPage,
          totalPages: 4,
          currentPageIndex: 3,
        ),
        isTrue,
      );
      expect(
        SpreadIndex.isOnLastSpread(
          mode: ReadingMode.dualPage,
          totalPages: 4,
          currentPageIndex: 1,
        ),
        isFalse,
      );
    });
  });

  group('SpreadIndex.isOnFirstSpread', () {
    test('detects first spread for paged and dualPage', () {
      expect(
        SpreadIndex.isOnFirstSpread(
          mode: ReadingMode.paged,
          totalPages: 5,
          currentPageIndex: 1,
        ),
        isTrue,
      );
      expect(
        SpreadIndex.isOnFirstSpread(
          mode: ReadingMode.paged,
          totalPages: 5,
          currentPageIndex: 2,
        ),
        isFalse,
      );
      expect(
        SpreadIndex.isOnFirstSpread(
          mode: ReadingMode.dualPage,
          totalPages: 5,
          currentPageIndex: 1,
        ),
        isTrue,
      );
      expect(
        SpreadIndex.isOnFirstSpread(
          mode: ReadingMode.dualPage,
          totalPages: 5,
          currentPageIndex: 3,
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

    test('dualPage to webtoon uses max page in spread', () {
      expect(
        SpreadIndex.remapPageForModeSwitch(
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
        SpreadIndex.remapPageForModeSwitch(
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
        SpreadIndex.remapPageForModeSwitch(
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
