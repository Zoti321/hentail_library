import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/history_list_progress.dart';

void main() {
  group('historyListCurrentPage', () {
    test('null or non-positive pageIndex defaults to page 1', () {
      expect(historyListCurrentPage(null), 1);
      expect(historyListCurrentPage(0), 1);
      expect(historyListCurrentPage(-1), 1);
    });

    test('positive pageIndex is shown as-is', () {
      expect(historyListCurrentPage(7), 7);
    });
  });

  group('historyListTotalPages', () {
    test('uses comic page count when available', () {
      expect(
        historyListTotalPages(pageCount: 40, currentPage: 10),
        40,
      );
    });

    test('falls back to current page when page count missing', () {
      expect(
        historyListTotalPages(pageCount: null, currentPage: 10),
        10,
      );
    });
  });
}
