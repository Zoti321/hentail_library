import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination_page_window.dart';

void main() {
  group('md3eBuildPaginationPageWindow (MUI usePagination)', () {
    test('page 1 of 10 matches MUI default window', () {
      final List<Md3ePaginationWindowItem> items =
          md3eBuildPaginationPageWindow(
            currentPage: 1,
            totalPages: 10,
          );
      expect(
        _pageTokens(items),
        <int>[1, 2, 3, 4, 5, -1, 10],
      );
    });

    test('middle page uses both ellipses', () {
      final List<Md3ePaginationWindowItem> items =
          md3eBuildPaginationPageWindow(
            currentPage: 6,
            totalPages: 10,
          );
      expect(
        _pageTokens(items),
        <int>[1, -1, 5, 6, 7, -1, 10],
      );
    });

    test('padding fixes strip length', () {
      final List<Md3ePaginationWindowItem> short =
          md3eBuildPaginationPageWindow(currentPage: 1, totalPages: 4);
      final List<Md3ePaginationWindowItem> padded = md3ePadPaginationPageWindow(
        short,
        slotCount: 7,
      );
      expect(padded.length, 7);
      expect(
        padded.whereType<Md3ePaginationWindowEmpty>().length,
        3,
      );
    });
  });
}

List<int> _pageTokens(List<Md3ePaginationWindowItem> items) {
  return items.map((Md3ePaginationWindowItem item) {
    return switch (item) {
      Md3ePaginationWindowPage(:final int page) => page,
      Md3ePaginationWindowEllipsis() => -1,
      Md3ePaginationWindowEmpty() => -2,
    };
  }).toList();
}
