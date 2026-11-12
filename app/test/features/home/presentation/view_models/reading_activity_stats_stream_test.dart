import 'package:hentai_library/shared/presentation/providers/catalog_state_providers.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/features/reading_stats/public.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  test(
    'readingActivityStatsStream exposes Reading activity stats via port',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          readingActivityStatsProvider.overrideWith(
            (ref) => _ActivityStream(
              ReadingActivityStats(
                finishedCount: 7,
                totalDuration: Duration(minutes: 42),
              ),
            ).watchActivityStats(),
          ),
          libraryRevisionThrottleBusyStateProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      final Completer<ReadingActivityStats> completer =
          Completer<ReadingActivityStats>();
      container.listen(readingActivityStatsStreamProvider, (
        AsyncValue<ReadingActivityStats>? previous,
        AsyncValue<ReadingActivityStats> next,
      ) {
        next.when(
          data: (ReadingActivityStats value) {
            if (!completer.isCompleted) {
              completer.complete(value);
            }
          },
          error: (Object error, StackTrace stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          },
          loading: () {},
        );
      }, fireImmediately: true);

      final ReadingActivityStats stats = await completer.future.timeout(
        const Duration(seconds: 5),
      );
      expect(stats.finishedCount, 7);
      expect(stats.totalDuration, const Duration(minutes: 42));
    },
  );
}

final class _ActivityStream {
  const _ActivityStream(this._stats);

  final ReadingActivityStats _stats;

  Stream<ReadingActivityStats> watchActivityStats() {
    return Stream<ReadingActivityStats>.value(_stats);
  }
}
