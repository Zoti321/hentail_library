import 'package:hentai_library/features/reader/domain/page_prefetch_window.dart';
import 'package:test/test.dart';

void main() {
  group('computePrefetchWindow', () {
    test('includes center and neighbors', () {
      expect(
        computePrefetchWindow(
          centerPageOneBased: 5,
          totalPages: 10,
          neighborCount: 2,
        ),
        <int>{3, 4, 5, 6, 7},
      );
    });

    test('merges extra spread pages', () {
      expect(
        computePrefetchWindow(
          centerPageOneBased: 2,
          totalPages: 10,
          neighborCount: 1,
          extraPageIndexesOneBased: <int>[3],
        ),
        <int>{1, 2, 3},
      );
    });
  });

  group('pagesLeavingPrefetchWindow', () {
    test('empty when no previous window', () {
      expect(
        pagesLeavingPrefetchWindow(
          previousWindow: null,
          nextWindow: <int>{1, 2, 3},
        ),
        isEmpty,
      );
    });

    test('returns pages dropped by a large center jump', () {
      final Set<int> previous = computePrefetchWindow(
        centerPageOneBased: 1,
        totalPages: 40,
        neighborCount: kReaderPrefetchNeighborCount,
      );
      final Set<int> next = computePrefetchWindow(
        centerPageOneBased: 28,
        totalPages: 40,
        neighborCount: kReaderPrefetchNeighborCount,
      );
      expect(
        pagesLeavingPrefetchWindow(previousWindow: previous, nextWindow: next),
        previous.difference(next),
      );
      expect(previous.difference(next), isNotEmpty);
    });
  });

  group('pagesToInvalidateOutsidePrefetchWindow', () {
    test('includes touched pages never present in previous window', () {
      expect(
        pagesToInvalidateOutsidePrefetchWindow(
          previousWindow: <int>{1, 2, 3},
          nextWindow: <int>{20, 21, 22},
          touchedPages: <int>{1, 2, 3, 4},
        ),
        <int>{1, 2, 3, 4},
      );
    });

    test('keeps pages that remain in the next window', () {
      expect(
        pagesToInvalidateOutsidePrefetchWindow(
          previousWindow: <int>{8, 9, 10},
          nextWindow: <int>{9, 10, 11},
          touchedPages: <int>{8, 9, 10, 12},
        ),
        <int>{8, 12},
      );
    });
  });
}
