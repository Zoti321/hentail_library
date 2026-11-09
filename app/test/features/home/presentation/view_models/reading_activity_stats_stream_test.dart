import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/di/reading_stats_providers.dart';
import 'package:hentai_library/shared/domain/library/reading_activity_stats.dart';
import 'package:hentai_library/shared/domain/ports/reading_activity_stats_port.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  test(
    'readingActivityStatsStream exposes Reading activity stats via port',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          readingActivityStatsPortProvider.overrideWithValue(
            const _FakeReadingActivityStatsPort(
              ReadingActivityStats(
                finishedCount: 7,
                totalDuration: Duration(minutes: 42),
              ),
            ),
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

final class _FakeReadingActivityStatsPort implements ReadingActivityStatsPort {
  const _FakeReadingActivityStatsPort(this._stats);

  final ReadingActivityStats _stats;

  @override
  Stream<ReadingActivityStats> watchActivityStats() {
    return Stream<ReadingActivityStats>.value(_stats);
  }
}
