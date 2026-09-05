import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_logic.dart';
import 'package:test/test.dart';

void main() {
  group('shouldBumpPrefetchGeneration', () {
    test('does not bump when warm window set is unchanged', () {
      final Set<int> window = computePrefetchWindow(
        centerPageOneBased: 5,
        totalPages: 20,
        neighborCount: kReaderPrefetchNeighborCount,
      );

      expect(
        shouldBumpPrefetchGeneration(
          previousWindow: window,
          nextWindow: Set<int>.from(window),
        ),
        isFalse,
      );
    });

    test('bumps when center moves and window set changes', () {
      final Set<int> previous = computePrefetchWindow(
        centerPageOneBased: 5,
        totalPages: 20,
        neighborCount: kReaderPrefetchNeighborCount,
      );
      final Set<int> next = computePrefetchWindow(
        centerPageOneBased: 8,
        totalPages: 20,
        neighborCount: kReaderPrefetchNeighborCount,
      );

      expect(
        shouldBumpPrefetchGeneration(
          previousWindow: previous,
          nextWindow: next,
        ),
        isTrue,
      );
    });

    test('bumps on first warm (no previous window)', () {
      expect(
        shouldBumpPrefetchGeneration(
          previousWindow: null,
          nextWindow: <int>{1, 2, 3},
        ),
        isTrue,
      );
    });
  });
}
