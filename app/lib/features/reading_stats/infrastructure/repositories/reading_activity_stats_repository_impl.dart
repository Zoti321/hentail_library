import 'package:hentai_library/features/reading_stats/domain/reading_activity_stats_repository.dart';
import 'package:hentai_library/infrastructure/frb/frb_call_guard.dart';
import 'package:hentai_library/features/reading_stats/domain/reading_activity_stats.dart';
import 'package:hentai_library/src/rust/api/reading_activity.dart' as rust;

class ReadingActivityStatsRepositoryImpl
    implements ReadingActivityStatsRepository {
  const ReadingActivityStatsRepositoryImpl();

  @override
  Stream<ReadingActivityStats> watchActivityStats() {
    // 迁移也会回填；此处经 FRB 再跑一遍（幂等），避免 reading_stats 依赖 history public。
    return Stream<int>.fromFuture(
      guardFrb(
        () => rust.backfillFinishedComicsFromHistoryFrb(),
        fallbackMessage: '回填读完标记失败',
      ),
    ).asyncExpand(
      (_) => guardFrbStream(
        () => rust.watchReadingActivityStatsFrb().map(_mapStats),
        fallbackMessage: '读取阅读行为统计失败',
      ),
    );
  }

  @override
  Future<void> recordSessionActivity({
    required String comicId,
    Duration? addDuration,
    required bool markFinished,
  }) {
    return guardFrb(
      () => rust.recordReadingActivityFrb(
        comicId: comicId,
        addDurationMs: addDuration?.inMilliseconds,
        markFinished: markFinished,
      ),
      fallbackMessage: '写入阅读行为统计失败',
    );
  }

  ReadingActivityStats _mapStats(rust.ReadingActivityStatsDto dto) {
    return ReadingActivityStats(
      finishedCount: dto.finishedCount,
      totalDuration: Duration(milliseconds: dto.totalDurationMs.toInt()),
    );
  }
}
