import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/shell/view_models/history_load_more_throttle.dart';

void main() {
  group('shouldAttemptHistoryLoadMore', () {
    test('allows first attempt', () {
      expect(
        shouldAttemptHistoryLoadMore(
          lastAttemptAt: null,
          now: DateTime.utc(2026, 9, 5, 12),
        ),
        isTrue,
      );
    });

    test('blocks attempts inside the min interval', () {
      final DateTime last = DateTime.utc(2026, 9, 5, 12);
      expect(
        shouldAttemptHistoryLoadMore(
          lastAttemptAt: last,
          now: last.add(const Duration(milliseconds: 100)),
        ),
        isFalse,
      );
    });

    test('allows attempts after the min interval', () {
      final DateTime last = DateTime.utc(2026, 9, 5, 12);
      expect(
        shouldAttemptHistoryLoadMore(
          lastAttemptAt: last,
          now: last.add(kHistoryLoadMoreMinInterval),
        ),
        isTrue,
      );
    });
  });
}
