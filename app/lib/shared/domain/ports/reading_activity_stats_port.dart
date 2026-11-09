import 'package:hentai_library/shared/domain/library/reading_activity_stats.dart';

/// Reading activity stats 跨 feature 读口。
///
/// Token：[readingActivityStatsPortProvider]（`shared/di/reading_stats_providers.dart`）。
abstract class ReadingActivityStatsPort {
  Stream<ReadingActivityStats> watchActivityStats();
}
