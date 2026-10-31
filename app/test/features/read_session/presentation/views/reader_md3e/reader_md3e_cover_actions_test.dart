import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/read_session/presentation/views/reader_md3e/reader_md3e_cover_actions.dart';

void main() {
  group('readerCoverPageIndex', () {
    test('converts 1-based currentIndex to 0-based page index', () {
      expect(readerCoverPageIndex(1), 0);
      expect(readerCoverPageIndex(10), 9);
    });

    test('never returns a negative index', () {
      expect(readerCoverPageIndex(0), 0);
      expect(readerCoverPageIndex(-5), 0);
    });
  });
}
