import 'package:hentai_library/features/reading_stats/domain/reading_activity_stats.dart';

/// Reading activity stats 仓储（owner：`reading_stats`）。
abstract class ReadingActivityStatsRepository {
  Stream<ReadingActivityStats> watchActivityStats();

  Future<void> recordSessionActivity({
    required String comicId,
    Duration? addDuration,
    required bool markFinished,
  });
}
