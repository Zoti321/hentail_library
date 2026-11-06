import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/widgets/pagination/pagination_page_window.dart';

void main() {
  group('buildPaginationPageWindow (MUI usePagination)', () {
    test('page 1 of 10 matches MUI default window', () {
      final List<PaginationWindowItem> items = buildPaginationPageWindow(
        currentPage: 1,
        totalPages: 10,
      );
      expect(_pageTokens(items), <int>[1, 2, 3, 4, 5, -1, 10]);
    });

    test('middle page uses both ellipses', () {
      final List<PaginationWindowItem> items = buildPaginationPageWindow(
        currentPage: 6,
        totalPages: 10,
      );
      expect(_pageTokens(items), <int>[1, -1, 5, 6, 7, -1, 10]);
    });

    test('padding fixes strip length', () {
      final List<PaginationWindowItem> short = buildPaginationPageWindow(
        currentPage: 1,
        totalPages: 4,
      );
      final List<PaginationWindowItem> padded = padPaginationPageWindow(
        short,
        slotCount: 7,
      );
      expect(padded.length, 7);
      expect(padded.whereType<PaginationWindowEmpty>().length, 3);
    });
  });
}

List<int> _pageTokens(List<PaginationWindowItem> items) {
  return items.map((PaginationWindowItem item) {
    return switch (item) {
      PaginationWindowPage(:final int page) => page,
      PaginationWindowEllipsis() => -1,
      PaginationWindowEmpty() => -2,
    };
  }).toList();
}
