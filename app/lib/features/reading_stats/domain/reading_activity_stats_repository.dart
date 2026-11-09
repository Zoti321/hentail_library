import 'package:hentai_library/shared/domain/library/reading_activity_stats.dart';

/// Reading activity stats 仓储（owner：`reading_stats`）。
abstract class ReadingActivityStatsRepository {
  Stream<ReadingActivityStats> watchActivityStats();
}
