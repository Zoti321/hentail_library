import 'package:hentai_library/features/reading_stats/domain/reading_activity_stats_repository.dart';
import 'package:hentai_library/shared/data/frb/frb_call_guard.dart';
import 'package:hentai_library/shared/domain/library/reading_activity_stats.dart';
import 'package:hentai_library/shared/domain/ports/reading_activity_stats_port.dart';
import 'package:hentai_library/src/rust/api/reading_activity.dart' as rust;

class ReadingActivityStatsRepositoryImpl
    implements ReadingActivityStatsRepository, ReadingActivityStatsPort {
  const ReadingActivityStatsRepositoryImpl();

  @override
  Stream<ReadingActivityStats> watchActivityStats() {
    return guardFrbStream(
      () => rust.watchReadingActivityStatsFrb().map(_mapStats),
      fallbackMessage: '读取阅读行为统计失败',
    );
  }

  ReadingActivityStats _mapStats(rust.ReadingActivityStatsDto dto) {
    return ReadingActivityStats(
      finishedCount: dto.finishedCount,
      totalDuration: Duration(milliseconds: dto.totalDurationMs.toInt()),
    );
  }
}
