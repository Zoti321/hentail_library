import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_logic.dart';
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
}
